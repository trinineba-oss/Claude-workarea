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
		for t in $$p/tests/*_test.gd; do \
			echo "  $$(basename $$t)"; \
			out=$$(mktemp); \
			timeout 120 godot --headless --path $$p --script res://tests/$$(basename $$t) >$$out 2>&1; \
			status=$$?; \
			cat $$out; \
			if [ $$status -ne 0 ] || grep -qE 'SCRIPT ERROR|Parse Error|Compile Error' $$out; then \
				rm -f $$out; echo "  FAILED: $$(basename $$t) (exit $$status or script errors)"; exit 1; \
			fi; \
			rm -f $$out; \
		done; \
	done

setup:
	CLAUDE_CODE_REMOTE=true .claude/hooks/session-start.sh
