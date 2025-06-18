SHELL:=/bin/bash

.PHONY: install
install: ## make install # Install dependencies
	@rbenv install -s && gem install bundler && bundle install
	@overcommit --install && overcommit --sign pre-commit
	@. "$$HOME/.nvm/nvm.sh" && nvm install && npm install && npm i -g npx || true

.PHONY: lint
lint: ## make lint # Run all linters
	@bundle exec standardrb --fix
	@npx prettier . --write

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
