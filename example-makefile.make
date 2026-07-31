# -----------------------------------------
# Makefile – Godot project builder
# -----------------------------------------

PROJECT = godotdemo

GODOT         ?= godot
EXPORT_PRESET  = Web

DIST_DIR   = dist
WEB_DIR    = $(DIST_DIR)/web
OUTPUT_ZIP = $(PROJECT)-$(VERSION).html.zip

VERSION_FILE = .version

all: build

build:
	$(GODOT) --headless --import

run:
	$(GODOT) --path .

web: build
	@mkdir -p $(WEB_DIR)
	@echo "==> Exporting web build ($(EXPORT_PRESET) preset)"
	$(GODOT) --headless --export-release "$(EXPORT_PRESET)" $(WEB_DIR)/index.html

export: web
	@if [ -z "$(VERSION)" ]; then \
		echo "ERROR: VERSION not set!"; exit 1; \
	fi
	@echo "==> Packaging web build for $(VERSION)"
	cd $(WEB_DIR) && zip -r ../../$(OUTPUT_ZIP) .
	@echo "==> Cleaning temporary files"
	rm -rf $(WEB_DIR)

watch:
	fswatch -o . --include="\.gd$$" --include="\.tscn$$" | while read; do make build; done

clean:
	rm -rf $(DIST_DIR) .godot

ci-version:
	@if [ -f metadata.json ]; then \
		VERSION=$$(jq -r '.version' metadata.json); \
	else \
		VERSION=$$(git rev-parse --short HEAD); \
	fi; \
	BRANCH=$$(git rev-parse --abbrev-ref HEAD); \
	if [ "$$BRANCH" != "main" ] && [ "$$BRANCH" != "master" ]; then \
		VERSION="dev-$$VERSION-$$BRANCH"; \
	fi; \
	echo $$VERSION > $(VERSION_FILE)

ci-export:
	@VERSION=$$(cat $(VERSION_FILE)); \
	$(MAKE) export VERSION=$$VERSION

ci-upload:
	@VERSION=$$(cat $(VERSION_FILE)); \
	FILE="$(PROJECT)-$$VERSION.html.zip"; \
	META_SRC="metadata.json"; \
	META_DST="$(PROJECT)-$$VERSION.metadata.json"; \
	cp $$META_SRC $$META_DST; \
	sshpass -p "$(DROPAREA_SSH_PASSWORD)" scp -o StrictHostKeyChecking=no -P $(DROPAREA_PORT) \
		$$FILE $$META_DST \
		$(DROPAREA_USER)@$(DROPAREA_HOST):$(DROPAREA_TARGET_PATH)/

ci-update:
	@VERSION=$$(cat $(VERSION_FILE)); \
	curl "$(UPDATE_SERVER)/update?secret=$(UPDATE_SECRET)&name=$(PROJECT)&platform=godot&version=$$VERSION"

.PHONY: all build run web export watch clean ci-version ci-export ci-upload ci-update
