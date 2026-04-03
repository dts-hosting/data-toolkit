.DEFAULT_GOAL := help
SHELL:=/bin/bash

.PHONY: hooks
hooks: ## make hooks # Install overcommit and init it
	@overcommit --install && overcommit --sign pre-commit

.PHONY: install
install: ## make install # Install dependencies
	@bundle install
	@pnpm install

.PHONY: lint
lint: ## make lint # Run all linters
	@bundle exec standardrb --fix
	@pnpm exec prettier . --write

.PHONY: test
test: ## make test # Run all tests
	@bin/rails db:test:prepare test test:system

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
