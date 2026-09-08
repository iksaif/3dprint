# Extension interface — how it was solved

> **Status: solved.** The dovetail is gone. The joint is now a ridge on the
> cover's *top face* and a groove in the extension's flange. Both parts print
> support-free — `tools/support.py` reports 0 unsupported runs on every part.
> The analysis below is kept because it is what led there, and because it is the
> reasoning anyone changing this joint has to reproduce.

**The answer, in one line:** the undercut does not have to be in the cover's
face. Both parts' print orientations object to that surface. Neither objects to
the cover's *top*.

* On the **cover** a ridge grows straight up out of the finished top face, so
  every layer of it lands on solid material. Supported by construction.
* On the **extension** the mating groove lies in the (Y, Z) profile plane, so it
  is a prism along X — the extension's own print Z. Free, and extensions stay
  "one 2D profile" to write.

The extension drops on from above, the ridge enters the groove, and the groove's
front wall is the hard stop against the load's moment. Nothing slides through an
undercut, so nothing has a lip that must begin in mid-air.

Why an undercut was never actually needed: the moment is a *couple*. It needs
tension at one end and compression at the other, not a grip along the whole
joint. The top is the tension end — that is the only place a hard stop belongs.
The bottom is the compression end, and the same moment presses it into the
cover's face for free.

```
ridge: 40 x 6 x 4 mm, takes 75 N at 0.63 MPa  (PETG yields ~50)
groove walls: 4.7 mm behind, 4.7 mm in front (the front one takes the moment)
extension vs cover   0.0000 mm^3 interference
cover.stl       270 layers   0 unsupported runs   OK
ext_helmet.stl  310 layers   0 unsupported runs   OK
```

---

## The problem, as it stood

Everything below documents the failure and the search. It is what makes the
solution above legible, and it is the constraint set for any future change.

---

## 1. The two parts and how they print

This is the crux of the whole problem, so it comes first.

| Part | Print orientation | Layers stack along | A feature is free if it is… |
|---|---|---|---|
| **Cover** | upright, as modelled | the cover's **Z** (height) | a prism along **Z** |
| **Extension** | on its side | the extension's **X** (width) | a prism along **X** |

Extension print mapping (from `extensions.scad`, `orient="print"` =
`translate([0,0,w/2]) rotate([0,-90,0])`):

    (print x, print y, print z) = (−ext_z, ext_y, ext_x + ext_w/2)

**The two parts' free axes are perpendicular.** The cover's free axis is the
direction the extension slides; the extension's free axis is across the joint.
Any feature that is a prism for one part is, in general, a local feature for the
other. That single fact generates the whole problem.

### The printability rule, stated exactly

A feature prints support-free if and only if, **at every layer, its material
rests on material in the layer below.** Consequences:

* A prism along the part's own print-Z always satisfies this.
* **Removed material never violates it.** A pocket, groove or bore can be any
  shape; only its *closing* side matters.
* Every void bounded in print-Z has a closing side where material reappears
  over air. It matters enormously *how* it closes:
  * **anchored along a full edge (a bridge)** — acceptable up to ~15 mm span;
  * **an overhang ≥ 45° from horizontal** — acceptable;
  * **an island** (material with no in-layer connection to supported material) —
    unacceptable;
  * **a knife edge** (material starting at zero width over air) — unacceptable,
    regardless of the angle that follows it.

The last case is the current failure. A 45° flank is fine *once it has started*;
the problem is that it has to start from nothing.

---

## 2. What the joint has to do

Functional requirements, in rough priority order:

1. **Locate** the extension on the cover, repeatably and without slop.
2. **Resist the tipping moment.** At the 3 kg design load this is a **113 N
   couple** trying to pull the extension's top away from the cover's face. This
   is what needs an undercut; nothing else in the joint provides it.
3. **Carry the weight** — 29 N vertical, currently through the roof bearing on
   the rail's top face (0.37 MPa).
