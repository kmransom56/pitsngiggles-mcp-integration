# MIT License — ASGI sub-application mount for one-process deployment

from __future__ import annotations

import typing
from collections.abc import Awaitable, Callable

ASGI = typing.Callable[
    [dict, typing.Any, typing.Callable],
    Awaitable[None],
]


def asgi_mount_at_prefix(
    main: ASGI,
    prefix: str,
    sub: ASGI,
) -> ASGI:
    """
    Insert ``sub`` so it handles ``prefix`` and everything under it.
    The sub-app sees paths with ``prefix`` stripped (e.g. ``/api/...`` for ``/race-engineer/api/...``).
    """

    p = prefix.rstrip("/")
    if not p.startswith("/"):
        p = "/" + p
    p_len = len(p)

    async def dispatch(scope, receive, send):
        t = scope.get("type")
        if t not in ("http", "websocket", "lifespan"):
            return await main(scope, receive, send)
        if t == "lifespan":
            return await main(scope, receive, send)
        path = scope.get("path") or ""
        if not (path == p or path.startswith(p + "/")):
            return await main(scope, receive, send)
        rest = path[p_len:] or "/"
        if not rest.startswith("/"):
            rest = "/" + rest
        s2: dict = dict(scope)
        s2["path"] = rest
        root = scope.get("root_path") or ""
        s2["root_path"] = root + p
        return await sub(s2, receive, send)

    return dispatch
