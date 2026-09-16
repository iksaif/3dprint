# post-hook

A snap-on hook for a 40 × 40 mm post. Two printed parts, no screws, no supports.
Press it on with both thumbs, hang about a kilo off it, squeeze the tabs to take
it off again.

|  |  |
|---|---|
| **Parts** | `clip_s` / `clip_m` / `clip_l` (PETG) + `pad_back` + 2 × `pad_side` (TPU, 1.2 mm) |
| **Load** | 1 kg, with a 2.8× margin on the friction that carries it |
| **Fixings** | none. A cable tie is optional and the slots are there for it |
| **Supports** | none, on any part |

```bash
make            # STLs, 3MFs, plates, then every check
make plates     # build/plates/{petg,tpu,test}.3mf
make check      # just the verification
```

Print `test.3mf` first: one `clip_m` and a set of three pads. Everything worth learning
from a first print — how hard it is to press on, whether the lips release when
you want them to, whether it holds a kilo — is a property of the arm spring over
its whole length, so a coupon cannot tell you any of it.

## How it works

The clip is a C that wraps three faces of the post. The two arms are the spring:
their inner faces are drawn 2 × 2.5 mm closer together than the post plus its
pads, so putting it on springs them open and they squeeze back. But that squeeze
is only *half* the load path, and assuming it was all of it is what broke the
first print — see below. The other half is the load's own moment, which presses
the back pad and the lips into the post with about 15 N each. Together: 28 N of
friction against a 9.8 N load. Nothing is clamped and nothing is bolted.

Each arm ends in a lip whose retention face is a **45° cam tangent to the post's
corner**. Pulling the clip off drives the corner up that cam, and at 45° the
force ratio is 1:1, so getting it off by straight pull needs the same 36 N it
would take to spring the arms apart — while squeezing the thumb tabs releases it
instantly. The cam also makes the fore-and-aft capture elastic: the arms' inward
force resolves on a 45° face into a component pushing the post back onto the
back pad, so the clip clamps itself in both axes and a post 0.5 mm over nominal
just springs the arms 0.5 mm further instead of jamming.

The hook's profile is a **stroke** — a chain of hulled circles whose radius is
the local half-thickness — swept from a thick root, up a stem raked at 50°,
round a Bézier curl, to a slim tip leaning 20° back over the cradle. The
boundary is tangent-continuous through every station, so there is no corner
anywhere to concentrate stress. A load slides down the rake and settles in the V
against the post, which is why the moment arm is 8.5 mm rather than the 22 mm of
reach the part appears to have.

The stroke smooths the hook's own outline but says nothing about its junction
with the wall, which is where the load actually goes in. That came out as four
sharp concave corners, filleted separately because they lie in different planes:
`hook_wall_fillet` in the side profile, made by unioning the wall into the
profile and applying a closing; `hook_side_fillet` in plan, a true radius
tangent to the wall and to the hook's side face, swept up through the hook's own
profile so it follows the rake instead of standing on the bed.

## What the first print taught

It broke going on, and the measurement that explains it is blunt: with the pads
fitted the mouth was **35 mm for a 40 mm post**.

That number is not the pads. The pad thickness cancels straight out of it:

```
hw_in   = post_w/2 + pad_t − preload      (arm's inner face)
crest   = hw_in − pad_t = post_w/2 − preload
opening = post_w − 2·preload              ← pad_t is gone
```

40 − 2×2.5 = 35. Halving `pad_t` would have changed nothing; the only parameter
that opens the mouth is `preload`, and it was 4× too big.

**Why it was too big.** It had been sized from a friction budget that
deliberately left the load's own moment out as "conservative". That is not
conservative — it is leaving out the mechanism doing most of the work and
letting the parameter that compensates absorb the error. A load on the hook
presses the back pad and the lips into the post as a couple, worth ~13 N of
friction on its own, which is why the clip nearly held a helmet with **no pads
and no preload at all**. `springcheck.py` now counts both terms, and fails if
the preload contribution drops too far below the moment's.

