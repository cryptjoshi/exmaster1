# Makefile for Batch Application

.PHONY: help dev prod build clean install-deps

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

dev: ## Start development environment with live reload
	docker-compose -f docker-compose.dev.yml up --build

prod: ## Start production environment
	docker-compose up --build -d

build: ## Build production images
	docker-compose build

clean: ## Clean up containers and images
	docker-compose -f docker-compose.dev.yml down --volumes --remove-orphans
	docker-compose down --volumes --remove-orphans
	docker system prune -f

install-deps: ## Install dependencies locally
	go mod download
	cd static && pnpm install

# Local development without Docker
dev-local-win: ## Run development servers locally on Windows (requires Go and Node.js)
	@echo "Use dev-local-win.bat script instead"
	@echo "Run: ./dev-local-win.bat"

dev-local: ## Run development servers locally (requires Go and Node.js)
	@echo "Starting Next.js frontend on port 3001..."
	cd static && pnpm run dev &
	@echo "Starting Golang backend with Air on port 8088..."
	air -c .air.toml

# Build frontend for production
build-frontend: ## Build Next.js frontend for production
	cd static && pnpm run build

# Run Go application locally
run-go: ## Run Go application locally
	go run main.go

# Test Go application
test: ## Run Go tests
	go test -v ./...

# Format Go code
fmt: ## Format Go code
	go fmt ./...

# Run Go linter
lint: ## Run Go linter
	golangci-lint run
