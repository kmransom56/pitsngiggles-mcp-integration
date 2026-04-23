# 🚀 Running pits-n-giggles (Manually)

This project uses Python 3.12 and is structured as a suite of apps under the `apps/` directory. Each sub-app can be run independently using Python's `-m` module mode.

## 🧰 Requirements

- **Python 3.12 or 3.13** (see `requires-python` in `pyproject.toml`) on your `PATH`
- **[Poetry](https://python-poetry.org/)** — the supported way to create the venv and install dependencies (this repo is **not** “uv-only”; see **[PYTHON_ENVIRONMENT.md](PYTHON_ENVIRONMENT.md)** for Poetry vs. optional `uv`/manual venv)

## 📦 Install Dependencies

Install only the production dependencies if you plan on running only the app and none of the tests:

```bash
poetry install --without dev
```

If you plan on running the app, dev utils, and unit tests, install all dependencies:

```bash
poetry install
```

This uses Poetry to set up a **virtual environment** and install what is defined in `pyproject.toml` (the project is `package-mode = false`, so you are not installing a library package, but you get all app dependencies).

---

## ▶️ Running Apps

The app can be launched by using the command

```bash
poetry run python -m apps.launcher
```

All commands below must be run **from the project root directory** (i.e., the folder containing `pyproject.toml`).

### 🧠 Backend App

```bash
poetry run python -m apps.backend --replay-server
```

Note:
The --replay-server flag enables the replay mode for the backend,
allowing the server to process pre-recorded events for debugging and testing.
Without this flag, the server will run in normal mode. For example, to run
in default mode, use:

```bash
poetry run python -m apps.backend
```

### 🛠 Dev Tools (e.g., telemetry replayer)

```bash
poetry run python -m apps.dev_tools.telemetry_replayer --file-name example.f1pcap
```

---

## ❗ Notes

- Do **not** include `.py` in module paths.
- Use dot (`.`) separators for nested module paths.
- You **must** be in the project root (`pits-n-giggles/`) when running these commands.
- All directories under `apps/` should **avoid hyphens** (`-`). Use underscores or camelCase instead to remain Python-compatible.

---

## 🧼 Cleaning Up

To remove the virtual environment created by Poetry, list envs and remove the one for this project:

```bash
poetry env list
poetry env remove <name-or-path-from-list>
```

To reinstall from a clean state:

```bash
poetry install --no-root
```

The **`engineer_voice/`** service uses its **own** venv at `engineer_voice\.venv` (created by the PowerShell launchers) and **`pip install -r engineer_voice/requirements.txt`**, not the Poetry venv. Remove that directory separately if you need a clean engineer voice install.
