# Shared build rules for every model in this repo.
#
# A model's own Makefile sets a few variables and includes this. Minimum:
#
#   REPO   := ../..
#   SCAD   := src/main.scad          # the entry point, taking a `part` variable
#   PARTS  := u_bracket cover pad    # -> build/<part>.{stl,3mf}
#   include $(REPO)/mk/model.mk
#
# Optional:
#   PLATES        := petg tpu        # -> build/plates/<plate>.3mf, from PLATE_SCAD
#   PLATE_SCAD    := src/plates.scad # entry point taking a `plate` variable
#   DIMS_PART     := dims            # a `part` that only echoes numbers
#   FIT_SCAD      := tools/fitcheck.scad
#   FIT_CASES     := a:label a,b     # passed to tools/fitcheck.py --cases
#   EXTRA_CHECKS  := ./tools/strength.py build/x.stl
#   SUPPORT_ARGS  := --reach 8
#   SUPPORT_EXEMPT := ext_light   # parts ALLOWED to need support, see below
#
# Every model gets: make stl / 3mf / plates / check / clean.

OPENSCAD ?= /opt/homebrew/bin/openscad
PYTHON   ?= python3

# --backend=manifold is not optional here. It is orders of magnitude faster than
# CGAL on these models AND it guarantees a manifold result, which is why the
# mesh check below is a cheap sanity net rather than the main event.
SCADFLAGS ?= --hardwarnings --backend=manifold
SCADRUN    = $(OPENSCAD) $(SCADFLAGS)

OUT      ?= build
TOOLS     = $(REPO)/tools

# Prusa MK4S usable footprint. Keep in step with lib/scad/print.scad — a model
# that prints on something else overrides this before the include.
BED      ?= 250,210

STLS      = $(addprefix $(OUT)/,$(addsuffix .stl,$(PARTS)))
MFS       = $(addprefix $(OUT)/,$(addsuffix .3mf,$(PARTS)))
PLATEMFS  = $(addprefix $(OUT)/plates/,$(addsuffix .3mf,$(PLATES)))

SUPPORT_ARGS   ?=
SUPPORT_EXEMPT ?=
EXEMPT_STLS  = $(addprefix $(OUT)/,$(addsuffix .stl,$(SUPPORT_EXEMPT)))
STRICT_STLS  = $(filter-out $(EXEMPT_STLS),$(STLS))

.PHONY: all stl 3mf plates check clean help
.DELETE_ON_ERROR:

all: stl 3mf plates check

stl:    $(STLS)
3mf:    $(MFS)
plates: $(PLATEMFS)

# Static pattern rules, not implicit ones: they apply only to the targets listed,
# so build/plates/*.3mf can never be captured by the generic part rule. Each
# recipe makes its own output directory, because an order-only prerequisite on
# $(OUT) stops firing the moment build/ exists but build/plates/ does not.
$(STLS): $(OUT)/%.stl: $(SOURCES)
	@mkdir -p $(@D)
	$(SCADRUN) --export-format binstl -o $@ -D 'part="$*"' $(SCAD)

$(MFS): $(OUT)/%.3mf: $(SOURCES)
	@mkdir -p $(@D)
	$(SCADRUN) -o $@ -D 'part="$*"' $(SCAD)

# Plates keep their pieces as separate objects so the slicer can still move them.
# Without lazy-union OpenSCAD unions the top-level children on export and the
# pieces arrive fused into one mesh.
# Which OpenSCAD variable selects a plate. Most models keep plates in their own
# file and dispatch on `plate`; a model that folds them into its `part` dispatch
# sets PLATE_VAR := part rather than redefining this rule.
PLATE_VAR ?= plate

$(PLATEMFS): $(OUT)/plates/%.3mf: $(SOURCES)
	@mkdir -p $(@D)
	$(SCADRUN) --enable=lazy-union -o $@ -D '$(PLATE_VAR)="$*"' $(PLATE_SCAD)

# A part that compiles is not a part that fits, and a part that fits is not a
# part that prints. These ask the three questions separately.
check: $(STLS)
	@echo "== bounding boxes"
	@$(PYTHON) $(TOOLS)/bbox.py $(STLS)
	@echo "\n== mesh sanity (watertight, oriented, single shell)"
	@$(PYTHON) $(TOOLS)/mesh.py --bed $(BED) $(STLS)
ifdef FIT_SCAD
	@echo "\n== boolean interference between mating parts"
	@$(PYTHON) $(TOOLS)/fitcheck.py --scad $(FIT_SCAD) --cases "$(FIT_CASES)"
endif
ifdef EXTRA_CHECKS
	@echo "\n== model-specific checks"
	@$(EXTRA_CHECKS)
endif
ifdef DIMS_PART
	@echo "\n== derived dimensions"
	@$(SCADRUN) -o /dev/null --export-format asciistl -D 'part="$(DIMS_PART)"' $(SCAD) 2>&1 \
	  | grep ECHO | sed 's/^ECHO: "/  /;s/"$$//'
endif
# Being correct and being printable are different questions. Every other check
# here asks the first; this is the only one that asks the second, and it is the
# only one that has ever caught an unprintable joint in this repo.
#
# No supports is the RULE, and it fails the build. SUPPORT_EXEMPT is the narrow
# exception: a part that has deliberately traded support-free printing for
# something else — a lighter or slimmer shape that the 45 deg limit will not
# give. Those are still measured and still printed in the report, so the cost is
# visible; they just do not fail. Anything not named there must come back clean.
	@echo "\n== unsupported material (each part in its own print orientation)"
	@$(PYTHON) $(TOOLS)/support.py $(SUPPORT_ARGS) $(STRICT_STLS)
ifneq ($(strip $(SUPPORT_EXEMPT)),)
	@echo "   -- these are ALLOWED to need support, by explicit choice --"
	@$(PYTHON) $(TOOLS)/support.py $(SUPPORT_ARGS) $(EXEMPT_STLS) || true
endif

clean:
	rm -rf $(OUT)

help:
	@echo "make          STLs, 3MFs, plates, then every check"
	@echo "make stl      just the STLs        parts:  $(PARTS)"
	@echo "make plates   just the 3MF plates  plates: $(PLATES)"
	@echo "make check    just the verification (needs the STLs)"
	@echo "make clean    remove $(OUT)/"
