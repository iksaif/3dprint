# Changelog — v2 (PROMPT.md v2 revision)

## Status: UNRENDERED

This revision was written without access to an OpenSCAD binary. The code has
been checked for bracket balance, undefined names and use-before-assignment,
and every derived dimension in the asserts was computed by hand for the four
styles, but **no part has been rendered or inspected**. Treat the first
`make check` as part of the review: expect the possibility of CGAL complaints
about coincident faces (the usual fix is nudging an `ov` or `eps`), and look
at every part in the viewer before printing. The acceptance criterion
"render each part and inspect it" is therefore not met by this commit and is
handed to whoever runs it first.

## Orientation (PROMPT 1.1) — split on the inclined puck-floor plane

The chassis is now `base` + `top_plate`, parted on the plane parallel to the
top face at −10.5 mm (the puck floor). Both print flat, top up. Full
reasoning is in PRINTING.md; the short version:

- The prompt's preferred horizontal plane forces a choice between blind puck
  bores in the plate (ceilings if printed face-down; fine if printed top-up,
  but then face-down was the whole point) and a cable bay that either shrinks
  to ≤ 7 mm or becomes a bridged pocket again.
- Face-down printing of the plate is not possible in any variant: the
  144 × 101 mm recess floor would be a ceiling.
- On the inclined plane the plate is a constant-thickness slab with
  **through** bores, the base's sloped face is the puck floor, the bay sits in
  the tall rear of the base as an open-topped slot, and every other cavity
  opens onto the parting plane or the top face. Zero bridges longer than the
  6.3 mm magnet pockets. The parting line is a horizontal line on the front
  and rear faces and an 18° line along the sides.

`chassis_side_print` is gone; there is no longer any reason to print on the
side. The old side-profile radii/chamfers (`side_profile_*`,
`top_side_edge_radius`) are gone with it: a large radius on the top edge
cannot print well in either orientation, and the prompt asked for a flat
land with defined chamfers. All top-face edges now carry one 45° chamfer
(`top_edge_chamfer`, per style) and the plate's bottom edge a 0.4 mm chamfer
that sharpens the reveal. The front reads as a ~11 mm plate face over a
~3 mm plinth with the reveal between them.

## Spans (1.2)

