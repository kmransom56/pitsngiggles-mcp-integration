"""
LAN-only race engineer: pulls telemetry from Pits n' Giggles (HTTP) and
answers via a local Ollama model. Serves a small browser UI on the same port.
"""

from __future__ import annotations

import json
import os
import tempfile
import threading
from pathlib import Path

import httpx
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from pydantic import BaseModel, Field

APP_DIR = Path(__file__).resolve().parent
STATIC = APP_DIR / "static"

OLLAMA_BASE = os.environ.get("OLLAMA_BASE", "http://127.0.0.1:11434")
PNG_BASE = os.environ.get("PNG_BASE", "http://127.0.0.1:4768")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "llama3.1")
WHISPER_MODEL = os.environ.get("WHISPER_MODEL", "small")
ENGINEER_PORT = int(os.environ.get("ENGINEER_VOICE_PORT", "11734"))

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