| | before | now |
|---|---|---|
| opening | 35 mm | **38 mm** |
| preload per arm | 2.5 mm | 1.0 mm |
| spread to fit | 4.5 mm | 2.5 mm |
| peak root stress | 36 MPa (1.38×) | **21 MPa (2.35×)** |
| push to fit | 5.9 kgf | 3.6 kgf |

A second coupling bit on the way through, worth recording because it was silent:
the catch is `lip_reach − pad_t`, and `lip_reach` had been left as a literal. So
thinning the pads from 3.0 to 1.2 deepened the catch from 2.0 to 3.8 mm on its
own, putting the spread back to 4.8 and the stress to 39 MPa. `lip_reach` is now
derived from `lip_catch`, so moving the pad moves the lip with it.

## Why the pads are thin, flat slabs

They were a standing U with a sawtooth face. The U printed as three thin 28 mm
walls in TPU — floppy, slow, prone to shifting — so it became three slabs lying
flat, **6 layers each**.

`pad_t` is 1.2 because the pad's job is μ, not bulk, and — per the algebra above
— its thickness never set the fit anyway.

**Flat, not toothed**, for a better reason than "the teeth got too big for a
1.2 mm pad" (they did). Elastomer friction is not Amontons': it has an adhesive
component that scales with *real contact area*, so concentrating the same normal
force onto a few tooth crests trades contact away for pressure. That pays only
when biting into something rough. Against a smooth painted post, full flat
contact grips harder.

Flat also kills an assembly trap nothing on the part warned about: a sawtooth is
directional twice over — which face goes to the post, and which end is up — and
fitted upside down its steps resist the one direction that does not matter.

What it costs is the teeth's compliance, which used to absorb `post_w` tolerance
by crushing. That now comes out of the preload margin, which is why `preload` is
1.0 rather than the 0.5 the grip alone would need.

## Where the stress goes

All of it goes to one corner, and it is not the one it looks like. The arms are
pushed **outward** by the post, so at the root the tension face is the one
*opposite* the load — the inner, cavity-facing surface. That is what `fillet_r`
rounds. The external corners are on the compression side, and a convex corner
concentrates nothing, so rounding those buys no strength at all.

The fillet was 1.0 mm and is now 2.5, which is the only rounding in the model
that is structural rather than cosmetic:

| `fillet_r` | r/t | Kt | peak while fitting | margin on yield |
|---|---|---|---|---|
| 1.0 | 0.28 | 1.55 | 42 MPa | 1.18× |
| 2.5 | 0.69 | 1.33 | 36 MPa | **1.38×** |
| 3.5 | 0.97 | 1.27 | 35 MPa | 1.44× |

It costs nothing — no change to stiffness, grip or insertion force — and past
~2.5 it flattens out.

**Thickening the arm is not the alternative**, and the reason is worth keeping
in mind for any printed spring: this one is *deflection*-controlled, not
force-controlled. The post imposes the deflection, so σ = E·3tδ/(2L²) rises
with `t` — a thicker arm carries *more* root stress, not less, while also
needing more force to fit. The levers are the fillet, a longer arm, or less
preload.

The number that is still worth watching is the **sustained** one: 20 MPa sits at
the root for as long as the clip is on the post, and PETG creeps at that level
over months. It will slowly relax the preload and so the grip. `springcheck.py`
fails above 22 MPa, and the cable tie is the fix if a particular clip ever goes
slack.

## The one idea the whole model rests on

**Print Z is the post's own axis.** Everything that wraps the post — arms, snap
lips, cam faces, lead-in ramps, thumb tabs, tie slots — lies in the (x, y) plane
and is therefore a prism along print Z, support-free whatever shape it is. The
undercut that normally makes a snap-fit unprintable runs sideways here, not up,
so it costs nothing.

There is no orientation in which a C that wraps a post and a hook that curls up
are *both* prisms, so the hook pays instead: its underside is a 50° slope and
its upturn leans 20° from vertical. Both are inside the printer's limit, which
is why `make check` reports zero unsupported material on all four parts.