4. **Resist lift-off** — currently the snap, 24 N.
5. **Attach and detach by hand**, no tools, repeatedly.
6. **Take an optional M4 × 40 lock screw** for a hard lock (already solved; see
   §5 — it should survive any redesign roughly as-is).

Non-functional, but they are why the design is shaped as it is:

7. **No supports on either part.** Bridges are acceptable; islands are not.
8. **Extensions must stay cheap to author.** Today an extension is one 2D
   profile in the (Y, Z) plane handed to `extension()`; everything else is added
   automatically. Preserving that is worth a lot — there is one cover and an
   open-ended number of extensions.
9. **One cover takes every extension**, including ones built with features
   disabled.

---

## 3. Current geometry (for reference)

The geometry **as it stood when the problem was found** — these are historical
numbers, not current ones. The `rail_*` parameters no longer exist, and the
clamp has since been rebuilt for a 40 mm post (`u_h` 50 → 40, `ext_w` 62 → 56),
which changes none of the reasoning: the failure was about *direction*, not
size, and it would have recurred identically at any scale.

```
rail_base   16      dovetail width at the cover's face (at the rail's TOP)
rail_tip    26      width at the tip, 5 mm proud
rail_depth   5      → flanks at 45° in the X–Y plane
rail_taper   0.6    rail is wider at the BOTTOM, so it wedges as it seats
rail_clear   0.25   perpendicular clearance in the extension's slot
ext_w       62      extension width (fixed)
ext_plate_t 12      extension plate thickness
ext_roof    14      roof + flange over the cover
u_h         50      cover height = rail length
```

Frame: cover face is the X–Z plane, X = width, Z = height, Y = out of the face.
The extension's local y = 0 is the cover's outer face.

---

## 4. The failure, precisely

The extension's slot is a dovetail whose **undercut direction is X** — which is
the extension's **print Z**. Walking up the print:

* The **−x lip** shrinks. Material tapering away. Free.
* The **+x lip** grows, and it starts where the flank meets the back face: a
  **zero-width knife edge with nothing beneath it**.

At 45° the first layer of that lip is **0.2 mm wide and ~50 mm long**, and it is
not a bridge — it is a cantilever, anchored only at the far end where the slot
runs out under the roof and the plate goes solid. It will not form.

Verified by probing the exported mesh (`tools/probe.scad`); the two lips are
asymmetric exactly as described.

---

## 5. What has already been tried — do not retry

| Approach | Outcome |
|---|---|
| **Vertical dovetail** (current) | Cover perfect (rail is a Z-prism). Extension has the knife edge. **Fails.** |
| **Horizontal dovetail** (slide on sideways) | Extension perfect (slot becomes a prism along its print Z). Cover's rail then appears all at once in one layer. **Fails on the cover.** |
| **Square T-slot instead of a dovetail** | Closing side becomes a 2 mm × 50 mm island in mid-air. **Worse.** |
| **Steepen the dovetail** | Better flank angle, but the lip grows *more slowly* → thinner first layers. **Worse.** |
| **Shallower dovetail** | Thicker first layers, but the flank drops below 45°. **Worse.** 45° is the balance point between these two, which is why it is the current value. |
| **Relieve the slot's mouth** | Moves the knife edge from y = 0 to y = 1 and puts the droop into the functional flank instead. **Does not fix it.** |
| **Diagonal rail at angle θ from vertical** | Extension overhang = θ, cover overhang = 90° − θ. Viable, but leaves both parts at exactly 45° and needs the snap and seating stop reworked. See §6. |
| **Ridge on the cover's top + groove in the flange** | **This is what was built.** No undercut anywhere in the sliding plane, so neither part has a lip to start in air. See the top of this file. |

### The one thing that did work, as a model of the right approach

The **snap** had the identical problem — a spring finger on the extension began
in mid-air. It was solved not by reshaping the finger but by **moving the
flexure to the part whose print orientation makes it free**: the spring is now a
leaf cut into the cover's face, running its full height, so it is a Z-prism and
costs nothing. The extension's half became a plain groove across its back face —
removed material, which can never be an island.

