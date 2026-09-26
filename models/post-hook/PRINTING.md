# Printing post-hook

## Clips — PETG

| Setting | Value | Why |
|---|---|---|
| Layer height | 0.2 mm | what every overhang here is designed against |
| **Perimeters** | **4** | the arms are 3.6 mm = 8 × 0.45; four per side makes them solid edge to edge, with no infill in the spring |
| Supports | none | nothing needs them; `make check` proves it |
| Orientation | as exported | the post's axis is print Z — do not lay it down |

**Perimeters is the one that matters.** At the default 2, each arm prints as
1.8 mm of perimeter around a 1.8 mm sparse core. In bending that core sits at
the neutral axis and costs only ~12% of the stiffness, but the perimeter–infill
boundary is a crack path in a part that flexes every time it goes on.

## Pads — TPU

Flat on the bed, as exported. Six layers, no supports, nothing to orient: both
faces are the same.

## Print `test.3mf` first

One `clip_m` and one set of pads. Everything worth learning is a property of
the whole arm, so no coupon will tell you.

## Then measure — the model assumes perfect dimensions

The model has no tolerance term. Printed cavities come out undersize, the
first layers pinch in (elephant's foot), and posts are rarely exactly 40.00.
One print of the test clip tells you how far off it all is, and these are the
numbers that matter, with calipers:

1. **The post**, both ways: width across the arms' direction, and depth.
2. **Inside the bare clip, between the arms**, near the back wall and again
   just behind the lips. Design value: 41.4 mm.
3. **The mouth between the two lip crests**, at the narrowest point. Design
   value: 36.0 mm.

The first two say whether the clip is sized right; the third says whether the
lips print where they should. `make check` echoes the design values under
"derived dimensions" if a parameter changes.

Measure at mid-height, not at the bottom edge, where elephant's foot reads
small.
