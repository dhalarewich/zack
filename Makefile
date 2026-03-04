.PHONY: lint format format-check test all help

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

lint: ## Run gdlint on all GDScript files
	@bash tools/lint.sh

format: ## Auto-format all GDScript files with gdformat
	@bash tools/format.sh

format-check: ## Check GDScript formatting (CI-safe, no modifications)
	@bash tools/format.sh --check

test: ## Run GUT unit tests headless
	@bash tools/test.sh

all: lint format-check test ## Run lint + format check + tests
