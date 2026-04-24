# MIT License
#
# Copyright (c) [2024] [Ashwin Natarajan]
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# -------------------------------------- IMPORTS -----------------------------------------------------------------------

import html
import logging
import os
import sys
import webbrowser
from http import HTTPStatus
from pathlib import Path
from typing import Any, Dict, Tuple

from apps.backend.state_mgmt_layer import SessionState
from apps.backend.state_mgmt_layer.intf import (
    DriverInfoRsp,
    PeriodicUpdateData,
    RaceInfoData,
    StreamOverlayData,
)
from lib.child_proc_mgmt import notify_parent_init_complete
from lib.config import PngSettings
from lib.mcp_server import MCPServer, MCP_HTTP_PATH, MCP_HTTP_PATH_LEGACY
from lib.web_server import BaseWebServer, ClientType

# -------------------------------------- GLOBALS -----------------------------------------------------------------------

# -------------------------------------- CLASS DEFINITIONS -------------------------------------------------------------


class TelemetryWebServer(BaseWebServer):
    """
    A web server class for handling telemetry-related web services and socket communications.

    This class sets up HTTP and WebSocket routes for serving telemetry data,
    static files, and managing client connections.

    Attributes:
        m_port (int): The port number on which the server will run.
        m_debug_mode (bool): Flag to enable/disable debug mode.
        m_app (Quart): The Quart web application instance.
        m_sio (socketio.AsyncServer): The Socket.IO server instance.
        m_sio_app (socketio.ASGIApp): The combined Quart and Socket.IO ASGI application.
        m_ver_str (str): The version string.
        m_logger (logging.Logger): The logger instance.
    """

    def __init__(
        self,
        settings: PngSettings,
        ver_str: str,
        logger: logging.Logger,
        session_state: SessionState,
        debug_mode: bool = False,
    ):
        """
        Initialize the TelemetryWebServer.

        Args:
            settings (PngSettings): App settings.
            ver_str (str): The version string.
            logger (logging.Logger): The logger instance.
            session_state (SessionState): Handle to the session state
            debug_mode (bool, optional): Enable or disable debug mode. Defaults to False.
        """
        super().__init__(
            port=settings.Network.server_port,
            ver_str=ver_str,
            logger=logger,
            client_event_mappings={
                ClientType.RACE_TABLE: ["frontend-update", "race-table-update"],
                ClientType.HUD: [
                    "hud-toggle-notification",
                    "hud-cycle-mfd-notification",
                    "hud-prev-page-mfd-notification",
                    "hud-mfd-interaction-notification",
                ],
                ClientType.PLAYER_STREAM_OVERLAY: ["stream-overlay-update"],
            },
            cert_path=settings.HTTPS.cert_path,
            key_path=settings.HTTPS.key_path,
            debug_mode=debug_mode,
        )
        self.define_routes()
        self.register_post_start_callback(self._post_start)
        self.m_show_start_sample_data = settings.StreamOverlay.show_sample_data_at_start
        self.m_session_state: SessionState = session_state
        self.m_disable_browser_autoload = settings.Display.disable_browser_autoload
        self.m_mcp_server = MCPServer(session_state, logger)
        self.m_race_engineer_mounted: bool = False
        self.m_race_engineer_fallback_registered: bool = False
        self._try_mount_race_engineer()

    def _ensure_repo_root_on_path(self) -> None:
        """So ``import engineer_voice`` works when the process cwd is not the repo root."""
        root = Path(__file__).resolve().parents[3]
        s = str(root)
        if s and s not in sys.path:
            sys.path.insert(0, s)

    def _register_race_engineer_unavailable_routes(self, detail: str) -> None:
        """Quart 404 is confusing when the ASGI sub-app did not mount; return 503 with instructions."""
        if self.m_race_engineer_fallback_registered:
            return
        self.m_race_engineer_fallback_registered = True
        body = f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><title>LAN race engineer unavailable</title></head>
