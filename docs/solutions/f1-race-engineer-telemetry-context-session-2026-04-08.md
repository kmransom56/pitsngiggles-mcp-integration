# F1 Race Engineer Telemetry Context Session (2026-04-08)

## Goal

Enable the in-browser F1 Race Engineer to answer natural, open-ended questions using live telemetry context, instead of requiring canned prompt wording.

## Implemented Changes

### 1) Strategy Center sends rich telemetry context

- Updated `apps/frontend/html/strategy-center.html`.
- `callMCPChatAPI()` now sends:
  - `periodic`: full payload from `GET /telemetry-info`
  - `playerIndex`: inferred from `table-entries[].driver-info.is-player`
  - `playerDriver`: detailed payload from `GET /driver-info?index=<playerIndex>`
- Removed old flat telemetry mapping (`lap`, `tyre_temps`, `track_name`, etc.) that did not match backend schema.

### 2) MCP server switched to canonical telemetry readers

- Updated `lib/mcp_server/server.py` MCP tool handlers:
  - Replaced `.toDict()` usage with `.toJSON()`
  - Fixed stream overlay call to:
    - `StreamOverlayData(...).toJSON(stream_overlay_start_sample_data=False)`
- Updated analysis methods to work with current schema:
  - `PeriodicUpdateData.toJSON()` using `table-entries`
  - `DriverInfoRsp.toJSON()` kebab-case fields such as:
    - `driver-name`
    - `lap-time-history-data`
    - `lap-time-in-ms`
    - `sector-1-time-in-ms`, `sector-2-time-in-ms`, `sector-3-time-in-ms`
    - `tyre-info` fields

### 3) Chat behavior improved for non-canned prompts

- Updated `lib/mcp_server/server.py` general chat path:
  - Uses `telemetry.periodic` and `telemetry.playerDriver` when present
  - Produces live status summary and recommendations
  - Avoids default “ask specific questions” gate when telemetry context is available

### 4) Sync touch-up in standalone server model

- Updated `mcp_server/server.py` `TelemetryData` model to include:
  - `periodic`
  - `playerIndex`
  - `playerDriver`
- Removed unused imports surfaced by lint.

## Validation Run

Executed after edits:

- `uv run black lib/mcp_server/server.py mcp_server/server.py`
- `uv run flake8 lib/mcp_server/server.py mcp_server/server.py --max-line-length=88 --ignore=E203,W503,E501`
- `uv run python -m py_compile lib/mcp_server/server.py mcp_server/server.py`

All commands completed successfully.

## Git / Repository Updates Completed

- Pushed telemetry-context/chat improvements to fork branch:
  - `feature/f1-race-engineer-mcp`
- Rewrote fork history to remove `CLAUDE.md` from all commits and tags.
- Added repo notice:
  - `HISTORY_REWRITE_NOTICE.md`

## Suggested Next Steps

1. Add a small telemetry normalizer utility so analyzer methods share one schema adapter.
2. Add a smoke test for `/api/chat` with a sample `periodic` payload.
3. Add lightweight logging around missing telemetry keys to catch future schema drift quickly.
