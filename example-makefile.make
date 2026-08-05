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

# --- native binaries ---------------------------------------------------------
# Godot cross-exports every desktop platform from linux with the official
# export templates, so unlike ebitengine ALL targets build in CI. Mac is a
# single universal (intel + arm) build: the official templates only ship a
# universal binary, per-arch export would need custom-built templates.
# Zip layout follows the ReleaseAsset convention: a single root folder,
# <project>-<version>-<target>/, zipped as <project>-<version>-<target>.zip.
BINARY_TARGETS = win-x86 win-x64 linux-x64 mac-universal

binaries: build
	@if [ -z "$(VERSION)" ]; then \
		echo "ERROR: VERSION not set!"; exit 1; \
	fi
	@for target in $(BINARY_TARGETS); do \
		$(MAKE) binary-$$target VERSION=$(VERSION) || exit 1; \
	done

binary-win-x86:
	@$(MAKE) binary-build VERSION=$(VERSION) B_PRESET="Windows x86" B_EXT=.exe B_TARGET=win-x86

binary-win-x64:
	@$(MAKE) binary-build VERSION=$(VERSION) B_PRESET="Windows x64" B_EXT=.exe B_TARGET=win-x64

binary-linux-x64:
	@$(MAKE) binary-build VERSION=$(VERSION) B_PRESET="Linux x64" B_EXT= B_TARGET=linux-x64

binary-mac-universal:
	@$(MAKE) binary-build-mac VERSION=$(VERSION) B_PRESET="Mac universal" B_TARGET=mac-universal

# belső helper: egy win/linux target exportja + zip egyetlen gyökérmappával
# (embed_pck miatt az export egyetlen futtatható fájl)
binary-build:
	@set -e; \
	PKG_DIR="$(PROJECT)-$(VERSION)-$(B_TARGET)"; \
	echo "==> Building $$PKG_DIR"; \
	rm -rf "$$PKG_DIR" "$$PKG_DIR.zip"; \
	mkdir -p "$$PKG_DIR"; \
	$(GODOT) --headless --export-release "$(B_PRESET)" "$$(pwd)/$$PKG_DIR/$(PROJECT)$(B_EXT)"; \
	if [ -f LICENSE ]; then cp LICENSE "$$PKG_DIR/"; fi; \
	if [ -f README.md ]; then cp README.md "$$PKG_DIR/"; fi; \
	zip -r "$$PKG_DIR.zip" "$$PKG_DIR" >/dev/null; \
	rm -rf "$$PKG_DIR"; \
	echo "==> $$PKG_DIR.zip kesz"

# mac helper: a Godot linuxról csak .zip-be tud macOS-t exportálni (benne a
# .app), ezt csomagoljuk át a gyökérmappás konvencióra (zip -ry: exec bitek
# és symlinkek megmaradnak)
binary-build-mac:
	@set -e; \
	PKG_DIR="$(PROJECT)-$(VERSION)-$(B_TARGET)"; \
	echo "==> Building $$PKG_DIR"; \
	rm -rf "$$PKG_DIR" "$$PKG_DIR.zip"; \
	mkdir -p "$$PKG_DIR"; \
	$(GODOT) --headless --export-release "$(B_PRESET)" "$$(pwd)/$$PKG_DIR/$(PROJECT)-mac-tmp.zip"; \
	cd "$$PKG_DIR" && unzip -q "$(PROJECT)-mac-tmp.zip" && rm "$(PROJECT)-mac-tmp.zip"; cd ..; \
	if [ -f LICENSE ]; then cp LICENSE "$$PKG_DIR/"; fi; \
	if [ -f README.md ]; then cp README.md "$$PKG_DIR/"; fi; \
	zip -ry "$$PKG_DIR.zip" "$$PKG_DIR" >/dev/null; \
	rm -rf "$$PKG_DIR"; \
	echo "==> $$PKG_DIR.zip kesz"

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

ci-binaries:
	@VERSION=$$(cat $(VERSION_FILE)); \
	$(MAKE) binaries VERSION=$$VERSION

ci-upload:
	@VERSION=$$(cat $(VERSION_FILE)); \
	FILE="$(PROJECT)-$$VERSION.html.zip"; \
	META_SRC="metadata.json"; \
	META_DST="$(PROJECT)-$$VERSION.metadata.json"; \
	BINS=$$(ls $(PROJECT)-$$VERSION-*.zip 2>/dev/null || true); \
	cp $$META_SRC $$META_DST; \
	for f in $$FILE $$META_DST $$BINS; do \
		curl -fsS -H "X-Update-Secret: $(UPDATE_SECRET)" \
			-F "file=@$$f" \
			"$(UPDATE_SERVER)/build/upload?name=$(PROJECT)&version=$$VERSION" || exit 1; \
	done

ci-publish:
	@VERSION=$$(cat $(VERSION_FILE)); \
	curl -fsS -X POST -H "X-Update-Secret: $(UPDATE_SECRET)" "$(UPDATE_SERVER)/build/publish?name=$(PROJECT)&platform=godot&version=$$VERSION"

.PHONY: all build run web export watch clean binaries binary-win-x86 binary-win-x64 binary-linux-x64 binary-mac-universal binary-build binary-build-mac ci-version ci-export ci-binaries ci-upload ci-publish