**The general lesson: put the geometrically awkward half on the part whose free
axis suits it, and leave the other part with a pure subtraction.** A solution to
the dovetail that follows this pattern is likely to be the right one.

---

## 6. The diagonal option, analysed

Tilt the rail by θ from vertical. The knife edge then acquires a component along
the extension's print Z, so only a *point* of it belongs to each layer and each
layer's new lip material rests on the previous layer's. The island becomes an
ordinary advancing overhang.

The angle is a direct trade:

* **Extension** overhang = **θ** from horizontal → wants θ large.
* **Cover** overhang = **90° − θ** → wants θ small.

They are complementary, so **θ = 45° is the unique angle that equalises them**,
putting both at exactly 45°. This converts a catastrophic feature on one part
into a marginal-but-standard one on both.

Known consequences:

* **Clearance is fine.** Sliding on at 45° needs ~35 mm of lateral travel. The
  U-bracket's arms end at y = 97 while the extension lives at y ≥ 119, so it
  passes 22 mm in front of them. The cover's lips are also behind that plane.
* **The snap needs rework** — it is currently bumps at fixed X catching a groove
  at fixed Z; both halves would have to follow the slide direction.
* **The seating stop needs rework** — the roof currently lands on the rail's top
  face, which becomes a corner.
* **The cover's rail degrades** from a perfect vertical prism to a 45° overhang.
* Gravity still seats it (weight component along the rail = 0.71 W) and the
  taper still wedges.

This is the best option identified so far, but it leaves *both* parts at exactly
the 45° limit, and it is not obviously the only answer. A better solution may
exist.

---

## 7. What a solution must satisfy

1. No unsupported islands or knife edges on **either** part, in each part's own
   print orientation. Bridges ≤ ~15 mm and overhangs ≥ 45° are acceptable.
2. Provides an undercut resisting a 113 N pull-out couple.
3. Extension attaches and detaches by hand.
4. An extension remains describable as a 2D profile plus automatic features.
5. Does not require the cover's leaf springs or the M4 lock to be abandoned
   (reworking their positions is fine).
6. Does not change the U-bracket, the pads, or the clamping mechanism.

---

## 8. How to verify a proposal

Existing tools, all of which measure the **exported mesh** rather than trusting
the source:

* `make check` — bounding boxes, dovetail taper, boolean interference by volume,
  extension bending, derived dimensions.
* `tools/fitcheck.py` — boolean interference between mating parts. Note this
  **passed throughout** the current failure: a hole in the wrong place, or a
  feature that cannot print, interferes with nothing.
* `tools/probe.scad` — is there material at a given point? Walks a line through
  both parts in one global frame. This is what confirmed the knife edge.

### `tools/support.py` — the one that catches this

Slices each STL along its print axis, works out which material rests on the
layer below (allowing one layer height of lateral overhang, i.e. exactly 45°),
then grows that seed through the layer and reports anything left further than
`--reach` from support. Bridges survive because they are reachable from two
sides; cantilevers and islands are not.

It is wired into `make check` and **currently fails**, which is the correct
state:

```
pad.stl                35 layers      0 unsupported runs      0.0 mm^2  OK
pad_arm.stl            35 layers      0 unsupported runs      0.0 mm^2  OK
u_bracket.stl         250 layers      0 unsupported runs      0.0 mm^2  OK
cover.stl             250 layers      0 unsupported runs      0.0 mm^2  OK
ext_helmet.stl        310 layers      4 unsupported runs      9.3 mm^2  NEEDS SUPPORT
    z= 39.90  y=   0.40  x  -41.80.. -27.69    14.1 mm
    ...
```

`z = 39.90` is `ext_x = 8.9` — the flank's start at 8.25 — at `y = 0.4`, the
back face, running along the rail. All four extensions fail identically, which
is expected: the defect is in the shared dock, not in any arm profile.

**A solution is finished when this reports OK for every part.** Nothing else in
the toolchain can tell you that — every other check passed throughout the
failure. It now reports OK for all eight parts.
