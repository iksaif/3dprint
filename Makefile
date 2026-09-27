# The whole repo in one place. The real rules live in mk/model.mk and each
# model's own Makefile; this only recurses, so `make` at the top does what CI
# does, and `make check` verifies everything without remembering three paths.
#
#   make                 build and check every model
#   make check           just the checks, every model
#   make charging-dock   one model, by name
#   make list            what is here
#
# Variables pass straight through, so this works as expected:
#   make OPENSCAD=/usr/bin/openscad
#
# Per-model options that are not repo-wide — STYLE, OUT — belong to the model:
#   make -C models/charging-dock STYLE=atelier

# A model is a directory with a Makefile. Globbing models/*/ would be the
# obvious way, but make 3.81 -- what macOS ships -- ignores the trailing slash
# and hands back models/LICENSE.md as well.
MODELS := $(notdir $(patsubst %/,%,$(dir $(wildcard models/*/Makefile))))

.PHONY: all list $(MODELS) stl 3mf plates check clean

all: $(MODELS)

# One model by name: `make post-hook`.
$(MODELS):
	@echo "== $@"
	@$(MAKE) --no-print-directory -C models/$@

# The shared targets, each fanned out over every model. A failure stops the
# run: a green summary that skipped a broken model would be worse than useless.
stl 3mf plates check clean:
	@for m in $(MODELS); do \
	  echo "== $$m"; \
	  $(MAKE) --no-print-directory -C models/$$m $@ || exit 1; \
	done

list:
	@echo "models:  $(MODELS)"
	@echo "targets: all (default), stl, 3mf, plates, check, clean"
	@echo "one model: make <name>, or make -C models/<name> <target>"
