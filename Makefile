SHELL := /bin/sh

APP_NAME ?= sublinkPro
WEB_DIR ?= webs
STATIC_DIR ?= static
FRONTEND_DIST ?= $(WEB_DIR)/dist

COREPACK ?= corepack
YARN ?= yarn
YARN_INSTALL_FLAGS ?= --immutable

GO ?= go
GOLANGCI_LINT ?= golangci-lint
CGO_ENABLED ?= 0
PROD_TAGS ?= prod
PROD_LDFLAGS ?= -s -w

.DEFAULT_GOAL := help

.PHONY: help
help:
	@printf 'SublinkPro build targets:\n'
	@printf '  make frontend-install  Enable Corepack and install Yarn dependencies\n'
	@printf '  make frontend-lint     Run frontend ESLint checks\n'
	@printf '  make frontend-build    Build Vite frontend into webs/dist\n'
	@printf '  make frontend-check    Run frontend lint and build\n'
	@printf '  make frontend-dev      Start the Vite dev server\n'
	@printf '  make frontend-preview  Preview the built Vite frontend\n'
	@printf '  make static            Copy webs/dist into static for Go prod embed\n'
	@printf '  make backend-build     Build the local development Go binary\n'
	@printf '  make backend-check     Run backend lint and tests\n'
	@printf '  make prod-build        Build production binary with embedded frontend\n'
	@printf '  make build             Alias for prod-build\n'
	@printf '  make check             Run frontend and backend checks\n'
	@printf '  make ci                Run checks and production build\n'
	@printf '  make clean             Remove generated frontend/static/binary outputs\n'

.PHONY: corepack
corepack:
	$(COREPACK) enable

.PHONY: frontend-install
frontend-install: corepack
	cd $(WEB_DIR) && $(YARN) install $(YARN_INSTALL_FLAGS)

.PHONY: frontend-lint
frontend-lint: frontend-install
	cd $(WEB_DIR) && $(YARN) run lint

.PHONY: frontend-build
frontend-build: frontend-install
	cd $(WEB_DIR) && $(YARN) run build

.PHONY: frontend-check
frontend-check: frontend-lint frontend-build

.PHONY: frontend-dev
frontend-dev: corepack
	cd $(WEB_DIR) && $(YARN) run start

.PHONY: frontend-preview
frontend-preview: frontend-build
	cd $(WEB_DIR) && $(YARN) run preview

.PHONY: static
static: frontend-build
	rm -rf $(STATIC_DIR)
	mkdir -p $(STATIC_DIR)
	cp -R $(FRONTEND_DIST)/. $(STATIC_DIR)/

.PHONY: backend-build
backend-build:
	$(GO) build -o $(APP_NAME) main.go

.PHONY: backend-check
backend-check:
	$(GOLANGCI_LINT) run
	$(GO) test ./...

.PHONY: go-prod-build
go-prod-build:
	CGO_ENABLED=$(CGO_ENABLED) $(GO) build -tags=$(PROD_TAGS) -ldflags="$(PROD_LDFLAGS)" -o $(APP_NAME)

.PHONY: prod-build
prod-build: frontend-check static go-prod-build

.PHONY: build
build: prod-build

.PHONY: check
check: frontend-check backend-check

.PHONY: ci
ci: frontend-check backend-check static go-prod-build

.PHONY: clean
clean:
	rm -rf $(FRONTEND_DIST) $(STATIC_DIR) $(APP_NAME)
