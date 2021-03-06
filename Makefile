
SHELL := /bin/bash
VERSION = $(shell git describe --tags --always --dirty --abbrev=12)
BUILDDATE = $(shell date +%s)
EXECUTABLE = greeter
PKG = github.com/thingful/${EXECUTABLE}
BUILDFLAGS = -a -installsuffix cgo -ldflags "-X ${PKG}/pkg/version.Version=${VERSION} -X ${PKG}/pkg/version.BuildDate=${BUILDDATE}"
BUILD_DIR = build

.PHONY: help
help: ## Show this help message
	@echo 'usage: make [target] ...'
	@echo
	@echo 'targets:'
	@echo
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s : | sed -e 's/^/  /')"

.PHONY: protoc
protoc: ## Compile proto definitions to generate client/server code
	protoc --proto_path=pkg/${EXECUTABLE}/ ./pkg/${EXECUTABLE}/*.proto --go_out=plugins=grpc:pkg/${EXECUTABLE}

.PHONY: build-internal
build-internal: ## Build our Go executable. Note this is designed to be run inside the container
	mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 GOOS=linux go build ${BUILDFLAGS} -o ${BUILD_DIR}/${EXECUTABLE} ${PKG}/pkg/server

.PHONY: build
build: ## Package our app inside a container using docker-compose
	docker-compose build

.PHONY: tag
tag: build ## Push the latest container build to docker hub
	docker tag thingful/greeter:latest thingful/greeter:${VERSION}

.PHONY: push
push: tag
	docker push thingful/greeter
