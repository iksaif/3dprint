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

There is no TPU any more — one part, one material.

## Print the calibration ladder first — `make calib`

`build/plates/calib.3mf`: three 6 mm slices of the collar, engraved `0.1`,
`0.2`, `0.3`. Each is drawn bigger by that much per side (`fit_adjust`). The
first ladder (0 … 0.8) put the answer near 0.2; this one brackets it, with the
corner relief and the grip lands now in. Same settings as the clips, a few
minutes each.

A slice fits the post exactly as the full clip does — the collar is a prism
along print Z, so lips, cams, grip lands and cavity are all there. What it
doesn't have is the clip's force: at 6 mm tall it springs ~6× more easily, so
judge the *fit*, not the effort.

**Try each one on the post and note which is which:**

- won't go on
- goes on, and you can feel the grip lands squeeze just behind the lips
- goes on loose: no squeeze at all, it rattles side to side

The one we want squeezes: it clicks over the corners, then holds on the lands.
Also look at the back corners — the post's square corners should sit in the
relief slots without touching.

Then, with calipers, on that slice, at mid-height:

1. **Across the grip lands** (the narrowest point between the arms, just
   behind the lips). Design value: 39.2 + 2 × `fit_adjust` — 39.6 on the `0.2`
   slice, 0.4 a side tighter than the post, which is the squeeze.
2. **Between the arms behind the lands.** Design value: 40.2 + 2 × `fit_adjust`.
3. **The mouth between the two lip crests.** Design value: 36.0 + 2 ×
   `fit_adjust`.

`fit_adjust` gets set once in `params.scad`, and everything — cavity, lands,
lips, cams, back wall, the checks — follows it.

## Then `test.3mf`

One `clip_m`. Push it on, hang the helmet, and see whether it stays without the
tie — the model says it should, by 1.5×, on a pessimistic friction figure. Then
add a tie and see that it does not move at all.

## Measure — the model assumes perfect dimensions unless told otherwise

Printed cavities come out undersize, the first layers pinch in (elephant's
foot), and posts are rarely exactly 40.00. `make check` echoes the drawn values
under "derived dimensions" if a parameter changes. Measure at mid-height, not
at the bottom edge, where elephant's foot reads small.
