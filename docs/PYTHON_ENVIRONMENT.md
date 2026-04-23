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
- **If the Windows `py` launcher reports “No suitable Python runtime”** (often when only a non-default install exists), set **`ENGINEER_PYTHON`** to the full path of a **Python 3.10+** `python.exe`, or install Python from [python.org](https://www.python.org/downloads/) with the **launcher** and **PATH** options, or install **[uv](https://docs.astral.sh/uv/)** and run `uv python install 3.13` so `uv venv` can create the venv. Run **`py -0`** in a terminal to see registered runtimes. **Astral/uv** installs show as e.g. `-V:Astral/CPython3.13.11`; the launch script tries those tags after `py -3.xx`. To pick one first: `$env:ENGINEER_PY_TAG = '-V:Astral/CPython3.13.11'`.
- To run it manually: create a venv under `engineer_voice/`, `pip install -r requirements.txt`, then `uvicorn server:app` (see that folder’s `server.py` and `RUNNING` notes in the [README](../README.md)).

## Summary

| Area | Tooling |
|------|--------|
| Main Pits n’ Giggles app (launcher, backend, PyInstaller build) | **Poetry** (documented) |
| Optional: same deps without Poetry | **venv** + **pip** or **uv** to manage Python/venv; align deps with `pyproject.toml` |
| `engineer_voice` HTTP service | **Dedicated venv** in `engineer_voice\.venv` + **pip** (as driven by the PowerShell scripts) |

If anything in the docs still says to use only `uv` for the main app, treat **Poetry** as the source of truth unless you are deliberately using an alternative venv as above.

## Windows: “script is installed in … which is not on PATH”

If you `pip install` with the **per-user** layout (e.g. into `…\AppData\Roaming\Python\Python3xx\site-packages`) **without** a venv, pip may place companion `.exe` tools under `…\AppData\Roaming\Python\Python3xx\Scripts` and warn that this directory is not on your **user PATH**. Your **imports still work**; only running those **CLI** tools by name from a shell may fail until you add that `Scripts` folder to your user `Path` or, preferably, use a **project venv** (e.g. `engineer_voice\.venv`) and install with that environment’s `python -m pip`.

## What to add to PATH (Windows)

Add **user** `Path` entries (Settings → *System* → *About* → *Advanced system settings* → *Environment variables* → select **Path** under your user → **Edit** → **New**). You only need the rows that match how you work.

| What | Typical directory to add | When you need it |
|------|--------------------------|------------------|
| **Per-user Python scripts** (pip/Windows Store / `python` installer) | `%UserProfile%\AppData\Roaming\Python\Python314\Scripts` | You installed packages with a **per-user** Python and want `tqdm`, `huggingface-cli`, `hf`, etc. on PATH. Replace **`314`** with your folder (e.g. `Python312` for 3.12, `Python313` for 3.13, `Python314` for 3.14). Check what exists under `%UserProfile%\AppData\Roaming\Python\`. |
| **Repository venv (main app)** | `<repo>\.venv\Scripts` | You use a project `.venv` at the repo root and want to run `python`, `uvicorn`, etc. without typing the full path. |
| **Engineer voice venv** | `<repo>\engineer_voice\.venv\Scripts` | Same, for the LAN engineer venv (e.g. `uvicorn.exe` in that venv). |
| **Poetry** | See `where poetry` after install, or e.g. `%UserProfile%\.local\bin` (installer-dependent) | The `poetry` command is not found in a new terminal. |
| **ffmpeg** | Folder that contains `ffmpeg.exe` (e.g. from [gyan.dev](https://www.gyan.dev/ffmpeg/builds/) or `chocolatey`’s `bin`) | **Optional** local STT / webm paths in `engineer_voice`; many setups work without it, but the docs note it for some formats. |

**Prefer venvs over global Scripts:** if you use **`engineer_voice\.venv`**, you usually **do not** need the Roaming `Python314\Scripts` path for this repo, as long as you run `.\engineer_voice\.venv\Scripts\python.exe` or `python -m uvicorn` with that venv’s Python.

**One-off in PowerShell (current session only)**, after replacing the version if needed:

```powershell
$env:Path = "$env:UserProfile\AppData\Roaming\Python\Python314\Scripts;" + $env:Path
```

**Persist for your user (PowerShell)** — only if you are sure the path is correct:

```powershell
[Environment]::SetEnvironmentVariable(
  "Path",
  "$env:UserProfile\AppData\Roaming\Python\Python314\Scripts;" + [Environment]::GetEnvironmentVariable("Path", "User"),
  "User"
)
```

Open a **new** terminal after changing PATH.
