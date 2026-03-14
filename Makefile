.PHONY: help test test-plain test-file verify-keybindings verify-keybindings-telescope verify-keybindings-snacks format lint lint-sh clean

help: ## Show available targets
	@egrep '^(.+)\:\ .*##\ (.+)' $(MAKEFILE_LIST) | sed 's/:.*##/#/' | column -t -c 2 -s '#'

test: ## Run all tests (with formatter)
	@nvim --headless --noplugin -u spec/minimal_init.lua \
		-c "lua require('plenary.test_harness').test_directory('spec', {minimal_init='spec/minimal_init.lua', sequential=true})" \
		2>&1 | ./scripts/test-formatter.sh

test-plain: ## Run all tests (raw plenary output)
	@nvim --headless --noplugin -u spec/minimal_init.lua \
		-c "lua require('plenary.test_harness').test_directory('spec', {minimal_init='spec/minimal_init.lua', sequential=true})"

test-file: ## Run specific test file (usage: make test-file FILE=org_spec.lua)
	@nvim --headless --noplugin -u spec/minimal_init.lua \
		-c "lua require('plenary.test_harness').test_directory('spec/$(FILE)', {minimal_init='spec/minimal_init.lua', sequential=true})" \
		2>&1 | ./scripts/test-formatter.sh

manual-test: ## Run self-guided manual test (default: telescope)
	@./scripts/manual_test.sh telescope

manual-test-telescope: ## Run self-guided manual test (Telescope adapter)
	@./scripts/manual_test.sh telescope

manual-test-snacks: ## Run self-guided manual test (Snacks adapter)
	@./scripts/manual_test.sh snacks

format: ## Format Lua code with stylua
	@stylua lua/ spec/

lint: ## Check Lua code formatting with stylua
	@stylua --check lua/ spec/

lint-sh: ## Check bash scripts with shellcheck (if available)
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "Running shellcheck..."; \
		shellcheck scripts/*.sh; \
	else \
		echo "shellcheck not found, skipping..."; \
	fi

clean: ## Remove vendor directory
	@rm -rf vendor/
