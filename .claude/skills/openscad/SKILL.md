---
name: openscad
description: Write, render, and debug OpenSCAD models for 3D printing. Use whenever a .scad file is involved, when designing a printable part, or when asked to model/preview/export geometry (STL, 3MF, PNG). Covers the render-and-look verification loop, FDM design tolerances, and the CLI.
---

# OpenSCAD

## The core loop: render, then actually look

OpenSCAD code is not verifiable by reading it. A part can compile cleanly and be
completely wrong. **Never claim a model works without rendering it and viewing the
PNG.**

```bash
~/.claude/skills/openscad/scripts/scad-preview.sh part.scad /tmp/prev
```

Renders iso / front / right / top at 800x600, prints the four paths, and surfaces
errors and warnings. Then Read the PNGs — actually inspect them. Look for: missing
features, parts floating unattached, walls thinner than intended, holes that didn't
punch through, mirrored geometry.

For one specific view or a customizer variant:

```bash
openscad -o out.png --imgsize=800,600 --viewall --autocenter \
  --camera=0,0,0,55,0,25,0 -D 'part_to_render="side_wedge"' part.scad
```

`--camera=tx,ty,tz,rx,ry,rz,dist` — with `--viewall --autocenter`, leave translate
and dist at 0 and set only the Euler rotation. Useful angles: iso `55,0,25`,
front `90,0,0`, right `90,0,90`, top `0,0,0`, back `90,0,180`.

Iterate: render → look → fix → re-render. Budget several rounds; first renders are
usually wrong in some visible way.

## Then check the mesh

A render only proves the part *looks* right. It says nothing about whether the
exported mesh is watertight — a union touching at one edge looks perfect and
slices into garbage. After exporting, always:

```bash
tools/mesh.py --bed 250,210 build/*.stl
```

Reports triangle count, volume and shell count, and exits non-zero on **open
edges** (not watertight), **non-manifold edges** (an edge on 3+ faces — the
edge-touching union bug), **flipped faces**, or a footprint over the bed.

Zero-area triangles are reported in `[brackets]` and never fail, but the two
kinds are **not** interchangeable and conflating them is why a naive checker
calls every chamfered part non-manifold:

- **null** — two corners coincident. Carries no surface and seals nothing, so it
  is dropped from the topology entirely.
- **colinear** — three distinct corners on a line. Seals a T-junction, so it
  stays in the topology and is only excluded from the winding test.

A non-manifold failure means the model is wrong, not the export. Fix it by
overlapping the offending solids, not by re-exporting. But check the tool first:
OpenSCAD's Manifold backend already guarantees a manifold result, so a failure
on a part that OpenSCAD called `manifold` is far more likely to be the checker's
vertex welding than the geometry.

## Then check that it can actually be printed

Watertight is not printable. This is the check that catches the real problem:

```bash
tools/support.py build/*.stl              # default --reach 8
tools/support.py --reach 1 build/*.stl    # tightened, to enumerate every bridge
```

It slices each mesh along its own print Z and reports material that rests on
nothing, tolerating true bridges (reachable from support at both ends) but not
cantilevers or islands. Every other check in this repo asks whether the model is
*correct*; this is the only one that asks whether it is *makeable*, and it is the
one that has caught real defects here.

## CLI

```bash
openscad -o part.stl --export-format binstl part.scad   # binary STL (default is ASCII)
openscad -o part.3mf part.scad                          # 3MF, keeps units + colour
openscad -o part.csg part.scad                          # flattened tree, good for diffing
openscad -o - --export-format echo part.scad            # echo/assert output to stdout
openscad -D 'wall_th=3.2' -D 'part="lid"' -o o.stl in.scad   # override any top-level var
```

`-D` only overrides variables assigned at the top level of the file. Preview PNG
renders use the fast throwntogether path; pass `--render=force` to force full CSG
evaluation when you need to see the true booleaned result — note it takes a value,
a bare `--render` makes OpenSCAD dump its usage text and exit 0 having rendered
nothing. The Manifold backend is
the default and is dramatically faster than CGAL — don't pass `--backend CGAL`
unless something is actually broken under Manifold.

Exit code is 0 even for some geometry warnings, so grep the stderr for `ERROR` and
`WARNING` rather than trusting `$?`.

## House style

This skill lives inside the models repo, so the conventions are the repo's — see
`CLAUDE.md` at the root, and prefer the shared `lib/scad/` helpers over rolling
your own. A new model goes in `models/<name>/` with a Makefile that sets a few
variables and includes `mk/model.mk`; that gets you every check for free.

Older single-file models look like this, and it is still fine for a small part:

```scad
$fn = 100;

/* [Pillar Dimensions] */
post_w      = 100.0; // Width of square pillar (mm)
fit_clearance = 0.5; // Fit clearance for snug sliding (mm)

/* [Render Mode] */
part_to_render = "assembly"; // [assembly, exploded, printable_plate, front_saddle]
```

- Header comment block: what the design is, the mechanism, target material and
  print settings (perimeters, infill, supports).
- `/* [Section] */` customizer groups; every parameter gets a unit and a purpose
  in a trailing comment.
- A `part_to_render` string selector with the options listed in a `// [a, b, c]`
  comment, driving a chain at the bottom of the file. Always include an `assembly`
  view and a `printable_plate` view with parts laid flat and separated.
- Derived values computed once in an `INTERNAL COMPUTATIONS` section, not inline.

## BOSL2

Installed at `~/Documents/OpenSCAD/libraries/BOSL2`, so `include <BOSL2/std.scad>`
just works. Reach for it when a part needs fillets, hardware, or multi-piece
alignment; plain OpenSCAD is still right for simple prismatic parts. Its full docs
are far too large to load — this is the working subset. To check an unfamiliar
signature, grep the source rather than guessing:
`grep -B15 "^module screw_hole" ~/Documents/OpenSCAD/libraries/BOSL2/screws.scad`.

