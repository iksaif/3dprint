# post-hook

A snap-on hook for a 40 × 40 mm post. One printed part, one material, no
screws, no supports. Press it on with both thumbs, hang about a kilo off it,
squeeze the tabs to take it off again. A cable tie through the lips locks it.

|  |  |
|---|---|
| **Parts** | `clip_s` / `clip_m` / `clip_l` — PETG, nothing else |
| **Load** | 1 kg: 1.5× on friction with no tie, 5.6× with a hand-pulled one |
| **Fixings** | none. A cable tie is optional and the slots are there for it |
| **Supports** | none |

```bash
make            # STLs, 3MFs, plates, then every check
make plates     # build/plates/{petg,test}.3mf
make calib      # build/plates/calib.3mf — the fit ladder, print this first
make check      # just the verification
```

Print the calibration ladder first, then `test.3mf` (one `clip_m`). The ladder
settles the fit in minutes of printing; the whole clip is what tells you how
hard it is to press on, whether the lips release when you want them to, and
whether it holds a kilo.

**Slicer settings, the ladder and the measurements to take are in
[PRINTING.md](PRINTING.md)** — in particular *Perimeters = 4*.

## How it works

The clip is a C that wraps three faces of the post. The two arms are the
spring. Along most of their length they clear the post by 0.1 mm a side and
touch nothing; near the front, a **grip land** 12 mm long stands 0.4 mm proud
of each arm's inner face, so putting the clip on springs the arms open there
and they squeeze back. That is 15 N a side and what keeps the clip in place with
nothing on it.

The squeeze is only part of the load path. The rest is the load's own moment,
which presses the back wall and the lips into the post with about 15 N each —
self-energising, so its margin holds whatever you hang on it. Together, on
bare PETG with a pessimistic μ of 0.25: 15 N of friction against a 9.8 N load,
1.5×. The cable tie turns that into as much as you like; 5 N of tie tension
reaches 2×, and a firm pull by hand is several times that.

Each arm ends in a lip whose retention face is a **cam tangent to the post's
corner**, its normal 25° off the insertion axis — tangent with the arms
*seated*, i.e. already spread by the grip lands, so there is no fore-and-aft
play. Squeezing the thumb tabs is how it comes off; a straight pull takes
~12 kgf, deliberately. The cam also makes the fore-and-aft capture elastic: the
arms' inward force resolves on the inclined face into a component pushing the
post back onto the back wall, so the clip clamps itself in both axes.

### Why 25° and not 45°

It was 45°, chosen so that a straight pull would release it. That left one load
case untested: **the load's own moment**. It presses the tops of the lips into
the post's front corners, and a 45° face turned ~60% of that push into outward
force on the arms — 0.85 mm of a 1.26 mm catch at 1 kg static, which hanging a
helmet on would roughly have doubled. At 25° only 19% comes back, and the lips
open 0.53 mm of 1.24 even allowing 2× for the load being hung on rather than
set down. `springcheck.py` checks this.

The catch is 1.24 mm rather than the nominal 2.0, because the grip lands bear
0.6 of the way along the arm and the tip — where the lip is — moves further
than the land does. That is in the check too.

### The hook

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

It had a TPU liner then — three flat pads — and it broke going on. Two separate
things were wrong: one about how hard the arms were being asked to spread, and
one about *where*.

### The interference reached back to where the arm cannot move

This is the one that actually stopped the post going in, and no stress number
would have found it.

A cantilever's deflection at its root is **zero**. The fraction of the tip's
deflection available at a distance *u* along it is `(3r² − r³)/2` with `r = u/L`,
and it collapses fast — at a tenth of the way along, under 2%. The side pads ran
the full length of the arm, starting 3 mm from the root, where supplying 1 mm of
interference would have needed over **100 mm** of tip deflection. The post was
not being gripped back there. It was jamming against something that could not
open, whatever the arm's stress said.

So the interference lives only where there is compliance to supply it — which
is why the grip lands are short and at the front, and why there is an assert on
the deflection available at a land's back end. It pays twice: the arm is
several times stiffer where the land bears than at its tip, so a small
interference gives a real force.

### And the opening was set by the wrong parameter