There are no roofs left to gable. `max_overhang_angle` drives
`chamfer_rise()` for every chamfer and is asserted against `top_angle` (the
plate's front/rear faces lean 18°). `max_bridge_span` is asserted against the
only two downward-facing blind pockets (magnets, feet). Each is annotated in
the assert block, which doubles as the list of every non-vertical,
non-open feature.

- Cable bay: open-topped slot, 132 × ~16 mm, floor at 2 mm, up to ~37 mm
  tall at the rear, roofed by the plate's flat underside. Front wall derived
  from the puck bore's rear edge + 2.5 mm; rear wall 4 mm.
- Rear access window: 94 × 11 mm notch in the base's rear wall directly
  under the parting line; the plate is the lintel.
- Plug chase: an open 14 × 8.5 mm trench in the puck floor from the bend
  tray, under the puck, into the bay. Covered by the puck in use, so the
  hidden chase is still hidden. Plug installation is now trivial: drop it in
  the trench with the puck out.
- Bend envelope: 20 × 22.5 through-slot in the plate floor + 3 mm tray in
  the base = the same 20 × 20 × 8.5 envelope as before, under the TPU notch.

## Fits (1.3)

- `puck_diameter = 60.4` → `puck_nominal_diameter = 60` +
  `puck_radial_clearance = 0.25` per side (60.5 bore). Seat depth is now the
  plate thickness, so it is exact by construction.
- `mat_clearance_total` 0.25 → 0.55, plus a 0.6 mm lead-in chamfer at the
  top of the recess wall.
- `part = "fit_test"` (PETG, 40 × 40): 90° arc of a puck seat with the rear of
  the 6 o'clock slot, a recess corner, and an 18 × 8 mm cross-section of the
  plug trench. `part = "fit_test_mat"` (TPU): the matching seat arc with
  bezel and the matching recess corner, same layout so they nest.

## First layer (1.4)

`bottom_undercut_*` removed. Base has a 0.5 mm × 45° bottom chamfer; plate a
0.4 mm chamfer at its parting edge. The "floating" look moved to the reveal
groove at the parting line (`reveal_depth` × `reveal_height` per style).

## Asserts and check (1.5)

Asserts cover: bay walls and floor, plate floor over the bay, bend slot vs
front keepout (asserted, and the keepout is now derived as
`recess_border + 1` so the slot never touches the recess wall), rib between
bores (≥ 8; 12.5 / 14.5 mm), recess floor beside bores, TPU ligament, bezel
fit, dowel and magnet pocket clearances to bores and bay, floors under tray
and trench, reveal vs base front lip, chamfer vs border, bed fit, overhang
and bridge budget. All four styles were checked by hand against every
assert.

`make check` renders every STL, runs the asserts for every style via the
`dimensions` part, then runs `check_mesh.py` (numpy only): watertight,
consistently wound, no degenerate faces, on the bed, not below Z = 0.
Every `.stl` has a `.3mf` twin.

## Concentric radii (2.1)

`recess_radius`, `mat_radius`, `support_radius` are gone. All top-face
profiles are `top_outline_2d(zl, inset)`: the true section of the vertical
footprint prism by the plane at local z, then `offset(delta = −inset)`. The
recess, its lead-in, the insert and both plate chamfers are parallel offsets
of one curve, so borders are constant-width round every corner. Bay, window
and channels keep their own radii (`channel_radius` per style) because they
are not nested in the top face.

## Silhouette (2.2)

- Footprint is a superellipse-cornered rectangle
  (`superrect_points()`, `footprint_exponent`; 4 = squircle for
  soft_monolith and furniture, 2 = circular for floating_deck and faceted).
- Front: flat land with chamfer above (`top_edge_chamfer`) and below
  (`plate_bottom_chamfer` + reveal).
- Bezel: a raised TPU ring (`mat_bezel_width` × `mat_bezel_height`, 1.8 ×
  0.4 default) around each puck hole. Raised, not recessed, because the
  constraints require the TPU top field to stay flat for the exposed-infill
  pattern; a groove would break that. Asserted to stay below the PETG border.
- Rear mark: two debossed rings (the two pucks), 0.35 mm deep, centred under
  the access window. Geometric rather than text so there is no font
  dependency in CI.

## Style system (2.3)

One `style_defaults` list and one `styles` list of `[key, value]` overrides;
`sp(key)` resolves them and asserts on unknown keys. Customizer annotations
on `style`, `part`, `join_method`, and sections for printing constraints
and fit parameters.

## floating_deck (2.4)

Fixed rather than dropped, by reinterpretation: the rigid deck is gone (it
had no retention and 5.4 mm ligaments), and the style now uses the same TPU
insert as the others with a 2 × 2 mm reveal so the top plate visibly floats
over the base. Retention for every style is the dowels + magnets/inserts.

## Anti-slip (2.5)

Four 8.5 × 0.8 mm pockets in the base underside for 8 mm adhesive silicone
bumpers, inset 14 mm from the corners, asserted below `max_bridge_span`.

## Join (new)

`join_method = magnets | inserts | none`. Two 4 × 10 mm printed dowels on the
rib between the pucks (through the plate floor, hidden under the TPU) locate
the plate in every case. Magnet pockets are blind from the plate underside,
open on the base top. Insert variant puts M3 heads under the TPU.

## Documentation (Part 3)

- README rewritten; the dimension table is generated (`DIMENSIONS.md`) from
  `echo()` in the model and the README points at it instead of restating
  numbers. The 5 mm / 5.5 mm / `dual_wedge_chassis.stl` discrepancies are
  gone with it.
- Stale semicolon-bug comment removed.
- PRINTING.md added.

## Removed

`chassis_side_print`, `side_print_friendly`, `side_profile_*`,
`top_side_edge_radius`, `bottom_undercut_*`, `floating_support_*`,
`floating_deck_thickness`, `insert_hole_diameter` (was 60.5 for the rigid
deck), `recess_radius`, `mat_radius`, `rear_access_window_center_*`,
`cable_bay_center_*`, `plug_chase_*`, `rim_cable_channel_center_z`,
`desired_rim_cable_channel_length` (the clamp is now an assert),
`puck_diameter` (split), `insert_surface_recess` (→ `mat_surface_recess`).

## Known deviations from PROMPT.md

- Parting plane is inclined, not horizontal (reasons above and in
  PRINTING.md).
- `front_height` raised from 12 to 14 for soft_monolith and furniture, and
  floating_deck to 15: with 12 the floor under the bend tray was 1.6 mm,
  below `min_floor`. The assert would have failed; raising the front was
  the smaller change compared with shrinking the cable envelope.
- The hidden plug chase is now an open trench under the puck rather than a
  closed passage. It is hidden by the puck, not by plastic.
- Fit test is two coupons (PETG and TPU) rather than one, because the mat
  corner has to be TPU.
- Nothing has been rendered. See "Status" above.
