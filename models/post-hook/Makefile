# Snap-on post hook. The build rules are shared — see ../../mk/model.mk.
#
#   make            STLs, 3MFs, build plates, then every verification check
#   make plates     just the ready-to-slice 3MF plates
#   make check      just the checks (fast; needs the STLs)
#   make clean

REPO    := ../..
SCAD    := src/main.scad
SOURCES := $(wildcard src/*.scad) $(wildcard $(REPO)/lib/scad/*.scad)

# One collar, three hooks. The collar is identical in all three, so a size is a
# row in the table in params.scad and nothing else.
PARTS   := clip_s clip_m clip_l

PLATES     := petg test
PLATE_SCAD := src/plates.scad

DIMS_PART := dims

# No FIT_CASES: it is one part, so nothing mates at zero volume. The overlaps
# that matter — the lips on the post's front — are driven by springcheck.py
# through tools/fitcheck.scad.

# The spring, and the catch. Neither is answerable by a fit check: one is a
# force and the other is an overlap that only exists once the arms are sprung.
# `=` not `:=`, because PYTHON comes from the include below.
EXTRA_CHECKS = $(PYTHON) ./tools/springcheck.py

include $(REPO)/mk/model.mk

# ---- calibration ladder -------------------------------------------------------
# Thin slices of the collar, each drawn bigger by a different fit_adjust, on one
# plate. Push each onto the post and see which fits — see PRINTING.md. A slice
# has exactly the full clip's fit, because the collar is a prism along print Z.
#
#   make calib      -> build/plates/calib.3mf
CALIB_STEPS  := 0.1 0.2 0.3
CALIB_STLS    = $(addprefix $(OUT)/calib/calib_,$(addsuffix .stl,$(CALIB_STEPS)))
comma := ,
empty :=
space := $(empty) $(empty)

.PHONY: calib
calib: $(OUT)/plates/calib.3mf

$(CALIB_STLS): $(OUT)/calib/calib_%.stl: $(SOURCES)
	@mkdir -p $(@D)
	$(SCADRUN) --export-format binstl -o $@ -D 'part="calib"' -D 'fit_adjust=$*' $(SCAD)

$(OUT)/plates/calib.3mf: $(CALIB_STLS) src/calib_plate.scad
	@mkdir -p $(@D)
	$(SCADRUN) --enable=lazy-union -o $@ \
	  -D 'steps=[$(subst $(space),$(comma),$(CALIB_STEPS))]' src/calib_plate.scad
