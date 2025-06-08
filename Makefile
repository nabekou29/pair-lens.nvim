.PHONY: test clean-test

test:
	@echo "Running tests..."
	NVIM_LISTEN_ADDRESS="" nvim -l tests/busted.lua tests

clean-test:
	@echo "Cleaning up test files..."
	rm -rf .tests
