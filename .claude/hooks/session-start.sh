#!/bin/bash
# SessionStart hook: prepares a Claude Code cloud session as a general-purpose
# workstation. Installs a few extra CLI tools and the dependencies of any
# project found under projects/. Idempotent and non-interactive.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

log() { echo "[session-start] $*" >&2; }

# --- Extra CLI tools (shellcheck, shfmt) via uv, cached in the container ---
for pkg in shellcheck-py shfmt-py; do
  bin="${pkg%-py}"
  if ! command -v "$bin" >/dev/null 2>&1; then
    log "installing $bin"
    uv tool install --quiet "$pkg" >&2 || log "warning: could not install $bin"
  fi
done

# --- Per-project dependencies under projects/<name>/ ---
shopt -s nullglob
for dir in "$ROOT"/projects/*/; do
  name="$(basename "$dir")"
  if [ -f "$dir/package.json" ]; then
    if [ -f "$dir/pnpm-lock.yaml" ]; then
      log "$name: pnpm install"
      (cd "$dir" && pnpm install --silent) >&2
    else
      log "$name: npm install"
      (cd "$dir" && npm install --no-audit --no-fund --silent) >&2
    fi
  fi
  if [ -f "$dir/pyproject.toml" ] || [ -f "$dir/requirements.txt" ]; then
    log "$name: python venv"
    (
      cd "$dir"
      [ -d .venv ] || uv venv --quiet .venv
      if [ -f uv.lock ]; then
        uv sync --quiet
      elif [ -f requirements.txt ]; then
        uv pip install --quiet --python .venv/bin/python -r requirements.txt
      else
        uv pip install --quiet --python .venv/bin/python -e .
      fi
    ) >&2
  fi
  if [ -f "$dir/go.mod" ]; then
    log "$name: go mod download"
    (cd "$dir" && go mod download) >&2
  fi
  if [ -f "$dir/Cargo.toml" ]; then
    log "$name: cargo fetch"
    (cd "$dir" && cargo fetch --quiet) >&2
  fi
done

# --- Session environment ---
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$HOME/.local/bin:\$PATH\"" >>"$CLAUDE_ENV_FILE"
fi

log "done"
