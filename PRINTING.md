# Printing

## Orientation strategy

The chassis is split into two PETG parts on the **inclined plane that carries
the puck floors** (local z = −10.5 mm, parallel to the top face). Both parts
print flat, top side up, with no supports.

Why this plane rather than a horizontal one, and why not face-down:

- **The puck seats become through-holes.** The top plate is a constant
  10.5 mm slab; the bores go all the way through it and the pucks sit on the
  base's sloped top face. A through-hole printed vertically is the most
  dimensionally reliable feature FDM can make: no ceiling, no floor, no
  stair-stepping. The only fit-critical dimension is the bore diameter, and
  it is printed in the plane of the bed. Seat depth is the plate thickness,
  which is set by layer count.
- **Face-down was never viable.** Printing the plate with its top face on the
  bed would put the 144 × 101 mm recess floor and both bore floors
  5–10 mm above the bed as unsupported ceilings. The recess floor alone is a
  bigger bridge than the cable bay ever was. The top face is 90 % covered by
  the TPU insert anyway; the visible 7 mm border prints cleanly top-up.
- **A horizontal parting plane could not hold the cable bay.** It had to sit
  under the thin front of the recess (≤ 9 mm up) to keep the puck bores in the
  plate, which left ≤ 7 mm of bay height in the base, or pushed the bay back
  into a bridged pocket. On the inclined plane the base is ~39 mm tall at the
  rear, so the bay lives entirely there as an open-topped slot roofed by the
  flat underside of the plate.
- **Every internal cavity opens onto the parting plane** or the top face. The
  bend envelope is a through-slot in the plate plus a 3 mm tray in the base;
  the plug chase is an open trench in the puck floor (covered by the puck in
  use); the bay is open-topped; the rear access window is a notch in the base
  whose lintel is the plate. Nothing is bridged.
- **The parting line is horizontal on the front and rear faces and runs at
  18° along the sides**, 10.5 mm below the top face. With the reveal groove it
  reads as a lid on a body, which is what it is.

The only downward-facing ceilings anywhere are the four 6.3 mm magnet pockets
in the plate underside and the four 8.5 mm foot pockets in the base underside.
Both are below `max_bridge_span` (10 mm) and asserted. The plate's front and
rear faces lean 18° (`top_angle`), asserted against `max_overhang_angle`.
Every chamfer is derived from `max_overhang_angle` via `chamfer_rise()`.

## Parts and orientation

| Part | Material | Orientation | Supports | Footprint (bed) |
|---|---|---|---|---|
| `<style>_base` | PETG | as exported: flat bottom on bed, sloped face up | none | 158 × 110 |
| `<style>_top_plate` | PETG | as exported: parting face on bed, top face up | none | 158 × 116 |
| `<style>_top_insert` | TPU | as exported: flat, top up | none | 144 × 102 |
| `dowel_pins` | PETG | as exported, standing | none | tiny |
| `fit_test` | PETG | as exported | none | 40 × 40 |
| `fit_test_mat` | TPU | as exported | none | 40 × 40 |

The base and top plate fit a 256 mm bed side by side (158 + 158 > 256, so
print them nose-to-tail or in two jobs). Nothing needs rotating in the slicer.

## Settings — PETG (base, top plate, pins)

- Layer height 0.2 mm. The plate is 10.5 mm = 52.5 layers; the slicer will
  round to 52 or 53 layers (±0.1 mm on puck protrusion). If that matters to
  you, set `puck_height = 10.4` or `10.6`.
- Walls: 4 perimeters (1.6 mm). The thinnest asserted walls are 2.4 mm
  (bay) and 2.0 mm floors; 4 perimeters keeps them solid.
- Top/bottom: 5 layers each. The plate's border and the recess floor are top
  surfaces; enable **ironing on the top surfaces** of the top plate if your
  slicer has it — the border is the most visible PETG surface on the object.
- Infill 20 % gyroid or grid. The rear of the base is a thick wedge; 15 % is
  fine there but keep 20 % for the plate so the magnet pockets and dowel
  holes are surrounded by solid material.
- First layer: standard PETG (smooth PEI with glue-stick release or textured
  PEI). The 0.4–0.5 mm × 45° bottom chamfers absorb elephant foot; do not
  also enable elephant-foot compensation above 0.1 mm or the reveal line
  will show a step.
- Slow the outer perimeter on the plate's front/rear faces if you see
  ringing on the 18° lean; 40 mm/s outer wall is plenty.
- Dowel pins: print two, 100 % infill, standing. Or use 4 mm steel dowel or a
  cut nail if you prefer; the base hole is a light press (+0.15 mm), the plate
  hole is a slip (+0.30 mm).

## Settings — TPU (top insert)

- Shore 95A (e.g. NinjaFlex Cheetah, Filaflex 95A, Polymaker 95A).
  Softer than 90A will print the bezel ring poorly and will not seat cleanly.
- Layer height 0.2 mm, 0.4 nozzle, 15–25 mm/s, retraction off or ≤ 1 mm
  direct drive, part cooling 50–100 %.
- Flow: TPU over-extrudes at the same flow as PETG. Start at 95 % and check
  the puck holes measure 60.0; the design assumes zero radial clearance in the
  TPU (`puck_hole_diameter = 60`) because the TPU should hug the puck.
- The **diamond top pattern** comes from the slicer, not the CAD: set top
  solid layers to 0 and infill to 3D honeycomb or cubic at 30–40 % so the
  infill is exposed. The CAD top surface is flat for this reason. The bezel
  ring is a 0.4 mm-high solid ring and will print as perimeters regardless.
- Perimeters 3, bottom layers 4.
- Shrinkage: TPU shrinks ~1 % on cooling, mostly in XY. `mat_clearance_total`
  is 0.55 mm; if your insert is still tight, measure it and raise the value.

## Before printing the full set

Run `make fit-test` and print `fit_test.stl` (PETG, ~10 min) and
`fit_test_mat.stl` (TPU, ~10 min). Check:

1. A puck drops into the 90° seat arc without force and without rattling.
   Adjust `puck_radial_clearance` (per side).
2. The TPU corner drops into the recess corner and lies flat.
   Adjust `mat_clearance_total`.
3. The puck's USB-C plug passes through the 14 × 8.5 mm trench section.
   Adjust `rim_cable_channel_width` / `rim_cable_channel_height`.

## Assembly

1. Press the two dowel pins into the base (rib between the puck seats).
2. Magnets: press 4 × 6 × 2 mm into the base pockets, then 4 into the plate
   pockets with **opposite** polarity facing out; a drop of CA each.
   Inserts: heat-set 4 × M3 into the base; M3 × 8 countersunk-head screws
   go in from the recess floor of the plate and end up under the TPU.
3. Feed each puck's plug down through the front slot, along the trench, into
   the bay and out through the rear window. Pull the slack you want into the
   bay.
4. Seat the plate on the base, then the TPU insert, then the pucks.
5. Stick four 8 mm silicone bumpers in the foot pockets.
