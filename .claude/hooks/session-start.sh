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

# --- Godot engine (+ export templates, gdtoolkit) for Godot projects ---
# Godot's own download hosts are blocked in cloud sessions, but the Nix binary
# cache is reachable, so install from a pinned nixpkgs snapshot.
NIXPKGS="https://releases.nixos.org/nixos/unstable/nixos-26.11pre1087755.e7439b6b14ad/nixexprs.tar.xz"
GODOT_CACHE="$HOME/.cache/godot-nix"
if compgen -G "$ROOT/projects/*/project.godot" >/dev/null; then
  if command -v nix-build >/dev/null 2>&1; then
    mkdir -p "$GODOT_CACHE" "$HOME/.local/bin"
    log "godot: nix-build engine and export templates"
    nix-build "$NIXPKGS" -A godot -o "$GODOT_CACHE/engine" >&2
    nix-build "$NIXPKGS" -A godot_4_7-export-templates-bin -o "$GODOT_CACHE/templates" >&2
    ln -sf "$GODOT_CACHE/engine/bin/godot" "$HOME/.local/bin/godot"
    mkdir -p "$HOME/.local/share/godot/export_templates"
    for tpl in "$GODOT_CACHE"/templates/share/godot/export_templates/*; do
      ln -sfn "$(readlink -f "$tpl")" "$HOME/.local/share/godot/export_templates/$(basename "$tpl")"
    done
  else
    log "warning: nix not found, skipping Godot install"
  fi
  if ! command -v gdlint >/dev/null 2>&1; then
    log "installing gdtoolkit"
    uv tool install --quiet gdtoolkit >&2 || log "warning: could not install gdtoolkit"
  fi
fi

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
