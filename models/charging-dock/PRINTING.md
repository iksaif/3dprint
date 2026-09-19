# Printing

Every part prints flat, with no supports and nothing to rotate in the slicer:
the rigid parts top side up, the TPU mat face down. The chassis is parted on the inclined plane carrying the puck
floors, so the puck seats are through-bores in the plate and the base's
sloped face is the puck floor. The only downward-facing ceilings anywhere are
the four 6.3 mm magnet pockets and the four 8.5 mm foot pockets, both well
inside `max_bridge_span` (10 mm) and asserted.

## Parts and orientation

| Part | Material | Orientation | Supports | Footprint (bed) |
|---|---|---|---|---|
| `<style>_base` | PETG / PLA | as exported: flat bottom on bed, sloped face up | none | 165 × 118 |
| `<style>_top_plate` | PETG / PLA | as exported: parting face on bed, top face up | none | 165 × 127 |
| `<style>_top_insert` | TPU | as exported: face down, studs up | none | 149 × 109 (furniture) |
| `dowel_pins` | PETG / PLA | as exported, standing | none | tiny |
| `fit_test` | PETG / PLA | as exported | none | 40 × 40 |
| `fit_test_mat` | TPU | as exported: face down, like the mat | none | 40 × 40 |

`make plates` writes `build/plates/set_petg.3mf`: the base, the top plate and
both pins as separate objects, each turned 90° about Z and laid side by side at
249.5 × 173 mm on the MK4S's 250 × 210 bed. That X is what caps `body_depth` at
118. The file name says PETG but carries no material; pick PLA in the slicer if
that is what you print. The TPU insert is a separate job (`set_tpu.3mf`)
because of the filament change.

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
- The mat is exported **face down** (`mat_print_face_down`): its visible face
  is the first layer, so a textured or patterned sheet gives it its look and
  there is nothing to iron. Let it cool fully before peeling; TPU grips PEI.
- The five **studs** under the mat (`mat_dowels`) point up as printed. They
  are 4 mm TPU pressed into 3.6 mm holes in the recess floor, which holds the
  mat without glue. Face up they would hang below the bed, so they need the
  face-down print; turn `mat_dowels` off to go back to glue.
- A modelled groove texture is still available (`mat_texture`: `hex`, `tread`,
  `rugged`; `none` by default): 0.8 mm grooves cut in, never raised, so the
  phone still rests on the puck faces and the chargers' magnetic grip is
  unchanged. Face down, the grooves print as short 1.6 mm bridges.
- The raised bezel ring (`mat_bezel`) and the slicer's exposed-infill diamond
  look (top solid layers 0, 3D honeycomb 30–40 %) both need the mat face up:
  `mat_print_face_down = false`, which also means `mat_dowels = false`.
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
   The coupon's quarter hole carries the tapered lip: the hole is 0.3 mm
   tighter at the face than at the underside, over the last 1.5 mm. The puck
   should need a deliberate push to seat and should not drop out when the
   coupon is turned over. Adjust `mat_puck_lip_inset`, or set
   `mat_puck_lip = false` for a plain hole.
3. The puck's USB-C plug passes through the 14 × 8.5 mm trench section.
   Adjust `rim_cable_channel_width` / `rim_cable_channel_height`.
4. **Press fit** (`fit_test_dowel` rigid + `fit_test_dowel_mat` TPU, ~10 min
   each): six holes, marked with 1 to 6 dots — 3.8, 4.0, 4.2, 4.4, 4.6 and
   4.8 mm against a 4 mm stud, so the ladder runs from interference through
   to clearance. Every hole is vented through the tile, as the plate's are:
   a blind hole with a soft plug in it traps air and feels far tighter than
   it is. Press a stud into each, keep the tightest one that seats fully
   without folding the stud, and set `mat_dowel_interference` to 4.0 minus
   that hole. Measure a printed stud and a printed hole with calipers too:
   TPU pegs print fat and rigid holes print small, which is what makes the
   nominal numbers misleading.
5. **Puck grip** (`fit_test_lip`, TPU, ~15 min): a ring of the real mat round
   one hole. Press the puck in — boot through the relief — then turn the ring
   over and shake gently. It should hold the puck, and still let it out with a
   deliberate push. Adjust `mat_puck_lip_inset`.
6. **Cable path** (`fit_test_cable`, rigid, ~30 min): the front of the base
   round one puck's route. Thread the real cable in: the boot lies in the
   trench mouth, and the U-turn drops into the pocket. If the loop will not
   sit without forcing, raise `cable_bend_radius` and check the assert on the
   floor under it still passes.

## Assembly

1. Press the two dowel pins into the base (rib between the puck seats).
2. Magnets: press 4 × 6 × 2 mm into the base pockets, then 4 into the plate
   pockets with **opposite** polarity facing out; a drop of CA each.
   Inserts: heat-set 4 × M3 into the base; M3 × 8 countersunk-head screws
   go in from the recess floor of the plate and end up under the TPU.
3. Feed each puck's plug down through the front slot, along the trench, into
   the bay and out through the rear window. Pull the slack you want into the
   bay.
4. Seat the plate on the base, then drop each puck into its bore, boot down
   into the cable slot. **Pucks before the mat**: the mat's cable relief is a
   blind pocket, so it comes down over the boot rather than the boot passing
   through it. With `mat_cable_pocket = false` the order is the other way.
5. Lay the TPU insert in the recess, each cable pocket over its boot, and press
   the five studs into their holes. To take a puck out later, lift the mat first.
6. Stick four 8 mm silicone bumpers in the foot pockets.
