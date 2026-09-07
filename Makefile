OPENSCAD ?= arch -x86_64 openscad
SCAD = dual_wedge_charging_dock.scad

.PHONY: all chassis chassis-side mat variants variant-sides debug fit-dummies cable-clearance clean version

all: chassis mat

variants: \
	soft_monolith_chassis.stl soft_monolith_top_insert.stl \
	floating_deck_chassis.stl floating_deck_top_insert.stl \
	faceted_chassis.stl faceted_top_insert.stl \
	furniture_chassis.stl furniture_top_insert.stl

variant-sides: \
	soft_monolith_chassis_side_print.stl \
	floating_deck_chassis_side_print.stl \
	faceted_chassis_side_print.stl \
	furniture_chassis_side_print.stl

version:
	$(OPENSCAD) --version

chassis: dual_wedge_chassis.stl

chassis-side: dual_wedge_chassis_side_print.stl

mat: dual_wedge_tpu_mat.stl

debug: fit-dummies cable-clearance

fit-dummies: fit_dummies.stl

cable-clearance: cable_clearance.stl

dual_wedge_chassis.stl: $(SCAD)
	$(OPENSCAD) -D 'part="chassis"' -o $@ $<

dual_wedge_chassis_side_print.stl: $(SCAD)
	$(OPENSCAD) -D 'part="chassis_side_print"' -o $@ $<

dual_wedge_tpu_mat.stl: $(SCAD)
	$(OPENSCAD) -D 'part="mat"' -o $@ $<

fit_dummies.stl: $(SCAD)
	$(OPENSCAD) -D 'part="fit_dummies"' -o $@ $<

cable_clearance.stl: $(SCAD)
	$(OPENSCAD) -D 'part="cable_clearance"' -o $@ $<

soft_monolith_chassis.stl: $(SCAD)
	$(OPENSCAD) -D 'style="soft_monolith"' -D 'part="chassis"' -o $@ $<

soft_monolith_top_insert.stl: $(SCAD)
	$(OPENSCAD) -D 'style="soft_monolith"' -D 'part="top_insert_flat"' -o $@ $<

soft_monolith_chassis_side_print.stl: $(SCAD)
	$(OPENSCAD) -D 'style="soft_monolith"' -D 'part="chassis_side_print"' -o $@ $<

floating_deck_chassis.stl: $(SCAD)
	$(OPENSCAD) -D 'style="floating_deck"' -D 'part="chassis"' -o $@ $<

floating_deck_top_insert.stl: $(SCAD)
	$(OPENSCAD) -D 'style="floating_deck"' -D 'part="top_insert_flat"' -o $@ $<

floating_deck_chassis_side_print.stl: $(SCAD)
	$(OPENSCAD) -D 'style="floating_deck"' -D 'part="chassis_side_print"' -o $@ $<

faceted_chassis.stl: $(SCAD)
	$(OPENSCAD) -D 'style="faceted"' -D 'part="chassis"' -o $@ $<

faceted_top_insert.stl: $(SCAD)
	$(OPENSCAD) -D 'style="faceted"' -D 'part="top_insert_flat"' -o $@ $<

faceted_chassis_side_print.stl: $(SCAD)
	$(OPENSCAD) -D 'style="faceted"' -D 'part="chassis_side_print"' -o $@ $<

furniture_chassis.stl: $(SCAD)
	$(OPENSCAD) -D 'style="furniture"' -D 'part="chassis"' -o $@ $<

furniture_top_insert.stl: $(SCAD)
	$(OPENSCAD) -D 'style="furniture"' -D 'part="top_insert_flat"' -o $@ $<

furniture_chassis_side_print.stl: $(SCAD)
	$(OPENSCAD) -D 'style="furniture"' -D 'part="chassis_side_print"' -o $@ $<

clean:
	rm -f dual_wedge_chassis.stl dual_wedge_chassis_side_print.stl dual_wedge_tpu_mat.stl fit_dummies.stl cable_clearance.stl
	rm -f soft_monolith_chassis.stl soft_monolith_top_insert.stl soft_monolith_chassis_side_print.stl
	rm -f floating_deck_chassis.stl floating_deck_top_insert.stl floating_deck_chassis_side_print.stl
	rm -f faceted_chassis.stl faceted_top_insert.stl faceted_chassis_side_print.stl
	rm -f furniture_chassis.stl furniture_top_insert.stl furniture_chassis_side_print.stl
