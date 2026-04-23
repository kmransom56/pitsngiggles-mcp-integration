"""
LAN-only race engineer: pulls telemetry from Pits n' Giggles (HTTP) and
answers via a local Ollama model. Serves a small browser UI on the same port.
"""

from __future__ import annotations

import asyncio
import json
import os
import tempfile
import threading
import time
from pathlib import Path

import httpx
from fastapi import (
    FastAPI,
    File,
    HTTPException,
    UploadFile,
    WebSocket,
    WebSocketDisconnect,
)
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse, StreamingResponse
from pydantic import BaseModel, Field

APP_DIR = Path(__file__).resolve().parent
STATIC = APP_DIR / "static"

OLLAMA_BASE = os.environ.get("OLLAMA_BASE", "http://127.0.0.1:11434")
PNG_BASE = os.environ.get("PNG_BASE", "http://127.0.0.1:4768")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "llama3.1:8b")
WHISPER_MODEL = os.environ.get("WHISPER_MODEL", "small")
ENGINEER_PORT = int(os.environ.get("ENGINEER_VOICE_PORT", "11734"))
# float32 audio from browser; 48k common from AudioContext, decimate ~3:1 to match Whisper
WS_STT_IN_SR = int(os.environ.get("WS_STT_IN_SAMPLE_RATE", "48000"))
WS_STT_TARGET_SR = 16000
WS_STT_CHUNK_S = float(os.environ.get("WS_STT_CHUNK_S", "1.4"))
# max ~2 min of audio at 16k float32
WS_STT_MAX_FLOATS = int(os.environ.get("WS_STT_MAX_FLOATS", str(30 * 16000)))

F1_ENGINEER_SYSTEM = """You are a professional F1 race engineer for F1 23/24/25 sim racing. \
You have live telemetry and race context in each message. Be concise, radio-style: 2-4 short sentences \
unless the driver asks for detail. Use numbers and concrete setup advice. If telemetry is missing, \
say so and give general guidance."""

_whisper = None
_whisper_lock = threading.Lock()

try:
    from faster_whisper import WhisperModel

    _FASTER = True
except ImportError:
    WhisperModel = None
    _FASTER = False


def _get_whisper() -> "WhisperModel | None":
    global _whisper
    if not _FASTER:
        return None
    with _whisper_lock:
        if _whisper is None:
            device = os.environ.get("WHISPER_DEVICE", "auto")
            compute = os.environ.get("WHISPER_COMPUTE", "int8")
            _whisper = WhisperModel(WHISPER_MODEL, device=device, compute_type=compute)
    return _whisper


