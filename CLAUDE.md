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
- **Work out the assembly MOTION before designing the retention.** The helmet
  holder had a leaf-spring snap for a long time and it never worked, because the
  joint's hard stop at the top is a pivot: the extension can only arrive by
  rotating about it, and the catch was shaped for a straight vertical drop. The
  fix was a pair of tabs that engage on the arc. Ask "how does this part
  actually move as it goes on?" first — the answer usually removes the need for
  a flexure entirely.
- **Prefer a geometric interlock to a spring.** Nothing to fatigue, nothing thin
  to print. Two hard surfaces that overlap in the direction you want to block
  beat any amount of clever cantilever.
- **A clearance fit passes a boolean interference check by MISSING entirely.**
  Correctly-engaged and completely-disengaged both intersect in zero volume. If
  a feature is supposed to catch, test it by moving the part until it fouls —
  see `models/helmet-holder/tools/hookcheck.py`.
- **Ramp added material along the PRINT Z, not the model axis that looks right.**
  A tab on a part printed on its side ramps in X; ramping it in Z looks correct
  on screen and does nothing for the printer.
- **Check the checker before believing a failure.** OpenSCAD's manifold backend
  guarantees manifold output; a mesh check that disagrees is usually welding
  vertices at the wrong tolerance, not finding a real defect.
- **`:=` in a model Makefile expands before the include.** Use `=` for anything
  referencing `$(PYTHON)` or `$(OUT)`.

## Editing

Use the Read/Write/Edit tools for source changes. Not python heredocs, not `sed`
— they have silently clobbered files in this repo before.
