# Listing copy — Dual Wedge Charging Dock

Paste-ready text for Printables / MakerWorld / Thingiverse. Numbers come from
the model's own `dims` report; regenerate with `make STYLE=furniture check` and
update here if you change parameters.

---

## Title

Dual Wedge Charging Dock for two magnetic pucks (parametric, support-free)

## Summary

An inclined desk dock that swallows two round magnetic chargers and their
cables. Both phones sit side by side at 18°, the cables disappear inside, and
the slack lives in a bay at the back instead of on your desk.

Three printed parts: a wedge base, a top plate, and a flexible TPU mat. No
supports anywhere, no rotating parts in the slicer, and every dimension is a
parameter if your chargers differ from mine.

## Details

- **Fits** two 60 mm round magnetic pucks (designed around the Anker Zolo
  A25M2) and phones up to 76 mm wide, including the case — the puck spacing
  follows `phone_width`, so wider phones are a one-line change.
- **Footprint** 165 × 118 mm, 14 mm at the front rising to 52 mm at the back.
- **Cable management**: each cable leaves its puck at 6 o'clock, loops inside
  the base, runs back under the puck and into a shared 108 cm³ bay with a
  94 mm opening at the rear. Nothing is visible from the front.
- **TPU mat** with a tapered lip that grips each puck so a lifted phone cannot
  pull it out, five studs that press into the plate so the mat needs no glue,
  and optional cut-in textures (honeycomb, chevron tread, cracked stone).
- **Four styles** — `soft_monolith`, `furniture`, `floating_deck`, `faceted` —
  same functional core, different corner radii, chamfers and shadow gaps.
- **Verified, not hoped**: the repo's checkers confirm on the exported meshes
  that everything fits the bed, is watertight, that mating parts only touch,
  and that no layer prints into thin air.

## What you need

| Item | Qty | Notes |
|---|---|---|
| Rigid filament (PETG or PLA) | ~400 g | base + top plate + 2 dowel pins |
| TPU 95A | ~50 g | the mat |
| 6 × 2 mm disc magnets | 4 | hold the plate to the base |
| 8 mm silicone bumpers | 4 | feet; pockets are modelled for them |
| M3 heat-set inserts + M3 × 8 screws | 4 + 4 | only if you prefer screws to magnets (`join_method = "inserts"`) |

## Print settings

- **Rigid parts** — 0.2 mm layers, 4 perimeters, 5 top/bottom, 20 % infill. No
  supports. Print as exported: flat bottom down for the base, parting face down
  for the plate. Ironing on the plate's top surface if you have it.
- **TPU mat** — 0.2 mm layers, 3 perimeters, 15–20 % gyroid, 15–25 mm/s,
  retraction off or minimal. Print it **face down, as exported**: the visible
  face is then the first layer, so a textured sheet gives it its finish and the
  studs point up. Do not rotate it.
- **Dowel pins** — two, standing, 100 % infill. Or use 4 mm steel dowels.

Two ready-made plates are provided: one with the base, top plate and both pins
arranged on a 250 × 210 bed, and one with the mat.

## Assembly

1. Press the two dowel pins into the base, on the rib between the puck seats.
2. Press the four magnets into the base, then four into the plate with opposite
   polarity facing out. A drop of CA each.
3. Feed each puck's plug down through the front slot, along the trench, into the
   bay and out of the rear window. Pull as much slack into the bay as you like.
4. Seat the plate on the base, then drop the pucks into their bores, boot first
   into the cable slot.
5. Lay the TPU mat over them, each cable pocket over its boot, and press the
   five studs into their holes.
6. Stick the four bumpers into the foot pockets.

## If your chargers are different

Measure and change these, then rebuild:

- `puck_nominal_diameter`, `puck_height` — the puck itself.
- `puck_boot_length`, `puck_boot_width`, `puck_boot_top_drop` — the rigid boot
  where the cable leaves the puck. The mat's cable pocket is sized from it.
- `cable_bend_radius` — how tightly your cable will loop.
- `phone_width` — the widest phone, with its case.

Asserts catch the combinations that will not work: too little floor under the
cable loop, too little TPU in front of the cable pocket, a puck lip so steep it
would peel off its own layer.

## Photo shot list

1. Both phones charging on the dock, on a real desk.
2. Three-quarter view, empty, so the styling reads.
3. The back: the cable bay with slack in it, cables leaving through the window.
4. The mat alone, face up, showing the texture and the puck holes.
5. The three parts laid out next to the magnets and bumpers.
6. A canary coupon mid-test, for the "it was measured" story.

## Credit and licence

Models: CC BY-SA 4.0. The source and its checkers live at
<https://github.com/iksaif/3dprint> — remixes welcome, keep the same licence.