**Rounding and chamfers as arguments** — replaces `hull()`-of-cylinders:

```scad
cuboid([40,24,12], rounding=3, edges="Z");        // vertical edges only
cuboid([40,24,12], chamfer=1, edges=BOTTOM);      // the first-layer chamfer
cyl(d=14, h=10, chamfer2=1);                      // chamfer2 = top end only
rect_tube(size=[40,24], wall=2.4, h=20, rounding=3);
```

`edges` takes `"Z"`/`"X"`/`"Y"`, `TOP`/`BOTTOM`, or `EDGES_ALL` with `except=`.

**`rounding` and `chamfer` are mutually exclusive on one call** — passing both is
an assertion failure, not a warning. For the common case of rounded vertical edges
*plus* a first-layer chamfer, do the second with an edge mask inside `diff()`
(`edge_profile` self-tags as `"remove"`):

```scad
diff()
cuboid([40,24,12], rounding=2, edges="Z")
    edge_profile(BOT) mask2d_chamfer(0.8);
```

**Attachments** — the reason to use BOSL2 at all. `attach(parent_anchor,
child_anchor)` places the child's face against the parent's, killing hand-tracked
translate/rotate chains:

```scad
cuboid([40,24,12]) attach(TOP, BOT) cyl(d=14, h=10);
```

Anchors: `TOP BOT LEFT RIGHT FWD BACK CENTER`, addable (`TOP+RIGHT`). Useful
`attach()` args: `inside=true` to point the child into the parent (for cutters),
`shiftout=0.1` to break the coplanar-face tie, `align=`, `inset=`, `spin=`.

**Subtraction via tags** — cutters positioned by `attach()` rather than `difference()`:

```scad
diff()
cuboid([40,24,12], rounding=2) {
    tag("remove") attach(TOP, TOP, inside=true, shiftout=0.1)
        screw_hole("M5", head="socket", counterbore=5, length=12, thread=false);
}
```

**Hardware** (`include <BOSL2/screws.scad>`) — clearances already correct, don't
add your own:

```scad
screw_hole("M5", head="socket", counterbore=5, length=12, thread=false);
nut_trap_inline(length=12, spec="M5", anchor=BOT, orient=UP);  // hex pocket
```

`thread=false` gives a smooth clearance hole (what you want for a bolt).
`counterbore` defaults to just the head height for socket heads — pass an explicit
depth or the pocket is too shallow to swallow the head.

Gotchas worth remembering:

- **`teardrop()` is already Y-axis.** It is built for horizontal holes, so its
  native axis is FWD/BACK, not UP. Passing `orient=FWD` rotates it *vertical* —
  the opposite of what you want, and it silently renders. Position it with
  `attach(FWD, FWD, inside=true, shiftout=0.1)` and never pass `spin=` to the
  teardrop itself (pass it to `attach()`).
- `include <BOSL2/std.scad>`, not `use` — `use` skips the constants, so `TOP` and
  friends come through undefined.
- BOSL2 overrides `cube`-like names with its own; `cuboid` and `cyl` are the BOSL2
  ones, `cube` and `cylinder` remain stock.
- Rounded BOSL2 solids emit occasional zero-area slivers. `tools/mesh.py` reports
  them in brackets and they are harmless — don't chase them.

## Designing for FDM

Numbers that matter, assuming a 0.4mm nozzle:

- **Clearance**: 0.2mm for a press fit, 0.4–0.5mm for a sliding fit, 0.6mm+ for a
  loose fit over a printed part. Holes print undersized — oversize a bolt hole by
  ~0.2mm (M5 → 5.4mm was chosen for exactly this reason).
- **Walls**: multiples of the nozzle. 1.6mm (4 perimeters) is a good structural
  minimum; below 0.8mm the slicer may drop it entirely.
- **Overhangs**: safe to ~45° from vertical. Steeper needs support — or redesign.
  Chamfer the underside of overhangs rather than adding supports.
- **Bridges**: fine up to ~20mm across if both ends are anchored. Teardrop or
  chamfer horizontal holes so the top doesn't need to bridge a curve.
- **First layer**: add a chamfer or fillet at the base; sharp 90° corners against
  the bed lift.
- **Layer-line anisotropy**: parts are ~40% weaker across layers. Orient so load
  runs along layers, not peeling them apart. Say the intended print orientation in
  the header comment.

## Pitfalls

- **`difference()` coplanar faces z-fight** and can leave a zero-thickness skin.
  Always overshoot the cutting solid past both surfaces — cut with a cylinder of
  `h+2` centred, not `h`.
- **`$fn` is a global cost multiplier.** `$fn=100` on every small fillet makes
  renders crawl. Set `$fn` low while iterating (`-D '$fn=24'`) and high only for
  the final STL. Prefer `$fa`/`$fs` for size-adaptive resolution.
- **Non-manifold output**: unioned solids that only touch at an edge or vertex
  produce geometry slicers reject. Overlap by at least 0.01mm. This is invisible
  in a render — `tools/mesh.py` is what catches it.
- **`scale()` on a hole distorts the tolerance** you carefully chose. Scale the
  design parameters instead.
- **`minkowski()` is exponentially slow.** For a rounded box use
  `hull()` of spheres/cylinders at the corners.
- `echo()` and `assert()` output only appears via `--export-format echo` or on
  stderr — use `assert(wall_th >= 1.6, "wall too thin")` to make constraints fail
  loudly rather than print wrong.