<body>
<h1>LAN race engineer is not available on this process</h1>
<p>Expected URL: <code>/race-engineer/</code> (should be served by the in-process FastAPI app).</p>
<p><b>What to do</b></p>
<ul>
<li>Install the same app dependencies as <code>pyproject.toml</code> (e.g. <code>fastapi</code>, <code>httpx</code>, <code>python-multipart</code>) in the environment that runs Pits n&apos; Giggles, then restart.</li>
<li>If you set <code>RACE_ENGINEER_DISABLE_MOUNT</code>, unset it and restart, or use standalone: <code>RACE_ENGINEER_STANDALONE=1</code> and the port <code>11734</code> server.</li>
</ul>
<p><b>Details</b></p>
<pre style="white-space:pre-wrap">{html.escape(detail, quote=False)}</pre>
</body></html>"""

        from quart import Response

        @self.http_route("/race-engineer/")
        async def _re_unavailable_slash() -> Response:
            return Response(
                body,
                status=503,
                mimetype="text/html; charset=utf-8",
            )

        @self.http_route("/race-engineer")
        async def _re_unavailable_noslash() -> Response:
            return Response(
                body,
                status=503,
                mimetype="text/html; charset=utf-8",
            )

    def _try_mount_race_engineer(self) -> None:
        """LAN race engineer (FastAPI) at ``/race-engineer`` on the same port as this server."""
        if os.environ.get("RACE_ENGINEER_DISABLE_MOUNT", "").strip() in (
            "1",
            "true",
            "yes",
        ):
            self.m_logger.info(
                "LAN race engineer mount disabled (RACE_ENGINEER_DISABLE_MOUNT). "
                "Use standalone on 11734 with RACE_ENGINEER_STANDALONE=1 or unset the env and restart."
            )
            self._register_race_engineer_unavailable_routes(
                "RACE_ENGINEER_DISABLE_MOUNT is set."
            )
            return
        self._ensure_repo_root_on_path()
        try:
            from lib.asgi_prefix_mount import asgi_mount_at_prefix
            from engineer_voice.server import app as _race_engineer_asgi
        except Exception as exc:
            self.m_logger.warning(
                "LAN race engineer not mounted (import failed). "
                "Install fastapi, httpx, python-multipart per pyproject.toml and restart. %s",
                exc,
            )
            self._register_race_engineer_unavailable_routes(
                f"{type(exc).__name__}: {exc!s}"
            )
            return
        if not os.environ.get("PNG_BASE", "").strip():
            proto = "https" if self.m_cert_path else "http"
            os.environ["PNG_BASE"] = f"{proto}://127.0.0.1:{self.m_port}"
        try:
            self.m_sio_app = asgi_mount_at_prefix(
                self.m_sio_app,
                "/race-engineer",
                _race_engineer_asgi,
            )
        except Exception as exc:
            self.m_logger.warning("LAN race engineer mount failed: %s", exc)
            self._register_race_engineer_unavailable_routes(
                f"{type(exc).__name__}: {exc!s}"
            )
            return
        self.m_race_engineer_mounted = True
        self.m_logger.info(
            "LAN Race Engineer: http://127.0.0.1:%s/race-engineer/ (Ollama + voice, same app)",
            self.m_port,
        )

    def define_routes(self) -> None:
        """
        Define all HTTP routes for the web server.

        This method calls sub-methods to set up file and data routes.
        """

        self._defineTemplateFileRoutes()
        self._defineDataRoutes()
        self._defineMCPRoutes()

    def _defineTemplateFileRoutes(self) -> None:
        """
        Define routes for rendering HTML templates.

        Sets up routes for the main index page and stream overlay page.
        """

        @self.http_route("/")
        async def index() -> str:
            """
            Render the main index page.

            Returns:
                str: Rendered HTML content for the index page.
            """
            return await self.render_template(
                "driver-view.html", live_data_mode=True, version=self.m_ver_str
            )

        @self.http_route("/eng-view")
        async def engineerView() -> str:
            """
            Render the engineer view page.

            Returns:
                str: Rendered HTML content for the stream overlay page.
            """
            return await self.render_template(
                "eng-view.html", live_data_mode=True, version=self.m_ver_str
            )

        @self.http_route("/player-stream-overlay")
        async def playerStreamOverlay() -> str:
            """
            Render the player stream overlay page.

            Returns:
                str: Rendered HTML content for the stream overlay page.
            """
            return await self.render_template("player-stream-overlay.html")

        @self.http_route("/strategy-center")
        async def strategyCenter() -> str:
            """
            Render the AI-powered strategy center page.

            Returns:
                str: Rendered HTML content for the strategy center.
            """
            return await self.render_template("strategy-center.html")

    def _defineDataRoutes(self) -> None:
        """
        Define HTTP routes for retrieving telemetry and race-related data.

        Sets up endpoints for fetching race info, telemetry info,
        driver info, and stream overlay info.
        """

        @self.http_route("/telemetry-info")
        async def telemetryInfoHTTP() -> Tuple[str, int]:
            """
            Provide telemetry information via HTTP.

            Returns:
                Tuple[str, int]: JSON response and HTTP status code.
            """
            return PeriodicUpdateData(self.m_session_state).toJSON(), HTTPStatus.OK

        @self.http_route("/race-info")
        async def raceInfoHTTP() -> Tuple[str, int]:
            """
            Provide overall race statistics via HTTP.

            Returns:
                Tuple[str, int]: JSON response and HTTP status code.
            """
            return RaceInfoData(self.m_session_state).toJSON(), HTTPStatus.OK

        @self.http_route("/driver-info")
        async def driverInfoHTTP() -> Tuple[str, int]:
            """
            Provide driver information based on the index parameter.

            Returns:
                Tuple[str, int]: JSON response and HTTP status code.
            """
            return self._processDriverInfoRequest(self.request.args.get("index"))

        @self.http_route("/stream-overlay-info")
        async def streamOverlayInfoHTTP() -> Tuple[str, int]:
            """
            Provide stream overlay telemetry information via HTTP.

            Returns:
                Tuple[str, int]: JSON response and HTTP status code.
            """
            return (
                StreamOverlayData(self.m_session_state).toJSON(
                    self.m_show_start_sample_data
                ),
                HTTPStatus.OK,
            )

    def _processDriverInfoRequest(
        self, index_arg: Any
    ) -> Tuple[Dict[str, Any], HTTPStatus]:
        """
        Process driver info request.

        Args:
            index_arg (Any): The index parameter, expected to be a number.

        Returns:
            Tuple[Dict[str, Any], HTTPStatus]: The response and HTTP status code.
        """

        # Validate the input
        if error_response := self.validate_int_get_request_param(index_arg, "index"):
            return error_response, HTTPStatus.BAD_REQUEST

        # Check if the given index is valid
        index_int = int(index_arg)
        if not self.m_session_state.isIndexValid(index_int):
            error_response = {
                "error": "Invalid parameter value",
                "message": "Invalid index",
                "index": index_arg,
            }
            return self.jsonify(error_response), HTTPStatus.NOT_FOUND

        # Process parameters and generate response
        return DriverInfoRsp(self.m_session_state, index_int).toJSON(), HTTPStatus.OK

    def _defineMCPRoutes(self) -> None:
        """
        Define Model Context Protocol (MCP) routes for AI tool integration.

        Sets up Server-Sent Events endpoint for ChatGPT, Claude, Cursor, etc.
        Canonical path: ``MCP_HTTP_PATH`` (``/f1-race-engineer-lan``).
        Legacy alias: ``MCP_HTTP_PATH_LEGACY`` (``/mcp``).
        """

        from quart import Response

        async def mcpEndpoint():
            """
            MCP Server-Sent Events endpoint for AI tools.

            Provides real-time telemetry data access to AI assistants using
            the Model Context Protocol over SSE.
            """

            async def generate():
                async for event in self.m_mcp_server.stream_events():
                    yield event

            return Response(
                generate(),
                mimetype="text/event-stream",
                headers={
                    "Cache-Control": "no-cache",
                    "X-Accel-Buffering": "no",
                    "Connection": "keep-alive",
                    "Access-Control-Allow-Origin": "*",
                },
            )

        async def mcpToolsEndpoint():
            """
            Handle MCP tool invocation requests.

            Allows AI tools to call specific telemetry functions via POST.
            """
            data = await self.request.get_json()
            method = data.get("method", "tools/list")
            params = data.get("params", {})

            result = await self.m_mcp_server.handle_request(method, params)
            return self.jsonify(result), HTTPStatus.OK

        for path in (MCP_HTTP_PATH, MCP_HTTP_PATH_LEGACY):
            self.m_app.route(path)(mcpEndpoint)
        for path in (f"{MCP_HTTP_PATH}/tools", f"{MCP_HTTP_PATH_LEGACY}/tools"):
            self.m_app.route(path, methods=["POST"])(mcpToolsEndpoint)

    async def _post_start(self) -> None:
        """Function to be called after the server starts serving."""
        notify_parent_init_complete()
        if not self.m_disable_browser_autoload:
            proto = "https" if self.m_cert_path else "http"
            path = "/race-engineer/" if self.m_race_engineer_mounted else "/"
            webbrowser.open(f"{proto}://localhost:{self.m_port}{path}", new=2)
