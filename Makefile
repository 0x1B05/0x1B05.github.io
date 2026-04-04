# Find all page .typ files in content/ while excluding metadata-only files.
SITE_DIR := _site
SITE_ASSET_DIR := $(SITE_DIR)/assets
PAGEFIND_BIN := ./node_modules/.bin/pagefind
PAGEFIND_FLAGS := --site $(SITE_DIR) --output-subdir pagefind --force-language en
TYPST_HTML_FLAGS := --root .. --features html --format html
TYP_FILES := $(shell find content -name '*.typ' -not -name 'series.typ' -not -name 'registry.typ' -not -path '*/_*' | LC_ALL=C sort)
PORT ?= 8000

# Generate corresponding HTML file paths in the output directory
HTML_FILES := $(patsubst content/%.typ,$(SITE_DIR)/%.html,$(TYP_FILES))
CONTENT_SHARED_TYPS := $(shell find content -name '_*.typ' -print | LC_ALL=C sort)
CONTENT_THUMBNAIL_FILES := $(shell find assets/content-thumbnails -type f 2>/dev/null | LC_ALL=C sort)
GLOBAL_EMBEDDED_ASSET_FILES := $(wildcard assets/logo-light.svg assets/logo-dark.svg)
ASSET_FILES := $(shell find assets -type f | LC_ALL=C sort)

define page-shared-typs
config.typ $(CONTENT_SHARED_TYPS) $(shell page_dir="$$(dirname content/$(1).typ)"; while [ "$$page_dir" != "content" ] && [ "$$page_dir" != "." ]; do page_dir="$$(dirname "$$page_dir")"; index="$$page_dir/index.typ"; series_typ="$$page_dir/series.typ"; if [ -f "$$index" ]; then printf '%s ' "$$index"; fi; if [ -f "$$series_typ" ]; then printf '%s ' "$$series_typ"; fi; done)
endef

define page-support-files
$(if $(filter index,$(1)),,$(shell page_dir="$(dir content/$(1).typ)"; find "$$page_dir" -mindepth 1 -maxdepth 1 -type f ! -name '*.typ' 2>/dev/null; find "$$page_dir/imgs" -mindepth 1 -maxdepth 1 -type f 2>/dev/null))
endef

define page-embedded-assets
$(GLOBAL_EMBEDDED_ASSET_FILES) $(if $(filter index,$(1)),assets/profile.png) $(if $(filter blog/index docs/index,$(1)),$(CONTENT_THUMBNAIL_FILES))
endef

# The main target 'html' builds pages, copies assets, and indexes the site for search.
html: $(HTML_FILES) assets search-index

# Explicit target for GitHub Pages style deployments
pages:
	@$(MAKE) clean
	@$(MAKE) html
	@touch $(SITE_DIR)/.nojekyll
	@printf '%s\n' "$(SITE_DIR)"

github-pages: pages

preview:
	@$(MAKE) html
	@python3 -m http.server -d $(SITE_DIR) $(PORT)

# Rebuild pages when their shared Typst dependencies, page-local support files, or embedded assets change.
.SECONDEXPANSION:
$(SITE_DIR)/%.html: content/%.typ $$(call page-shared-typs,$$*) $$(call page-support-files,$$*) $$(call page-embedded-assets,$$*)
	@mkdir -p $(@D)
	typst compile $(TYPST_HTML_FLAGS) $< $@

assets: $(ASSET_FILES)
	@mkdir -p $(SITE_ASSET_DIR)
	@cp -r assets/* $(SITE_ASSET_DIR)/

search-index: $(HTML_FILES) assets package-lock.json
	@test -x $(PAGEFIND_BIN) || (printf '%s\n' "Missing $(PAGEFIND_BIN). Run npm install to set up Pagefind." >&2; exit 1)
	@$(PAGEFIND_BIN) $(PAGEFIND_FLAGS)

# A clean rule to remove generated files
clean:
	rm -rf $(SITE_DIR)

.PHONY: html clean assets pages github-pages preview search-index
