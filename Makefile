.PHONY: help setup dev test lint security audit \
        gen-model gen-controller gen-migration

NAME    ?=
FIELDS  ?=
ACTIONS ?=

help:
	@printf "Available targets:\n"
	@printf "  make setup                                              # Install gems and prepare the database\n"
	@printf "  make dev                                               # Start the development server\n"
	@printf "  make test                                              # Run the test suite\n"
	@printf "  make lint                                              # Run RuboCop\n"
	@printf "  make security                                          # Run Brakeman\n"
	@printf "  make audit                                             # Run bundler-audit\n"
	@printf "\n"
	@printf "  make gen-model      NAME=<Model>  [FIELDS=\"col:type\"]  # rails generate model\n"
	@printf "  make gen-controller NAME=<Name>   [ACTIONS=\"action ...\"] # controller + views + tests\n"
	@printf "  make gen-resource   NAME=<Name>   [FIELDS=\"col:type\"]  # full resource (model+ctrl+routes)\n"
	@printf "  make gen-migration  NAME=<Name>   [FIELDS=\"col:type\"]  # rails generate migration\n"
setup:
	@bin/setup

dev:
	@bin/dev

test:
	@bin/rails test

lint:
	@bin/rubocop

security:
	@bin/brakeman --no-pager

audit:
	@bin/bundler-audit

gen-model:
	@[ -n "$(NAME)" ] || (printf "Usage: make gen-model NAME=<Model> [FIELDS=\"col:type ...\"]\n"; exit 1)
	@bin/rails generate model $(NAME) $(FIELDS)

gen-controller:
	@[ -n "$(NAME)" ] || (printf "Usage: make gen-controller NAME=<Name> [ACTIONS=\"action ...\"]\n"; exit 1)
	@bin/rails generate controller $(NAME) $(ACTIONS)
	@bin/rails generate system_test $(NAME)

gen-resource:
	@[ -n "$(NAME)" ] || (printf "Usage: make gen-resource NAME=<Name> [FIELDS=\"col:type ...\"]\n"; exit 1)
	@bin/rails generate resource $(NAME) $(FIELDS)
	@bin/rails generate system_test $(NAME)

gen-migration:
	@[ -n "$(NAME)" ] || (printf "Usage: make gen-migration NAME=<MigrationName> [FIELDS=\"col:type ...\"]\n"; exit 1)
	@bin/rails generate migration $(NAME) $(FIELDS)
