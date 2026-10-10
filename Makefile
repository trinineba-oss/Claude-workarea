SHELL_FILES := .claude/hooks/session-start.sh tests/session_start_test.sh

GODOT_PROJECTS := $(patsubst %/project.godot,%,$(wildcard projects/*/project.godot))

.PHONY: lint test setup

lint:
	shellcheck $(SHELL_FILES)
	shfmt -d -i 2 $(SHELL_FILES)
	@for p in $(GODOT_PROJECTS); do \
		echo "gdlint $$p"; \
		gdformat --check $$p/scripts $$p/tests && gdlint $$p/scripts $$p/tests || exit 1; \
	done

test:
	tests/session_start_test.sh
	@for p in $(GODOT_PROJECTS); do \
		echo "godot test $$p"; \
		godot --headless --path $$p --import >/dev/null 2>&1; \
		godot --headless --path $$p --script res://tests/smoke_test.gd || exit 1; \
	done

setup:
	CLAUDE_CODE_REMOTE=true .claude/hooks/session-start.sh
