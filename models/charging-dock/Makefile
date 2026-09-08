# Dual wedge charging dock. Shared build rules live in ../../mk/model.mk.
#
#   make            STLs, 3MFs, the per-dock sets, then every check
#   make plates     one 3MF per dock: set_petg.3mf + set_tpu.3mf
#   make shots      showcase render per style into docs/
#   make check      just the verification (needs the STLs)
#   make fit-test   the 10-minute fit coupons (PETG + TPU)
#   make all-styles build and check every style in turn
#
# Styles are a lookup table in src/params.scad; adding one is a single line.
# The parts below are exported for the DEFAULT style. To build another:
#   make STYLE=faceted

REPO    := ../..
SCAD    := src/main.scad
SOURCES := $(wildcard src/*.scad) $(wildcard $(REPO)/lib/scad/*.scad)

STYLE   ?= soft_monolith
STYLES   = soft_monolith floating_deck faceted furniture

PARTS   := base top_plate top_insert_flat dowel_pins fit_test fit_test_mat

PLATES     := set_petg set_tpu
PLATE_SCAD := src/main.scad
# This model folds its plates into the `part` dispatch rather than a plates.scad.
PLATE_VAR  := part

DIMS_PART := dimensions

FIT_SCAD  := tools/fitcheck.scad
FIT_CASES := chassis:base vs top plate,insert:TPU insert vs its recess

include $(REPO)/mk/model.mk

# Every OpenSCAD invocation carries the style. Appended after the include so it
# rides on the SCADFLAGS the shared rules already set.
SCADFLAGS += -D 'style="$(STYLE)"'

.PHONY: fit-test shots all-styles
fit-test: $(OUT)/fit_test.stl $(OUT)/fit_test_mat.stl

SHOT_SIZE   = 1600,1200
SHOT_CAMERA = 0,52,10,68,0,30,400
shots:
	@mkdir -p docs
	@for s in $(STYLES); do \
	  echo "  docs/$$s.png"; \
	  $(SCADRUN) -D "style=\"$$s\"" -D 'part="showcase"' \
	    --imgsize=$(SHOT_SIZE) --camera=$(SHOT_CAMERA) --colorscheme=Tomorrow \
	    -o docs/$$s.png $(SCAD) >/dev/null; \
	done

# The asserts in params.scad run per style, so building every style IS a check
# that no style violates a design rule.
all-styles:
	@for s in $(STYLES); do \
	  echo "== $$s"; \
	  $(MAKE) --no-print-directory STYLE=$$s OUT=build/$$s stl check || exit 1; \
	done
