# Install required tools
.PHONY: install-tools
install-tools:
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	go install connectrpc.com/connect/cmd/protoc-gen-connect-go@latest
	go install github.com/bufbuild/buf/cmd/buf@latest
	go install github.com/air-verse/air@latest

# Generate protobuf code
.PHONY: proto
proto:
	buf generate

# Generate code (alias for proto)
.PHONY: gen
gen: proto

# Docker 用コマンド
.PHONY: docker/init-development
docker/init-development:
	- docker network create fox-network

.PHONY: docker/build-development
docker/build-development:
	DOCKER_BUILDKIT=1 docker buildx build \
		--target development \
		--load \
		-t fox-api \
		--cache-from type=local,src=.buildx-cache \
		--cache-to type=local,dest=.buildx-cache,mode=max \
		.

.PHONY: docker/up-development
docker/up-development:
	docker compose up -d

.PHONY: docker/stop-development
docker/stop-development:
	docker compose stop

.PHONY: docker/clean-development
docker/clean-development:
	docker compose down --volumes --remove-orphans

.PHONY: docker/login-development
docker/login-development:
	docker exec -it `make __docker_login_container_id` /bin/bash

.PHONY: __docker_login_container_id
__docker_login_container_id:
	docker ps $(shell [ "$(all)" == "true" ] && echo "-a" || true) | grep fox-api | awk '{ print $$1 }'

.PHONY: docker/lint-development
docker/lint-development:
	docker compose exec api make lint

# go 用コマンド
.PHONY: test
test:
	BASE_DIR=$$(pwd) APP_ENV=test TZ=UTC go test ./... -tags test

.PHONY: test-with-coverage
test-with-coverage:
	BASE_DIR=$$(pwd) APP_ENV=test TZ=UTC go test ./... -tags test -covermode=count -coverprofile=cover.out

# make create-migration name=your_migration_name
.PHONY: create-migration
create-migration:
	@if [ -z "$(name)" ]; then \
		echo "Usage: make create-migration name=your_migration_name"; \
		exit 1; \
	fi
	goose -dir migrations create $(name) sql

.PHONY: migrate-up
migrate-up:
	go run cmd/migrate/main.go -direction up

.PHONY: migrate-down
migrate-down:
	go run cmd/migrate/main.go -direction down

.PHONY: migrate-down-one
migrate-down-one:
	go run cmd/migrate/main.go -direction down-one

.PHONY: migrate-reset
migrate-reset:
	go run cmd/migrate/main.go -direction down
	go run cmd/migrate/main.go -direction up

# テストDB用マイグレーション
.PHONY: migrate-test-up
migrate-test-up:
	APP_ENV=test go run cmd/migrate/main.go -direction up

.PHONY: migrate-test-down
migrate-test-down:
	APP_ENV=test go run cmd/migrate/main.go -direction down

.PHONY: migrate-test-down-one
migrate-test-down-one:
	APP_ENV=test go run cmd/migrate/main.go -direction down-one

.PHONY: migrate-test-reset
migrate-test-reset:
	APP_ENV=test go run cmd/migrate/main.go -direction down
	APP_ENV=test go run cmd/migrate/main.go -direction up

# マイグレーション検証
.PHONY: validate-migrations
validate-migrations:
	APP_ENV=test ./scripts/validate_migrations.sh

.PHONY: seed
seed:
	BASE_DIR=$$(pwd) go run cmd/seed/*.go

.PHONY: lint
lint:
	golangci-lint run

.PHONY: lint-fix
lint-fix:
	golangci-lint run --fix

.PHONY: mockgen
mockgen:
	@echo ">>> Generating mocks with go generate..."
	@go generate ./...

	@echo ">>> Adding build tags to generated mocks (skip if already present)..."
	@find . -name "mock_*.go" | while read file; do \
		if ! grep -q "//go:build test" $$file; then \
			tmpfile=$$file.tmp; \
			echo "//go:build test" > $$tmpfile; \
			echo "" >> $$tmpfile; \
			cat $$file >> $$tmpfile; \
			mv $$tmpfile $$file; \
			echo "  -> Added build tags to $$file"; \
		else \
			echo "  -> Skipped $$file (already has build tags)"; \
		fi \
	done

.PHONY: enumgen
enumgen:
	go generate ./enums

# SQL lint 用コマンド (sqlfluff)
.PHONY: sql-lint
sql-lint:
	sqlfluff lint migrations/

.PHONY: sql-lint-fix
sql-lint-fix:
	sqlfluff fix migrations/

.PHONY: docker/sql-lint
docker/sql-lint:
	docker compose exec api make sql-lint
