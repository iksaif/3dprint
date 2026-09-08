# Working in this repo

Parametric OpenSCAD models for a Prusa MK4S. PETG, TPU where flex is needed, no
supports anywhere.

## Non-negotiables

**Render it and look at it.** OpenSCAD code is not verifiable by reading. A part
compiles cleanly and is completely wrong. Never report a model as working without
exporting a PNG and actually viewing it. The `.claude/skills/openscad` skill has
the loop.

**Run `make check` and read the output.** Not "it built". The checks exist because
each of them has caught something a render did not.

**No supports, ever.** If a feature needs support, the feature is wrong. A part
prints support-free iff, at every layer, its material rests on material in the
layer below. A prism along the part's own print Z always satisfies this.

## The shared pieces

- `lib/scad/print.scad` — bed, layer height, overhang limit, clearances,
  material properties. `include` it, don't `use` it: `use` skips variables.
- `lib/scad/holes.scad` — teardrops, hex pockets, nut slots. Every horizontal
  bore is a teardrop; use `hole_x`/`hole_y` rather than rolling the rotation by
  hand, which is how a bore and its own counterbore end up pointing opposite ways.
- `lib/scad/shapes.scad` — `rrect`, `stroke`, `smooth2d`, `chamfered_extrude`.
  Note `chamfered_extrude` erodes its child by `c` first, so anything narrower
  than `2*c` vanishes rather than being chamfered.
- `mk/model.mk` — build rules. A model sets `PARTS`, `PLATES`, `FIT_CASES` and
  includes it.

## Adding a model

```
models/<name>/
  src/params.scad     every dimension, nothing hardcoded elsewhere
  src/main.scad       dispatches on `part`, plus a `dims` part that echoes numbers
  tools/fitcheck.scad intersections of parts that mate, dispatching on `which`
  Makefile            ~15 lines: PARTS, PLATES, then include ../../mk/model.mk
  README.md
```

Then add a row to the root README's model table.

## Things learned the hard way here

- **A moment is a couple.** It needs tension at one end and compression at the
  other, not a grip along the whole joint. That realisation is what made the
  helmet holder's extension joint printable — see `models/helmet-holder/INTERFACE.md`.
- **Put a flexure where the cross-section is constant.** A leaf spring on a part
  that prints upright is identical on every layer and free; the same leaf on a
  part that prints on its side begins in mid-air.
- **Snap force goes as t³ and stress as t/a².** Shortening a leaf without
  thinning it multiplies the stress fast. Compute it, don't eyeball it.
- **Check the checker before believing a failure.** OpenSCAD's manifold backend
  guarantees manifold output; a mesh check that disagrees is usually welding
  vertices at the wrong tolerance, not finding a real defect.
- **`:=` in a model Makefile expands before the include.** Use `=` for anything
  referencing `$(PYTHON)` or `$(OUT)`.

## Editing

Use the Read/Write/Edit tools for source changes. Not python heredocs, not `sed`
— they have silently clobbered files in this repo before.
