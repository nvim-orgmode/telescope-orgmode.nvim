.PHONY: help test test-file format lint clean

help: ## Show available targets
	@egrep '^(.+)\:\ .*##\ (.+)' $(MAKEFILE_LIST) | sed 's/:.*##/#/' | column -t -c 2 -s '#'

test: ## Run all tests
	@nvim --headless --noplugin -u spec/minimal_init.lua \
		-c "lua require('plenary.test_harness').test_directory('spec', {minimal_init='spec/minimal_init.lua', sequential=true})"

test-file: ## Run specific test file (usage: make test-file FILE=org_spec.lua)
	@nvim --headless --noplugin -u spec/minimal_init.lua \
		-c "lua require('plenary.test_harness').test_directory('spec/$(FILE)', {minimal_init='spec/minimal_init.lua', sequential=true})"

format: ## Format Lua code with stylua
	@stylua lua/ spec/

lint: ## Check Lua code formatting with stylua
	@stylua --check lua/ spec/

clean: ## Remove vendor directory
	@rm -rf vendor/
