BINARY := gphotos-uploader-cli
.DEFAULT_GOAL := help

# This VERSION could be set calling `make VERSION=0.2.0`
VERSION ?= $(shell git describe --tags --abbrev=0)

# This BUILD is automatically calculated and used inside the command
BUILD := $(shell git rev-parse --short HEAD)

# Use linker flags to provide version/build settings to the target
VERSION_IMPORT_PATH := github.com/nmrshll/gphotos-uploader-cli/cmd
LDFLAGS=-ldflags "-X=${VERSION_IMPORT_PATH}.Version=$(VERSION) -X=${VERSION_IMPORT_PATH}.Build=$(BUILD)"

# go source files, ignore vendor directory
PKGS = $(shell go list ./... | grep -v /vendor)
SRC := main.go
COVERAGE_FILE := coverage.txt

# Get first path on multiple GOPATH environments
GOPATH := $(shell echo ${GOPATH} | cut -d: -f1)

.PHONY: test
test: ## Run all the tests
	@echo "--> Running tests..."
	@go test -covermode=atomic -coverprofile=$(COVERAGE_FILE) -v -race -failfast -timeout=30s $(PKGS)

.PHONY: cover
cover: test ## Run all the tests and opens the coverage report
	@echo "--> Openning coverage report..."
	@go tool cover -html=$(COVERAGE_FILE)

build: ## Build the app
	@echo "--> Building binary artifact ($(BINARY) $(VERSION) (build: $(BUILD)))..."
	@go build ${LDFLAGS} -o $(BINARY) $(SRC)

.PHONY: clean
clean: ## Clean all built artifacts
	@echo "--> Cleaning all built artifacts..."
	@rm -f $(BINARY) $(COVERAGE_FILE)
	@rm -rf dist

BIN_DIR := $(GOPATH)/bin

GOLANGCI := $(BIN_DIR)/golangci-lint
GOLANGCI_VERSION := 1.12.3

$(GOLANGCI):
	@echo "--> Installing golangci v$(GOLANGCI_VERSION)..."
	@curl -sfL https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | sh -s -- -b $(BIN_DIR) v$(GOLANGCI_VERSION)

.PHONY: lint
lint: $(GOLANGCI) ## Run linter
	@echo "--> Running linter golangci v$(GOLANGCI_VERSION)..."
	@$(GOLANGCI) run

.PHONY: ci
ci: build test lint ## Run all the tests and code checks

GORELEASER := $(BIN_DIR)/goreleaser

$(GORELEASER):
	@echo "--> Installing goreleaser..."
	@curl -sL https://git.io/goreleaser | bash

.PHONY: release
release: $(GORELEASER) ## Release a new version using goreleaser (only CI)
	@echo "--> Releasing $(BINARY) $(VERSION) (build: $(BUILD))..."
	@$(GORELEASER) run

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: version
version: ## Show current version
	@echo "$(VERSION) (build: $(BUILD))"
