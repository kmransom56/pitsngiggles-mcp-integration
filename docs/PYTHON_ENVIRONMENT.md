# Python environment: Poetry (official) and alternatives

This repo is **not** built or run through **`uv` by default**. The documented path uses **[Poetry](https://python-poetry.org/)** and the versions declared in `pyproject.toml` (`requires-python = ">=3.12,<3.14"`).

## What Poetry does here

- Poetry creates and manages a **virtual environment** and installs the dependencies under `[project]` in `pyproject.toml`.
- `[tool.poetry] package-mode = false` means the project is **not** packaged as an installable library; `poetry install` still **installs dependencies** you need to run and build (including PyInstaller for the Windows executable).

**Typical commands (from the repository root):**

```bash
poetry install --without dev
poetry run python -m apps.launcher
poetry run python scripts/build.py
```

See [BUILDING.md](BUILDING.md) and [RUNNING.md](RUNNING.md) for the full flow.

## Optional: `uv` or a manual venv (without Poetry)

If you prefer not to use Poetry, you can still use a normal **venv** and **`pip`**, or use **[uv](https://docs.astral.sh/uv/)** to install a Python and create `.venv` yourself. This is **not** the maintained workflow in the main docs, but it works if you install the same dependency set.

- **Python version:** 3.12 or 3.13 (see `pyproject.toml`).
- **Dependencies:** use the list under `[project] dependencies` in `pyproject.toml` (e.g. install with `pip` after resolving versions, or use `uv pip install` with the same constraints).
- **Build:** with the venv active, `python scripts/build.py` (PyInstaller) from the repo root, same as `poetry run python scripts/build.py`.
- A plain `pip install .` may fail for this layout because the project is in **non-package** mode; installing **dependencies** explicitly (or `uv sync` with a hand-authored lock) is the practical workaround when not using Poetry.

## LAN race engineer (`engineer_voice/`)

The **engineer voice** service is a **separate** small app with its own `engineer_voice/requirements.txt` (and optional `requirements-optional-stt.txt`).

- `start_engineer_voice.ps1` / `launch_race_center.ps1` create or reuse **`engineer_voice\.venv`** and install with **`pip`**, not Poetry (by design, so the stack is self-contained next to the integration scripts).
- To run it manually: create a venv under `engineer_voice/`, `pip install -r requirements.txt`, then `uvicorn server:app` (see that folder’s `server.py` and `RUNNING` notes in the [README](../README.md)).

## Summary

| Area | Tooling |
|------|--------|
| Main Pits n’ Giggles app (launcher, backend, PyInstaller build) | **Poetry** (documented) |
| Optional: same deps without Poetry | **venv** + **pip** or **uv** to manage Python/venv; align deps with `pyproject.toml` |
| `engineer_voice` HTTP service | **Dedicated venv** in `engineer_voice\.venv` + **pip** (as driven by the PowerShell scripts) |

If anything in the docs still says to use only `uv` for the main app, treat **Poetry** as the source of truth unless you are deliberately using an alternative venv as above.