With the pads fitted the mouth was **35 mm for a 40 mm post**: the arms had been
drawn 2.5 mm a side tighter than the post, sized from a friction budget that
deliberately left the load's own moment out as "conservative". That is not
conservative — it is leaving out the mechanism doing most of the work and
letting the parameter that compensates absorb the error. The clip nearly held a
helmet with **no pads and no squeeze at all**, which is the moment term doing
its job. `springcheck.py` counts both.

## What the second print taught — and why the TPU went

The next print came out tight *without* the pads, with no room to fit them. A
6 mm calibration slice measured against the drawing said why: everything was
0.2 mm a side small — cavity and arm alike — which is the printer, not the
design. That is now `fit_adjust`: the geometry is drawn around a post
`2 × fit_adjust` bigger than the real one, and the ladder (`make calib`) finds
the value.

With the fit right, the TPU had nothing left to do that PETG could not, and
three loose parts that need gluing are not "simple". So the pads went, and
their one useful effect — a squeeze that keeps the clip in place with no tie —
is moulded into the arm as the grip lands, where the first print said it has to
be.

### Corner relief

The post's corners are square; the inside corners of the C were filleted
(`fillet_r`, 2.5 mm) for the root stress. A concave fillet bulges into the
cavity, and against a square corner it left 0.28 mm of room — which a 0.2 mm
print undersize all but closes. The post's corners were the first thing to
touch.

So the corner is no longer filled, it is **relieved**: a slot sunk 2 mm into the
back wall at each inside corner, the arm's inner face running straight down
into it. A square post corner sits in open space.

It goes into the back wall and not the arm because the corner is also the arm's
**root**, and its tension face is exactly the arm's inner face — a dog-bone
centred on the corner would bite ~1 mm into the most stressed section of the
part. The slot is pushed 0.5 mm into the arm (`relief_off`) as a compromise,
for room round the post's edge, and the root is charged for it: 3.1 mm of arm
there instead of 3.6.

## Where the stress goes

All of it goes to one corner, and it is not the one it looks like. The arms are
pushed **outward** by the post, so at the root the tension face is the one
*opposite* the load — the inner, cavity-facing surface, which now turns round
the relief slot's radius, `relief_r`. The external corners are on the
compression side, and a convex corner concentrates nothing, so rounding those
buys no strength at all.

**Thickening the arm is not the alternative**, and the reason is worth keeping
in mind for any printed spring: this one is *deflection*-controlled, not
force-controlled. The post imposes the deflection, so σ = E·3tδ/(2L²) rises
with `t` — a thicker arm carries *more* root stress, not less, while also
needing more force to fit. The levers are the root radius, a longer arm, or
less interference.

Peak stress while fitting is 18 MPa, 2.7× on yield. The number worth watching
is the **sustained** one — 9 MPa sits at the root for as long as the clip is on
the post, and PETG creeps. `springcheck.py` fails above 22 MPa; the cable tie is
the fix if a particular clip ever goes slack.

## The one idea the whole model rests on

**Print Z is the post's own axis.** Everything that wraps the post — arms, grip
lands, relief slots, snap lips, cam faces, lead-in ramps, thumb tabs, tie slots
— lies in the (x, y) plane and is therefore a prism along print Z, support-free
whatever shape it is. The undercut that normally makes a snap-fit unprintable
runs sideways here, not up, so it costs nothing.

There is no orientation in which a C that wraps a post and a hook that curls up
are *both* prisms, so the hook pays instead: its underside is a 50° slope and
its upturn leans 20° from vertical. Both are inside the printer's limit, which
is why `make check` reports zero unsupported material on every part.

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

1. Offer the clip up to the post and press. The lead-in ramps spread the arms;
   about 2 kgf, two thumbs, and it clicks over the corners.
2. Optionally, the cable tie — below.
3. To remove: squeeze the two thumb tabs outward and lift it off. Pulling it
   straight off takes ~12 kgf — deliberately, so that a load can't do it.

### The cable tie (optional)

There is a 5.4 × 2.2 mm slot through each lip for a 4.8 mm nylon tie, for a
heavier load, a slippery post finish, or a clip that has taken a set after a
year outdoors.

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
three questions nothing else can:

- **Does it grip?** The arm spring as a cantilever whose root rotates with the
  back wall — stiffness where the grip lands actually bear, friction from the
  lands and from the load's own moment, the tie tension needed for 2×,
  insertion force, and the peak and sustained root stress at the relieved
  root. All from `params.scad`, so the numbers cannot go stale.
