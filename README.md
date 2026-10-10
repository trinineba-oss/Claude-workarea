# Claude-workarea

A general-purpose remote workstation for [Claude Code on the web](https://code.claude.com/docs/en/claude-code-on-the-web).
Open a cloud session on this repo and you get a ready-to-use Linux box with the
common toolchains, plus automatic dependency setup for anything you drop into
`projects/`.

## Layout

| Path | Purpose |
| --- | --- |
| `projects/<name>/` | One folder per project. Committed. Dependencies install automatically at session start. |
| `projects/pixel-game/` | A starter Godot 2D pixel-art game for Android. See its README. |
| `scratch/` | Throwaway work. Git-ignored, so it disappears with the container. |
| `.claude/hooks/session-start.sh` | SessionStart hook that prepares each cloud session. |
| `.claude/settings.json` | Registers the hook. |
| `CLAUDE.md` | Working conventions Claude follows in this repo. |
| `tests/` | Test for the session-start hook. |

## What the session-start hook does

Runs only in cloud sessions (`CLAUDE_CODE_REMOTE=true`), synchronously, before
the session starts:

1. Installs `shellcheck` and `shfmt` (the base image already has Python, uv,
   Node, pnpm, Go, Rust, Java, Ruby, Docker, ruff, black, pytest, eslint and
   prettier).
2. For each `projects/<name>/`, installs dependencies based on what it finds:
   - `package.json` → `pnpm install` if `pnpm-lock.yaml` exists, else `npm install`
   - `pyproject.toml` / `requirements.txt` → a `.venv` via uv (`uv sync` when `uv.lock` exists)
   - `go.mod` → `go mod download`
   - `Cargo.toml` → `cargo fetch`
   - `project.godot` → Godot 4.7.2 and its export templates (from the Nix cache) plus `gdtoolkit`
3. Adds `~/.local/bin` to the session `PATH`.

The container state is cached after the hook finishes, so later sessions start faster.

## Commands

```sh
make setup   # run the hook by hand (e.g. after adding a project mid-session)
make lint    # shellcheck + shfmt on the repo's shell scripts
make test    # exercise the hook against sample projects
```

## Things to know

- **Containers are ephemeral.** Commit and push anything you want to keep;
  uncommitted work and `scratch/` are lost when the session ends.
- **Secrets** belong in the cloud environment's settings (environment
  variables), not in this repo. `.env*` files are git-ignored as a backstop.
- **Network access** is governed by the environment's network policy. If a
  package registry or API is blocked, change the policy in the environment
  settings.
- The hook only takes effect for new sessions once it is on the default branch.
