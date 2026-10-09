# Claude-workarea

This repo is a general-purpose remote workstation for Claude Code cloud sessions.

## Conventions

- Put each real project in its own folder under `projects/<name>/`. Keep
  project-specific instructions in `projects/<name>/CLAUDE.md`.
- Put throwaway experiments in `scratch/` (git-ignored).
- After adding a project or changing its dependency manifest mid-session, run
  `make setup` so its dependencies install.
- Python projects use a per-project `.venv` managed with `uv`; run tools via
  `.venv/bin/...` or `uv run`.
- Never commit secrets; use environment variables configured on the cloud
  environment.
- The container is ephemeral: commit and push work you want to keep.

## Checks

- `make lint` — shellcheck + shfmt (2-space indent) for shell scripts.
- `make test` — tests for the session-start hook.
- Run both after changing `.claude/hooks/session-start.sh`.
