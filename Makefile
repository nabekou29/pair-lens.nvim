.PHONY: test clean-test

test:
	@echo "Running tests..."
	nvim --clean -l tests/busted.lua tests

clean-test:
	@echo "Cleaning up test files..."
	rm -rf .tests
