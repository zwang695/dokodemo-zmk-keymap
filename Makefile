KEYMAP_DRAWER := keymap
PYTHON ?= python3
KEYMAP_CONFIG := keymap-drawer/config.yaml
KEYMAP_FORMATTER := keymap-drawer/format.py
KEYMAP_SOURCE := config/dokodemo.keymap
KEYMAP_YAML := keymap-drawer/keymap.yaml
KEYMAP_SVG := keymap-drawer/keymap.svg
KEYMAP_COMPACT_SVG := keymap-drawer/keymap-compact.svg
KEYMAP_COMPACT_PNG := keymap-drawer/keymap-compact.png
KEYMAP_COMPACT_PNG_WIDTH ?= 3840
KEYMAP_LAYERS := QWERTY Colemak-DH Cursor Symbol Num Magic
KEYMAP_PRINT_DIR := keymap-drawer/print
KEYMAP_PRINT_PDF := keymap-drawer/keymap-print.pdf
CHROMIUM ?= chromium
RSVG_CONVERT ?= rsvg-convert

.PHONY: keymap keymap-svg keymap-compact keymap-compact-svg keymap-compact-png keymap-print check-keymap-print-deps

keymap:
	$(KEYMAP_DRAWER) -c $(KEYMAP_CONFIG) parse -z $(KEYMAP_SOURCE) \
		-l $(KEYMAP_LAYERS) -o $(KEYMAP_YAML)
	$(PYTHON) $(KEYMAP_FORMATTER) $(KEYMAP_YAML)
	$(MAKE) keymap-svg keymap-compact-svg

keymap-svg:
	$(KEYMAP_DRAWER) -c $(KEYMAP_CONFIG) draw \
		-j config/dokodemo.json -l dokodemo \
		-o $(KEYMAP_SVG) $(KEYMAP_YAML)
	$(PYTHON) $(KEYMAP_FORMATTER) $(KEYMAP_SVG)

keymap-compact:
	$(KEYMAP_DRAWER) -c $(KEYMAP_CONFIG) parse -z $(KEYMAP_SOURCE) \
		-l $(KEYMAP_LAYERS) -o $(KEYMAP_YAML)
	$(PYTHON) $(KEYMAP_FORMATTER) $(KEYMAP_YAML)
	$(MAKE) keymap-compact-svg

keymap-compact-svg:
	$(KEYMAP_DRAWER) -c $(KEYMAP_CONFIG) draw \
		-j config/dokodemo.json -l dokodemo \
		-s QWERTY Cursor Symbol Num Magic \
		-o $(KEYMAP_COMPACT_SVG) $(KEYMAP_YAML)
	$(PYTHON) $(KEYMAP_FORMATTER) $(KEYMAP_COMPACT_SVG)

keymap-compact-png: keymap-compact-svg
	@command -v $(RSVG_CONVERT) >/dev/null || { echo "Missing rsvg-convert: install librsvg or set RSVG_CONVERT=/path/to/rsvg-convert."; exit 1; }
	$(RSVG_CONVERT) -w $(KEYMAP_COMPACT_PNG_WIDTH) -o $(KEYMAP_COMPACT_PNG) $(KEYMAP_COMPACT_SVG)

check-keymap-print-deps:
	@command -v $(KEYMAP_DRAWER) >/dev/null || { echo "Missing keymap-drawer: install the global 'keymap' executable."; exit 1; }
	@command -v $(PYTHON) >/dev/null || { echo "Missing Python executable: $(PYTHON)."; exit 1; }
	@$(PYTHON) -c 'import yaml' 2>/dev/null || { echo "Missing PyYAML: install the Python 'yaml' package."; exit 1; }
	@command -v "$(CHROMIUM)" >/dev/null || { echo "Missing Chromium: install 'chromium' or set CHROMIUM=/path/to/browser."; exit 1; }

keymap-print: check-keymap-print-deps keymap
	mkdir -p $(KEYMAP_PRINT_DIR)
	$(KEYMAP_DRAWER) -c $(KEYMAP_CONFIG) draw -j config/dokodemo.json -l dokodemo \
		-s QWERTY Colemak-DH -o $(KEYMAP_PRINT_DIR)/page-1.svg $(KEYMAP_YAML)
	$(KEYMAP_DRAWER) -c $(KEYMAP_CONFIG) draw -j config/dokodemo.json -l dokodemo \
		-s Cursor Symbol -o $(KEYMAP_PRINT_DIR)/page-2.svg $(KEYMAP_YAML)
	$(KEYMAP_DRAWER) -c $(KEYMAP_CONFIG) draw -j config/dokodemo.json -l dokodemo \
		-s Num Magic -o $(KEYMAP_PRINT_DIR)/page-3.svg $(KEYMAP_YAML)
	$(PYTHON) $(KEYMAP_FORMATTER) $(KEYMAP_PRINT_DIR)/page-1.svg
	$(PYTHON) $(KEYMAP_FORMATTER) $(KEYMAP_PRINT_DIR)/page-2.svg
	$(PYTHON) $(KEYMAP_FORMATTER) $(KEYMAP_PRINT_DIR)/page-3.svg
	"$(CHROMIUM)" --headless --no-sandbox --disable-gpu --disable-dev-shm-usage \
		--disable-crash-reporter --disable-breakpad \
		--allow-file-access-from-files --no-pdf-header-footer \
		--user-data-dir=$$(mktemp -d /tmp/dokodemo-keymap-print-chromium.XXXXXX) \
		--print-to-pdf=$(abspath $(KEYMAP_PRINT_PDF)) \
		file://$(abspath keymap-drawer/print.html)
	@echo "Created $(KEYMAP_PRINT_PDF)"
