#!/bin/bash
# Runs the SessionStart hook against a throwaway workspace with sample
# projects and checks that their dependencies were installed.
set -euo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/.claude/hooks/session-start.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/projects/py" "$WORK/projects/js"
echo "six" >"$WORK/projects/py/requirements.txt"
echo '{"name":"js","version":"0.0.0","dependencies":{"left-pad":"1.3.0"}}' \
  >"$WORK/projects/js/package.json"
touch "$WORK/env"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# Outside a cloud session the hook must be a no-op.
CLAUDE_CODE_REMOTE='' CLAUDE_PROJECT_DIR="$WORK" "$HOOK"
[ ! -d "$WORK/projects/py/.venv" ] || fail "hook ran outside a cloud session"

CLAUDE_CODE_REMOTE=true CLAUDE_PROJECT_DIR="$WORK" CLAUDE_ENV_FILE="$WORK/env" "$HOOK"
"$WORK/projects/py/.venv/bin/python" -c "import six" || fail "python deps missing"
[ -d "$WORK/projects/js/node_modules/left-pad" ] || fail "node deps missing"
grep -q "PATH" "$WORK/env" || fail "env file not written"
command -v shellcheck >/dev/null || fail "shellcheck missing"

# Second run must succeed too (idempotent).
CLAUDE_CODE_REMOTE=true CLAUDE_PROJECT_DIR="$WORK" CLAUDE_ENV_FILE="$WORK/env" "$HOOK"

echo "PASS"
