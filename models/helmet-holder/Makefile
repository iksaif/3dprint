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

PARTS   := u_bracket cover pad pad_arm ext_helmet ext_strap ext_lock ext_shelf

PLATES     := petg tpu coupon
PLATE_SCAD := src/plates.scad

DIMS_PART := dims

FIT_SCAD  := tools/fitcheck.scad
FIT_CASES := ext:extension vs cover,clamp:cover vs U-bracket,pad:TPU pad vs its pocket,pad_arm:TPU side pad vs its pocket

# Cantilever bending, section by section, measured off the exported mesh.
# `=` not `:=`: PYTHON and OUT are defined by the include below, so this has to
# expand at use time rather than here.
EXTRA_CHECKS = $(PYTHON) ./tools/strength.py $(OUT)/ext_helmet.stl

include $(REPO)/mk/model.mk

.PHONY: renders
renders:
	./build.sh
