.PHONY: help build up down logs ps run-benchmarker
.DEFAULT_GOAL := help

setup: ## Setup data
	rm -rf webapp/sql/dump.sql benchmarker/userdata/img
	cd webapp/sql && \
	curl -L -O https://github.com/catatsuy/private-isu/releases/download/img/dump.sql.bz2 && \
	bunzip2 dump.sql.bz2
	cd benchmarker/userdata && \
	curl -L -O https://github.com/catatsuy/private-isu/releases/download/img/img.zip && \
	unzip img.zip && \
	rm img.zip

build: ## Build docker image
	docker compose -f ./webapp/docker-compose.yml build --no-cache 

up: ## Do docker compose up
	docker compose -f ./webapp/docker-compose.yml up -d

down: ## Do docker compose down
	docker compose -f ./webapp/docker-compose.yml down --volumes
	docker compose -f ./benchmarker/docker-compose.yml down --volumes

logs: ## Tail docker compose logs
	docker compose -f ./webapp/docker-compose.yml logs -f

ps: ## Check container status
	docker compose -f ./webapp/docker-compose.yml ps

exec:
	docker compose -f ./webapp/docker-compose.yml exec app /bin/bash

run-benchmarker: ## Run benchmarker
	docker compose -f ./benchmarker/docker-compose.yml up

help: ## Show options
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'