That is also the one thing a stroke does badly, and it needed handling. A
circle's underside goes horizontal at its lowest point, so the root station
bulges out of the wall on a surface that flattens to 20° just as it leaves — a
real overhang that no other check would have failed. The profile is therefore
clipped against the rake line before extrusion: the bulge goes, the underside
leaves the wall as a straight 50°, and everything above it stays as drawn.

## Sizes

One collar, three hooks — a size is a row in the table in `params.scad`. They
are not the same hook scaled, and what separates them is the **mouth**, the gap
a load has to pass through to get in. It grows much faster than the reach,
because on the small size the collar's own back wall is taller than the hook and
walls the entry off.

| | reach | cradle | mouth | lift to escape | width | height | for |
|---|---|---|---|---|---|---|---|
| `s` | 16 | 11 | 7.7 | 20.3 | 12 | 31.3 | cord, strap, lanyard |
| `m` | 22 | 17 | 11.8 | 27.9 | 16 | 40.9 | bag handle, helmet strap, hose |
| `l` | 26 | 21 | 14.8 | 35.2 | 20 | 50.2 | thick handle, coiled lead |

`m` is 22 mm of reach and not 20 because the organic profile cost it mouth: a
rounded tip is fatter near its top than the old straight lean was, which took it
from 13.1 mm to 9.3. Two more millimetres of reach bought it back. Tune these on
the mouth, not on the reach.

## Fitting it

1. Lay the three pads on the collar's inner faces — the wide one on the back
   wall, the two long ones on the arms. They are plain flat slabs with no
   orientation: both faces are the same, so there is no wrong way round. A push
   fit, with a dab of glue if they will not stay put. Once the clip is on the
   post there is nowhere for them to go, so this only matters until you fit it.
2. Offer the clip up to the post and press. The lead-in ramps spread the arms;
   about 3.6 kgf, two thumbs, and it clicks over the corners.
3. To remove: squeeze the two thumb tabs outward and lift it off.

### The cable tie (optional)

There is a 5.4 × 2.2 mm slot through each lip for a 4.8 mm nylon tie, for when
the spring alone is not enough — a heavier load, a slippery post finish, a clip
that has taken a set after a year outdoors.

**The loop stays at the opening end.** In one slot, across the post's exposed
face, out the other slot, then closed back across the outside of the two thumb
tabs — a small loop around the two lips and nothing else. It does not wrap the
clip and never goes near the hook, so the buckle sits behind the clip as you
look at the hook, out of the way.

It is also the stronger of the two routings, which is luck rather than the
reason: both runs bear on the arm **tips**, the far end of the spring, so a
given tie tension buys the most closing force it can. A loop round the whole
clip would spend much of its tension squeezing the back wall, which is rigid and
does not need it.

The slots are through the **lips**, not through the arms: the arms are the
spring, and a hole through the full thickness of a bending beam is a stress
riser exactly where the strain peaks.

A guide channel was tried here and removed. The idea was a shallow groove on the
same band, following the arm's outer face and round the thumb tab, to hold the
tie level while threading it. In practice it did not work, and it was not free:
it grooved the spring for 8% of `I`, and every version of the cutter fought the
geometry. A stepped roof left a zero-volume fin that made the mesh read as **two
shells**; a square roof passed `support.py` but broke the rule it stands for,
since material must rest on material below and a ledge does not; and the
cutter block's outer wall sitting exactly on the collar's own surface shredded
the arm's face into a z-fighting hatch.

The slots alone work. If a guide comes back, the lesson worth carrying is that
its cutter must **cross** every surface it meets rather than land on one —
coplanar faces and tangential contacts are what produced all three failures.

One of those is worth recording for its own sake, because the repo's rule caught
it the right way round. `CLAUDE.md` says to suspect the checker before believing
a mesh failure, since OpenSCAD's manifold backend had reported no error. So it
was checked: an independent split by *vertex* adjacency found one component,
while `mesh.py` splits by *edge* adjacency and found two. That disagreement is
precisely the signature of two closed surfaces meeting at a point. The checker
was right.

## Verification

`make check` runs the shared checks plus `tools/springcheck.py`, which asks the
two questions nothing else can:

- **Does it grip?** The arm spring as a cantilever — stiffness, preload force,
  friction against the load, insertion and pull-off forces, and the peak and
  sustained strain. All from `params.scad`, so the numbers cannot go stale.
- **Does the lip actually catch?** Rendered, not computed, and as a *pair*: the
  lips are placed where they sit once the arms are sprung, then pulled 1 mm off
  the post and intersected with it.

That second one exists because this model got it wrong twice, and both times
every other check passed:

- The catch was quoted as `lip_reach - preload`. Wrong: the preload cancels out.
  Seated, the arm's inner face is always exactly `pad_t` off the post, so the
  overlap is `lip_reach - pad_t`.
- Far worse, and invisible in every render: **the post's corners are rounded.**
  A square retention face 0.5 mm in front of the nominal front face meets a post
  that is only 18.7 mm half-wide at that depth, not 20. The lip reached to 18.0
  and caught 0.3 mm over a 0.7 mm strip. It would have slid off in the hand.

Neither survived a check that put the lips where they sit and intersected them
with the post — the intersection came back *empty*. The fix was to stop
pretending the corner is square and shape the lip to it.

The pull test is a `pull` distance and not an overlap-at-rest for the reason
`CLAUDE.md` gives: a clearance fit passes a boolean interference check by
missing entirely. Here it is sharper still — the cam is *tangent* to the corner,
so zero overlap at rest is the correct answer, and a "must be zero" test would
pass just as happily on a lip that missed the post by a mile. The only way to
test a catch is to move the part until it fouls.

## Numbers

From `make check`, on the default 40 × 40 post:

```
arm spring   3.6 x 36 mm section, 41.1 mm free   ->  12.1 N/mm per arm
grip         15 N preload + 13 N from the moment ->  2.8x on 1 kg
fitting      2.5 mm of spread, 30 deg lead-in    ->  3.6 kgf of push
holding on   1.5 mm of travel over a 45 deg cam  ->  3.7 kgf of straight pull
strain       0.80% peak while fitting, 0.32% sustained  (PETG yields ~2.5%)
root stress  fillet r2.5, Kt 1.33            ->  21 MPa peak, 2.35x on yield
                                                  9 MPa sustained
catch        0 mm^3 at rest (tangent), 54 mm^3 pulled 1 mm off
```

## Reading the assembly render

Parts are modelled **unsprung**, because that is what gets printed. Drawn that
way against a nominal post, the post reads as buried 2.5 mm into the pads on
each side — which looks like a mistake and is not one. It is the preload: on a
real post the arms flex out by exactly that much and carry the pads with them,
and nothing is crushed, since the teeth are only 0.8 mm proud.

A review render that shows 2.5 mm of interference is still a bad review render,
so `show_seated` (on by default) shears each arm to where it actually sits —
linear in y from the back wall, reaching `preload` at `arm_free`, which is a
cantilever's tip deflection to first order. Set it false to see the parts as
printed.

## Fitting a different post

`post_w` is the axis the arms grip, and tolerance there is absorbed by the
spring at the cost of a little preload. `post_d` is the axis the cams capture,
and since the cams made that elastic too, it is no longer the critical
measurement it was.

**`post_corner_r` is, and it is asymmetric.** The lips' cam faces are shaped
tangent to it, and designing for `r_design` against a post that really has
`r_actual` clears the corner *iff* `r_actual >= r_design` — the algebra
collapses to `0.586 · r_actual >= 0.586 · r_design`, since both the tangent
constant and the arc's centre move with `r`. So:

- post **rounder** than designed → a little slack, which the arms simply close
  up and the pads' crests absorb;
- post **squarer** than designed → the cam drives into the corner and the clip
  will not seat without permanently spreading the arms.

One is a nuisance, the other is a part that does not fit. Set it to the
*smallest* radius the post might have, never the average and never a guess on
the high side. It was 3 here — a plausible figure for rolled steel tube — while
the actual posts are near enough square, which would have jammed both lips by
0.8 mm. It is now 0.5.
