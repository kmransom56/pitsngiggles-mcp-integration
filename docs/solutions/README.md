# `docs/solutions/` — learnings workflow

Markdown files here are **searchable institutional memory**: past fixes, session notes, and runbooks. Agents and humans should add new entries when resolving non-obvious issues.

## Frontmatter schema (YAML)

Place a `---` block at the top of each file. Use this shape unless a file explicitly documents an exception.

| Field | Required | Description |
|--------|----------|-------------|
| `id` | yes | Unique slug, kebab-case, stable over time (e.g. `pitsngiggles-2026-04-07-cursor-strategy-mcp`). |
| `kind` | yes | One of: `session-note`, `incident`, `howto`, `adr`, `runbook`. |
| `title` | yes | Human-readable title (can match H1 below). |
| `summary` | yes | 1–3 sentences for retrieval; state problem + root cause or fix. |
| `written` | yes | `YYYY-MM-DD` when the note was first captured. |
| `tags` | yes | Lowercase tokens: product areas, tools, symptoms (e.g. `cursor`, `nginx`, `mcp`). |
| `updated` | no | `YYYY-MM-DD` last substantive edit. |
| `components` | no | Repo paths or logical areas (e.g. `apps/frontend/html/strategy-center.html`). |
| `symptoms` | no | Short bullet strings a future searcher might match. |

### Single source of truth

- Put the **full body** of a learning or troubleshooting write-up in **`docs/solutions/<file>.md`** (this folder).
- If you want a second path under **`docs/troubleshooting/`** for discoverability, add a **stub** there: minimal frontmatter plus a link to the solutions file. Use frontmatter key **`redirect_to`** on the stub pointing at the solutions file (relative path). **Do not duplicate** the long body in two places.

### `kind` values

- **session-note** — Multi-topic capture from a working session.
- **incident** — Production or user-visible break; include timeline if useful.
- **howto** — Repeatable procedure.
- **adr** — Architecture decision (link to full ADR if elsewhere).
- **runbook** — Operational steps (restart order, URLs, rollback).

### Naming files

Prefer `topic-slug-YYYY-MM-DD.md` or `YYYY-MM-DD-topic-slug.md`; keep `id` in frontmatter stable even if the filename changes.
