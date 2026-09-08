# Task

Design a **3D-printable bike helmet holder** in OpenSCAD. It clamps onto a vertical square
post in my bike cage. The clamp is a **reusable platform**: the helmet arm is just the first
of several interchangeable extensions.

Work in `/Users/corentin.chary/dev/3dprint/helmet-holder`. Iterate: write SCAD → render STL
and PNGs → **look at the renders yourself** → fix what's wrong → repeat. Don't hand me
anything you haven't visually inspected.

---

## 1. Hard constraints

**The post**
- Vertical steel post, square section, **100 × 100 mm nominal**, corners slightly rounded
  (assume R ≈ 5 mm, parameterise it).
- **Powder-coated / painted steel.** The coating must not be chewed up — contact faces need
  soft pads (I'll add adhesive rubber/felt, or print TPU pads) and generous, flat bearing
  area rather than sharp edges.
- I have not measured it precisely. Design must work over **96–104 mm** without reprinting,
  by bolt travel alone.
- Useful fact: because the post is **square**, the clamp physically cannot rotate around it.
  Grip only has to resist (a) sliding down and (b) the tipping moment from the load.
  Don't over-engineer clamping force — over-tightening a printed part is how it cracks.

**The printer / material**
- **PETG.** Bed **250 × 250 mm** usable, 250 mm Z. 0.4 mm nozzle, 0.2 mm layers.
- No part may exceed the bed. Prefer parts that print **flat on the bed with no supports**;
  a little bridging is fine, tall unsupported overhangs are not.
- **Design around layer adhesion.** PETG is strong in-plane and weak between layers. Every
  loaded feature must be oriented so the load is carried *within* layers, not peeling them
  apart. Explicitly state the intended print orientation for each part, and justify it
  against the load path.

**Fasteners**
- M5 or M6, your choice — pick one and stick to it. Stainless hex bolts + nuts, from a
  hardware store. Say exactly what to buy (count, thread, length) in a BOM.
- Nuts should be **captive** in hex pockets so I can tighten one-handed.
- Note the standard dims you're using: M6 clearance ⌀6.5, nut 10 mm A/F × 5 mm; M5 clearance
  ⌀5.5, nut 8 mm A/F × 4 mm. Add ~0.3 mm print clearance and say so.
- **Removable / relocatable easily** is a real requirement: I want to move this thing without
  a workshop. Consider knurled thumb-wheels or printed wing-nut caps over the hex nuts so
  it's tool-free once assembled. Two bolts total is better than eight.

**Load**
- ≤ 1 kg. Bike helmet ~350 g; a D-lock hook should tolerate ~1.5 kg. Design for ~3 kg static
  as a safety margin, then say what you assumed.

---

## 2. Architecture

Two layers, cleanly separated:

**A. The clamp** — grabs the post. Universal, never changes.

**B. Extensions** — bolt onto the clamp's front face via a **documented mechanical interface**.
Design the interface deliberately and document it as a contract, so I can design more
extensions later against it. My suggestion (override it if you have a better idea, and say
why): a **vertical dovetail rail** on the clamp so the extension slides down from the top and
is carried in shear by the rail rather than by the screw, plus one retaining screw so it can't
lift out. That gives tool-light swapping and takes the moment off the fastener.

**Extensions to deliver (three, all sharing the interface):**
1. **Helmet cradle** — a broad curved horn that goes *inside* the helmet shell. Wide enough
   to spread load across the EPS foam without denting it, angled so the helmet sits stably and
   doesn't slide off, and shaped so a helmet with a visor still fits. This is the primary one;
   spend the most effort here.
2. **Strap hook** — simple upward hook to hang a helmet by its chin strap. Minimal.
3. **Lock / light hook** — stouter downward hook for a D-lock, ~1.5 kg.

---

## 3. OpenSCAD code quality

- One file per part or a shared `common.scad` + per-part files — your call, but keep the
  clamp and extensions **decoupled**. Interface dimensions live in exactly one place.
- **Everything parametric**, named constants at the top with units and a one-line comment
  each: post size, corner radius, adjustment range, wall thickness, bolt size, clearances.
- Use `$fn` sensibly (low for preview, high for export — a `$preview` conditional).
- **Fillet every stress riser.** Sharp internal corners are where printed parts crack. Use
  `minkowski` sparingly (it's slow) or hand-built rounded primitives / `offset()` on 2D
  profiles extruded — the latter is usually faster and cleaner.
- Provide a `part = "..."` selector plus an `assembly` mode that shows everything positioned
  around a mock post, so I can sanity-check fit.
- Provide a `cutaway = true` mode that differences away half the model, so you can inspect
  internal geometry (bolt pockets, nut traps) in renders. **Use it during review** — most
  bugs in this kind of part are invisible from the outside.

---

## 4. Verification loop — do this every iteration

OpenSCAD 2026.08.30 CLI is installed at `/opt/homebrew/bin/openscad`.

```bash
# STL export (use the manifold backend, it's much faster and catches non-manifold geometry)
openscad --backend=manifold -o build/clamp_half.stl -D 'part="clamp_half"' src/main.scad

# Renders you actually look at
openscad --backend=manifold -o build/iso.png --imgsize=1600,1200 \
  --colorscheme=Tomorrow --viewall --autocenter --render -D 'part="assembly"' src/main.scad
```

Rules:
- Render **at least 3 viewpoints** per part (iso, front, and a cutaway section) and open the
  PNGs. A part that "compiles" is not a part that works.
- Treat any OpenSCAD warning as a bug. Run with `--hardwarnings` at least once.
- Check the exported STL bounding box fits 250 × 250 × 250 mm — print the numbers, don't
  eyeball them.
- Before declaring done, walk the checklist explicitly in writing:
  - [ ] Every part fits the bed, stated dimensions
  - [ ] Print orientation stated per part, load in-plane with layers
  - [ ] No overhang worse than ~45° that isn't a short bridge
  - [ ] Bolt holes, nut traps, and clearances verified in a cutaway render
  - [ ] Clamp closes over 96 mm and still opens over 104 mm — verify by rendering both extremes
  - [ ] Extension interface identical across all three extensions
  - [ ] Fillets on loaded corners

---

## 5. Deliverables

1. Commented `.scad` source.
2. Exported STLs in `build/`, one per printable part.
3. The review renders (keep them, don't delete).
4. `README.md` with:
   - photo-style render of the assembly
   - **BOM**: exact bolts/nuts/pads to buy, with counts
   - **print settings**: orientation per part, perimeters, infill %, supports y/n, and *why*
   - assembly + installation steps
   - the **extension interface spec**, dimensioned, so I can design my own later
5. A short note on the design decisions you made where I left it open — especially the clamp
   topology and the interface — with the reasoning and what you rejected.

---

## 6. Where I want your judgement, not mine

I deliberately left the **clamp topology** open. Evaluate the realistic options for a 100 mm
square post on a 250 mm bed — e.g. two L-shaped jaws pulled together by bolts on the diagonal;
a four-corner-block frame; a three-sided C closed by one bolted plate; something else — reason
about print orientation, layer-adhesion load path, part count, adjustment range and how easy it
is to fit and remove one-handed on a post. **Pick one, build it, and tell me why.**

Ask me before making assumptions that would be expensive to undo. Otherwise, proceed.