- **Does the load open the lips?** The moment presses the lip tops into the
  post's corners, and the cam face turns part of that into outward push on the
  arms. Checked against the catch that is actually left, with a 2× factor for
  the load being hung on rather than set down.
- **Does the lip actually catch?** Rendered, not computed, and as a *pair*: the
  lips are placed where they sit once the arms are sprung, then pulled 1 mm off
  the post and intersected with it.

That last one exists because this model got the lip wrong three times, and
every other check passed each time:

- The catch was quoted as `lip_reach - preload`, when the spring had nothing to
  do with it.
- **The post's corners were modelled rounded.** A square retention face 0.5 mm
  in front of the nominal front face met a post only 18.7 mm half-wide at that
  depth, not 20. The lip caught 0.3 mm over a 0.7 mm strip and would have slid
  off in the hand. The fix was to shape the lip as a cam tangent to the corner.
- When the grip lands replaced the pads, the cam was drawn tangent with the
  arms at rest. The lands spread them 0.76 mm, which carried the cam 0.4 mm
  clear of the corner: rattle, and a lip that had to be pulled that far before
  it bit. The pull test read 19 mm³ where 30 is the floor. The cam is now drawn
  tangent with the arms seated.

The pull test is a `pull` distance and not an overlap-at-rest for the reason
`CLAUDE.md` gives: a clearance fit passes a boolean interference check by
missing entirely. Here it is sharper still — the cam is *tangent* to the corner,
so zero overlap at rest is the correct answer, and a "must be zero" test would
pass just as happily on a lip that missed the post by a mile. The only way to
test a catch is to move the part until it fouls.

## Numbers

From `make check`, on the default 40 × 40 post:

```
arm spring   3.6 x 36 mm, 41.1 mm free, back wall -> 9.1 N/mm at the TIP
                                                     (wall is 24% of it)
grip lands   bear 0.60 along the arm, 0.4 mm     ->  15 N a side, 7 N friction
catch        lands spread the tip 0.76 mm        ->  1.24 mm left of 2.0
grip         7 N lands + 7 N from the moment     ->  1.5x on 1 kg, no tie
tie          5 N of tension reaches 2x           ->  5.6x at a 40 N hand pull
fitting      2.0 mm of spread, 30 deg lead-in    ->  2.2 kgf of push
lips         25 deg face, load hung on           ->  open 0.53 of 1.24 mm (2.3x)
removal      tabs 2.3 kgf; straight pull         ->  11.9 kgf
strain       0.65% peak while fitting, 0.32% sustained  (PETG yields ~2.5%)
root stress  relief r1.5 on 3.1 mm, Kt 1.40  ->  18 MPa peak, 2.7x on yield
                                                  9 MPa sustained
catch test   ~0 mm^3 at rest (tangent), 56 mm^3 pulled 1 mm off

All of it assumes the part prints to size — that is what fit_adjust is for.
```

## Reading the assembly render

The part is modelled **unsprung**, because that is what gets printed. Drawn that
way against the post, the grip lands read as buried 0.4 mm in it — which is the
interference, not a mistake: on a real post the arms flex out and carry the
lands with them.

So `show_seated` (on by default) shears each arm to where it actually sits —
linear in y from the back wall, reaching the grip lands' tip spread at
`arm_free`. A straight line is not the cantilever's curve, but it is near enough
for a picture. Set it false to see the part as printed.

## Fitting a different post

`post_w` is the axis the arms grip; tolerance there moves the grip lands'
squeeze up or down. `post_d` is the axis the cams capture, and the cams make it
elastic: a deeper post just springs the arms a little further.

**`post_corner_r` is asymmetric.** The lips' cam faces are shaped tangent to it,
and designing for `r_design` against a post that really has `r_actual` clears
the corner *iff* `r_actual >= r_design`, since both the tangent constant and the
arc's centre move with `r`. So:

- post **rounder** than designed → a little slack, which the arms close up;
- post **squarer** than designed → the cam drives into the corner and the clip
  will not seat without permanently spreading the arms.

One is a nuisance, the other is a part that does not fit. Set it to the
*smallest* radius the post might have. It was 3 here — a plausible figure for
rolled steel tube — while the actual posts are square, which would have jammed
both lips by 0.8 mm. It is now 0.

And set `fit_adjust` from the calibration ladder, not from a guess: it is the
printer's error, not the post's.
