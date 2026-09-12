# Post collar helmet holder. The build rules are shared — see ../../mk/model.mk.
#
#   make            STLs, 3MFs, build plates, then every verification check
#   make plates     just the ready-to-slice 3MF plates
#   make check      just the checks (fast; needs the STLs)
#   make renders    the review renders (slow)
#   make clean

REPO    := ../..
SCAD    := src/main.scad
SOURCES := $(wildcard src/*.scad) $(wildcard $(REPO)/lib/scad/*.scad)

# ext_stub is in here because it is a real printed part — it is the test coupon
# — and because leaving it out meant nothing checked it. An edit that reduced it
# to an empty mesh passed `make check` clean; the coupon plate would have sliced
# to nothing and the first sign of it would have been an empty bed.
PARTS   := u_bracket cover pad pad_arm screw_cap ext_stub \
           ext_helmet ext_light ext_strap ext_lock ext_shelf

PLATES     := petg light tpu coupon

# No supports is the rule and it fails the build. ext_light is the one part that
# has bought out of it: its width sweeps from the full plate to a 10 mm toe over
# the whole arm, which is a ~17 deg underside and cannot be printed dry at any
# rate. ext_helmet is the same cradle without the sweep and still comes back
# clean — so this is a choice between two parts, not a relaxed standard.
SUPPORT_EXEMPT := ext_light

PLATE_SCAD := src/plates.scad

DIMS_PART := dims

FIT_SCAD  := tools/fitcheck.scad
FIT_CASES := ext:extension vs cover,clamp:cover vs U-bracket,pad:TPU pad vs its pocket,pad_arm:TPU side pad vs its pocket

# Cantilever bending, section by section, measured off the exported mesh; and
# the hook kinematics, which the boolean fit check provably cannot answer.
# `=` not `:=`: PYTHON and OUT are defined by the include below, so this has to
# expand at use time rather than here.
# Both cradles, because ext_light is the one with the material taken out of it —
# checking only the fat one would be checking the case that cannot fail.
EXTRA_CHECKS = $(PYTHON) ./tools/hookcheck.py && \
               $(PYTHON) ./tools/strength.py $(OUT)/ext_helmet.stl && \
               $(PYTHON) ./tools/strength.py $(OUT)/ext_light.stl

include $(REPO)/mk/model.mk

.PHONY: renders
renders:
	./build.sh