app = FastAPI(title="LAN Race Engineer", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class ChatIn(BaseModel):
    message: str = Field(..., min_length=1, max_length=16_000)
    include_telemetry: bool = True


class ChatOut(BaseModel):
    reply: str
    context_ok: bool


async def _fetch_png_context(client: httpx.AsyncClient) -> tuple[str, bool]:
    ra = te = None
    ok = True
    try:
        r1 = await client.get(f"{PNG_BASE}/race-info", timeout=3.0)
        if r1.is_success:
            ra = r1.json()
    except (httpx.RequestError, json.JSONDecodeError):
        ok = False
    try:
        r2 = await client.get(f"{PNG_BASE}/telemetry-info", timeout=3.0)
        if r2.is_success:
            te = r2.json()
    except (httpx.RequestError, json.JSONDecodeError):
        ok = False
    if not ra and not te:
        return (
            "No live telemetry: start Pits n' Giggles and ensure the HTTP server (4768) is on.",
            False,
        )
    return json.dumps({"race": ra, "telemetry": te}, indent=0)[:48_000], ok


async def _ollama_chat(client: httpx.AsyncClient, system: str, user: str) -> str:
    body = {
        "model": OLLAMA_MODEL,
        "stream": False,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
    }
    r = await client.post(f"{OLLAMA_BASE}/api/chat", json=body, timeout=120.0)
    if r.status_code >= 400:
        raise HTTPException(
            status_code=502, detail=f"Ollama error: {r.status_code} {r.text[:500]}"
        )
    data = r.json()
    msg = (data.get("message") or {}).get("content")
    if not msg:
        raise HTTPException(
            status_code=502, detail="Ollama returned no message content."
        )
    return msg


def _resample_to_16k_mono(x_in: "object", in_sr: int) -> "object":  # numpy ndarray
    import numpy as np

    x = np.asarray(x_in, dtype=np.float32)
    if x.size < 1:
        return x
    if in_sr == WS_STT_TARGET_SR:
        return x
    step = max(1, int(round(in_sr / float(WS_STT_TARGET_SR))))
    return x[::step].astype(np.float32)


def _transcribe_float32_16k(audio: "object") -> str:  # numpy ndarray, mono 16 kHz
    import numpy as np

    arr = np.asarray(audio, dtype=np.float32)
    if arr.size < 100:
        return ""
    m = _get_whisper()
    if not m:
        return ""
    segs, _ = m.transcribe(
        arr,
        language="en",
        vad_filter=True,
    )
    return " ".join(s.text for s in segs).strip()


def _ws_buffer_to_text(buf: bytearray, in_sample_rate: int) -> str:
    import numpy as np

    if len(buf) < 400:
        return ""
    x = np.frombuffer(bytes(buf), dtype=np.float32)
    y = _resample_to_16k_mono(x, in_sample_rate)
    if y.size < 100:
        return ""
    if y.size > WS_STT_MAX_FLOATS:
        y = y[-WS_STT_MAX_FLOATS:].copy()
    return _transcribe_float32_16k(y)


@app.get("/")
async def index():
    p = STATIC / "lan_engineer.html"
    if not p.is_file():
        return JSONResponse(
            {"error": f"Missing UI file: {p}"},
            status_code=500,
        )
    return FileResponse(p, media_type="text/html; charset=utf-8")


@app.get("/health")
async def health():
    oll = png = wsp = False
    async with httpx.AsyncClient() as client:
        try:
            r = await client.get(f"{OLLAMA_BASE}/api/tags", timeout=2.0)
            oll = r.is_success
        except httpx.RequestError:
            oll = False
        try:
            r2 = await client.get(f"{PNG_BASE}/race-info", timeout=2.0)
            png = r2.is_success
        except httpx.RequestError:
            png = False
    wsp = _FASTER
    return {
        "ollama": oll,
        "pits_n_giggles_http": png,
        "faster_whisper": wsp,
        "ollama_model": OLLAMA_MODEL,
        "websocket_stt": wsp,
    }


@app.post("/api/chat", response_model=ChatOut)
async def chat(item: ChatIn):
    async with httpx.AsyncClient() as client:
        if item.include_telemetry:
            ctx, context_ok = await _fetch_png_context(client)
            system = f"{F1_ENGINEER_SYSTEM}\n\n## Live context (JSON)\n{ctx}\n"
            reply = await _ollama_chat(client, system, item.message)
        else:
            context_ok = False
            reply = await _ollama_chat(client, F1_ENGINEER_SYSTEM, item.message)
    return ChatOut(reply=reply, context_ok=context_ok)


@app.post("/api/chat/stream")
async def chat_stream(item: ChatIn):
    """Proxies Ollama NDJSON; first line is `engineer_meta` with `context_ok`."""

    async def gen():
        async with httpx.AsyncClient() as client:
            if item.include_telemetry:
                ctx, context_ok = await _fetch_png_context(client)
                system = f"{F1_ENGINEER_SYSTEM}\n\n## Live context (JSON)\n{ctx}\n"
            else:
                context_ok = False
                system = F1_ENGINEER_SYSTEM
            meta = (
                json.dumps(
                    {
                        "engineer_meta": {
                            "context_ok": context_ok,
                        }
                    }
                )
                + "\n"
            )
            yield meta.encode("utf-8")
            body = {
                "model": OLLAMA_MODEL,
                "stream": True,
                "messages": [
                    {"role": "system", "content": system},
                    {"role": "user", "content": item.message},
                ],
            }
            try:
                async with client.stream(
                    "POST",
                    f"{OLLAMA_BASE}/api/chat",
                    json=body,
                    timeout=httpx.Timeout(300.0),
                ) as response:
                    if response.status_code != 200:
                        err = (await response.aread()).decode()[:2000]
                        err_line = (
                            json.dumps(
                                {
                                    "error": f"Ollama {response.status_code}",
                                    "detail": err,
                                }
                            )
                            + "\n"
                        )
                        yield err_line.encode("utf-8")
                        return
                    async for line in response.aiter_lines():
                        if line:
                            yield (line + "\n").encode("utf-8")
            except httpx.RequestError as e:
                err_line = (
                    json.dumps(
                        {
                            "error": "ollama_request",
                            "detail": str(e),
                        }
                    )
                    + "\n"
                )
                yield err_line.encode("utf-8")

    return StreamingResponse(
        gen(),
        media_type="application/x-ndjson",
        headers={"X-Accel-Buffering": "no"},
    )


@app.websocket("/ws/stt")
async def ws_stt(websocket: WebSocket):
    await websocket.accept()
    if not _FASTER:
        await websocket.close(
            code=1013,
            reason="faster_whisper not installed; see requirements-optional-stt",
        )
        return
    buf = bytearray()
    in_sr = WS_STT_IN_SR
    last_t = 0.0
    _transcribe_lock = threading.Lock()

    try:
        while True:
            try:
                msg = await websocket.receive()
            except WebSocketDisconnect:
                break
            mtype = msg.get("type")
            if mtype == "websocket.disconnect":
                break
            if mtype == "websocket.receive" and msg.get("text") is not None:
                try:
                    data = json.loads(msg["text"])
                except (json.JSONDecodeError, TypeError, ValueError):
                    data = {}
                if data.get("type") == "config" and "sample_rate" in data:
                    in_sr = int(data["sample_rate"])
                if data.get("type") in ("end", "flush") and len(buf) > 0:
                    t = _ws_buffer_to_text(buf, in_sr)
                    if t:
                        await websocket.send_text(
                            json.dumps({"type": "stt", "partial": False, "text": t})
                        )
                    buf.clear()
                if data.get("type") == "close":
                    break
            if mtype == "websocket.receive" and msg.get("bytes") is not None:
                buf.extend(msg["bytes"])
                maxb = WS_STT_MAX_FLOATS * 4
                if len(buf) > maxb:
                    del buf[: len(buf) - maxb]
                n = len(buf) // 4
                need = int(WS_STT_TARGET_SR * WS_STT_CHUNK_S)
                if n < need:
                    continue
                now = time.monotonic()
                if now - last_t < WS_STT_CHUNK_S * 0.4:
                    continue
                last_t = now
                bcopy = bytes(buf)

                def _run() -> str:
                    with _transcribe_lock:
                        return _ws_buffer_to_text(bytearray(bcopy), in_sr)

                text = await asyncio.to_thread(_run)
                if text:
                    await websocket.send_text(
                        json.dumps(
                            {
                                "type": "stt",
                                "partial": True,
                                "text": text,
                            }
                        )
                    )
    except WebSocketDisconnect:
        pass
    except Exception as e:  # noqa: BLE001
        try:
            await websocket.close(code=1011, reason=str(e)[:200])
        except Exception:
            pass


@app.post("/api/stt")
async def stt(audio: UploadFile = File(...)):
    if not _FASTER:
        raise HTTPException(
            status_code=501,
            detail="faster-whisper not installed. Use browser speech or: pip install -r requirements-optional-stt.txt",
        )
    data = await audio.read()
    if not data or len(data) < 32:
        raise HTTPException(status_code=400, detail="Empty or too small audio")
    sfx = Path(audio.filename or "clip.webm").suffix or ".webm"
    with tempfile.NamedTemporaryFile(delete=False, suffix=sfx) as tmp:
        tmp.write(data)
        path = tmp.name
    try:
        model = _get_whisper()
        if not model:
            raise HTTPException(status_code=501, detail="Whisper not available")
        segs, _ = model.transcribe(path, language="en", vad_filter=True)
        text = " ".join(s.text for s in segs).strip()
    finally:
        try:
            os.unlink(path)
        except OSError:
            pass
    if not text:
        raise HTTPException(status_code=400, detail="No speech detected")
    return {"text": text}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("server:app", host="127.0.0.1", port=ENGINEER_PORT, reload=False)
