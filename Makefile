.PHONY: build clean build-all release-assets macos-pkg appstore-pkg test frontend-embed docker-publish

BINARY_NAME=marumesh
SERVER_NAME=marumesh-server
BUILD_DIR=bin
DIST_DIR=dist
FRONTEND_EMBED_DIR=src/cmd/marumesh-server/web/dist
SKIP_FRONTEND_BUILD?=false
HOST_OS?=$(shell go env GOOS)
HOST_ARCH?=$(shell go env GOARCH)
HOST_EXT=$(if $(filter windows,$(HOST_OS)),.exe,)
HOST_PLATFORM=$(HOST_OS)-$(HOST_ARCH)

VERSION=0.11.87
DOCKER_IMAGE?=dirmich/marumesh
LDFLAGS=-ldflags "-X main.Version=$(VERSION)"

frontend-embed:
	@if [ "$(SKIP_FRONTEND_BUILD)" = "true" ]; then \
		echo "Skipping frontend embed refresh"; \
	else \
		cd frontend && npm run build; \
		rm -rf ../$(FRONTEND_EMBED_DIR); \
		mkdir -p ../$(FRONTEND_EMBED_DIR); \
		cp -R dist/. ../$(FRONTEND_EMBED_DIR)/; \
	fi

build: frontend-embed
	mkdir -p $(BUILD_DIR)/$(HOST_PLATFORM)
	GOOS=$(HOST_OS) GOARCH=$(HOST_ARCH) go build $(LDFLAGS) -o $(BUILD_DIR)/$(HOST_PLATFORM)/$(BINARY_NAME)$(HOST_EXT) ./src/cmd/marumesh
	GOOS=$(HOST_OS) GOARCH=$(HOST_ARCH) go build $(LDFLAGS) -o $(BUILD_DIR)/$(HOST_PLATFORM)/$(SERVER_NAME)$(HOST_EXT) ./src/cmd/marumesh-server

test: frontend-embed
	go test ./...

clean:
	rm -rf $(BUILD_DIR)

build-all: clean frontend-embed
	# Linux
	mkdir -p $(BUILD_DIR)/linux-amd64 $(BUILD_DIR)/linux-arm64 $(BUILD_DIR)/windows-amd64
	GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o $(BUILD_DIR)/linux-amd64/$(BINARY_NAME) ./src/cmd/marumesh
	GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o $(BUILD_DIR)/linux-amd64/$(SERVER_NAME) ./src/cmd/marumesh-server
	GOOS=linux GOARCH=arm64 go build $(LDFLAGS) -o $(BUILD_DIR)/linux-arm64/$(BINARY_NAME) ./src/cmd/marumesh
	GOOS=linux GOARCH=arm64 go build $(LDFLAGS) -o $(BUILD_DIR)/linux-arm64/$(SERVER_NAME) ./src/cmd/marumesh-server
	# Windows
	GOOS=windows GOARCH=amd64 go build $(LDFLAGS) -o $(BUILD_DIR)/windows-amd64/$(BINARY_NAME).exe ./src/cmd/marumesh
	GOOS=windows GOARCH=amd64 go build $(LDFLAGS) -o $(BUILD_DIR)/windows-amd64/$(SERVER_NAME).exe ./src/cmd/marumesh-server
	# macOS systray requires a native build for the target arch.
	@if [ "$(HOST_OS)" = "darwin" ]; then \
		$(MAKE) build HOST_OS=darwin HOST_ARCH=$(HOST_ARCH); \
	else \
		echo "Skipping macOS build on $(HOST_OS); run make build on macOS to create bin/darwin-<arch>/ outputs."; \
	fi

release-assets: build-all
	mkdir -p $(DIST_DIR)
	cp $(BUILD_DIR)/linux-amd64/$(BINARY_NAME) $(DIST_DIR)/$(BINARY_NAME)-linux-amd64
	cp $(BUILD_DIR)/linux-arm64/$(BINARY_NAME) $(DIST_DIR)/$(BINARY_NAME)-linux-arm64
	cp $(BUILD_DIR)/windows-amd64/$(BINARY_NAME).exe $(DIST_DIR)/$(BINARY_NAME)-windows-amd64.exe
	@if [ -f "$(BUILD_DIR)/darwin-amd64/$(BINARY_NAME)" ]; then \
		cp $(BUILD_DIR)/darwin-amd64/$(BINARY_NAME) $(DIST_DIR)/$(BINARY_NAME)-darwin-amd64; \
	fi
	@if [ -f "$(BUILD_DIR)/darwin-arm64/$(BINARY_NAME)" ]; then \
		cp $(BUILD_DIR)/darwin-arm64/$(BINARY_NAME) $(DIST_DIR)/$(BINARY_NAME)-darwin-arm64; \
	fi

appstore-pkg:
	bash scripts/build_macos_appstore_pkg.sh

macos-pkg:
	bash scripts/build_macos_developer_id_pkg.sh

# Requires an authenticated buildx builder. Produces one manifest containing
# native amd64 and arm64 server images.
docker-publish:
	VERSION=$(VERSION) DOCKER_IMAGE=$(DOCKER_IMAGE) scripts/docker_publish.sh
