SHELL_FILES := .claude/hooks/session-start.sh tests/session_start_test.sh

.PHONY: lint test setup

lint:
	shellcheck $(SHELL_FILES)
	shfmt -d -i 2 $(SHELL_FILES)

test:
	tests/session_start_test.sh

setup:
	CLAUDE_CODE_REMOTE=true .claude/hooks/session-start.sh
