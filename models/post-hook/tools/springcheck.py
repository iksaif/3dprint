#!/usr/bin/env python3
"""The two questions that decide whether this clip works, neither of which any
other check in the repo can ask.

1. DOES IT GRIP?  Nothing here is bolted. The clip stays put because the post
   springs the two arms open and the friction of the TPU liner against the post
   exceeds the load. That is a force, and no boolean or mesh check computes a
   force. It is also the number that has to be traded against the two things
   working directly against it — the effort of pushing the clip on, and the
   strain in the arm while you do — so all three are reported together.

2. DOES THE LIP ACTUALLY CATCH?  This is the trap CLAUDE.md names: a clearance
   fit passes a boolean interference check BY MISSING ENTIRELY, because
   correctly-engaged and completely-disengaged both intersect in zero volume.
   The lip is worse than that: unloaded it overlaps the post by lip_reach and
   looks fine, but the arms are sprung open by preload when the clip is seated,
   which carries the lips outward by the same amount. Size the lip to the catch
   you want and forget the spring and you get a lip that is exactly flush and
   slides off. So this measures the overlap with the lips MOVED to where they
   sit in use, and requires it to be large.

The spring model is a cantilever of length arm_free, section collar_h x arm_t,
rooted at the back wall's inner face. It is deliberately the simple one, and it
reads LOW by maybe 20-30%: the real arm has a fillet at the root, a stiff lip at
the tip, and gets help from the back wall, all of which stiffen it. Reading low
is the safe direction for the grip margin and the wrong one for the insertion
force, which is why the insertion figure is quoted as "at least".
"""
import math
import os
import re
import struct
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
OPENSCAD = os.environ.get("OPENSCAD", "/opt/homebrew/bin/openscad")
G = 9.81


def params():
    """Plain `name = number;` assignments out of params.scad and print.scad.

    Only the literals. Anything derived is recomputed here from them, so this
    file cannot quote a number the model does not actually have.
    """
    out = {}
    for path in (os.path.join(HERE, "..", "..", "..", "lib", "scad", "print.scad"),
                 os.path.join(HERE, "..", "src", "params.scad")):
        with open(path) as f:
            for line in f:
                m = re.match(r"\s*([a-z_][a-z0-9_]*)\s*=\s*(-?[0-9.]+)\s*;", line)
                if m:
                    out[m.group(1)] = float(m.group(2))
                    continue
                # Booleans too, so that turning a feature off actually turns it
                # off here. Without this a `= false;` line is simply not seen,
                # and the flag silently keeps whatever default the caller chose.
                m = re.match(r"\s*([a-z_][a-z0-9_]*)\s*=\s*(true|false)\s*;", line)
                if m:
                    out[m.group(1)] = m.group(2) == "true"
    return out


def volume(path):
    """Signed volume by the divergence theorem, summed over the triangles."""
    with open(path, "rb") as f:
        f.read(80)
        n = struct.unpack("<I", f.read(4))[0]
        v = 0.0
        for _ in range(n):
            r = struct.unpack("<12fH", f.read(50))
            a, b, c = r[3:6], r[6:9], r[9:12]
            v += (a[0] * (b[1] * c[2] - b[2] * c[1])
                  - a[1] * (b[0] * c[2] - b[2] * c[0])
                  + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6
    return abs(v)


def render_case(which, **kw):
    """Volume of a fitcheck case. An empty result is 0.0, not an error: OpenSCAD
    writes no file at all when the intersection is empty, and for the pull test
    empty is a meaningful (and failing) answer rather than a broken run."""
    scad = os.path.join(HERE, "fitcheck.scad")
    with tempfile.NamedTemporaryFile(suffix=".stl", delete=False) as t:
        out = t.name
    os.unlink(out)
    cmd = [OPENSCAD, "--backend=manifold", "--export-format", "binstl",
           "-o", out, "-D", f'which="{which}"']
    for k, v in kw.items():
        cmd += ["-D", f"{k}={v}"]
    try:
        r = subprocess.run(cmd + [scad], capture_output=True, text=True)
        if r.returncode != 0:
            print(r.stderr.strip(), file=sys.stderr)
            return None
        if not os.path.exists(out) or os.path.getsize(out) <= 84:
            return 0.0
        return volume(out)
    finally:
        if os.path.exists(out):
            os.unlink(out)


def main():
    p = params()
    fails = []

    arm_t, h, E = p["arm_t"], p["collar_h"], p["petg_e_mpa"]
    preload, lip_reach = p["preload"], p["lip_reach"]
    liner_t, post_w, post_d = p["liner_t"], p["post_w"], p["post_d"]
    r = p["post_corner_r"]
    load = p["load_kg"] * G
    mu = p["mu_tpu"]

    # Rederived exactly as params.scad does, and only from literals — anything
    # that file computes is recomputed here rather than scraped, because the
    # scraper only sees plain numbers and would silently miss an expression.
    hw_in = post_w / 2 + liner_t - preload
    cam_c = post_w / 2 + post_d / 2 - 2 * r + math.sqrt(2) * (r + p["lip_clear"])
    y_cam_start = cam_c - preload - hw_in
    arm_free = y_cam_start + lip_reach / 2 + post_d / 2 + liner_t
    spread_peak = post_w / 2 - (hw_in - lip_reach)
    x_crest_seated = hw_in + preload - lip_reach
    lip_release = post_w / 2 - x_crest_seated

    # The arm is a plain rectangle again. It briefly carried a tie-guide channel
    # down its outer face, which cost 8% of I — small, but worth computing
    # rather than waving at, since this is the number the grip margin rests on.
    # The channel is gone; if one comes back, subtract its strip here.
    I = h * arm_t ** 3 / 12
    k = 3 * E * I / arm_free ** 3          # N/mm at the tip, per arm

    print(f"  arm spring: {arm_t} x {h} mm section, {arm_free:.1f} mm free, "
          f"I = {I:.0f} mm^4 -> {k:.1f} N/mm per arm")

    # ---- 1. grip -----------------------------------------------------------
    normal = k * preload
    friction = 2 * normal * mu
    margin = friction / load
    print(f"  seated: each arm sprung {preload} mm -> {normal:.0f} N normal; "
          f"friction at mu {mu} is {friction:.0f} N against a "
          f"{p['load_kg']} kg ({load:.1f} N) load  = {margin:.1f}x")
    if margin < 2.0:
        fails.append(f"grip margin {margin:.1f}x is under 2x")

    # ---- 2. what it costs to get it on and off -----------------------------
    lat = k * spread_peak
    axial = 2 * lat * math.tan(math.radians(p["lead_angle"]))
    print(f"  fitting: tip spreads {spread_peak} mm ({lat:.0f} N lateral per arm); "
          f"over the {p['lead_angle']:.0f} deg lead-in that is at least "
          f"{axial:.0f} N ({axial / G:.1f} kgf) of push")
    # The cam is at 45 deg, so the force ratio pulling it off is tan(45) = 1 and
    # the pull-off force is simply the force to spread the arms far enough for
    # the crest to clear the post. This is the number the square-faced lip could
    # not have quoted at all, because it had no defined release travel.
    pull_off = 2 * k * lip_release
    print(f"  holding on: {lip_release:.1f} mm of release travel over a "
          f"{p['lip_cam']:.0f} deg cam = {pull_off:.0f} N ({pull_off / G:.1f} kgf) "
          f"of straight pull, or squeeze the thumb tabs and it lifts off")
    if axial / G > 15:
        fails.append(f"insertion force {axial / G:.1f} kgf is too high to press on by hand")
    if pull_off < 3 * load:
        fails.append(f"pull-off {pull_off:.0f} N is under 3x the {load:.0f} N load")

    # ---- 3. strain ---------------------------------------------------------
    # Peak is momentary, during insertion; sustained is what sits there for
    # years and is the one creep cares about.
    peak = 3 * arm_t * spread_peak / (2 * arm_free ** 2)
    sustained = 3 * arm_t * preload / (2 * arm_free ** 2)
    print(f"  strain: {peak * 100:.2f}% peak while fitting, "
          f"{sustained * 100:.2f}% sustained once on  (PETG yields around 2.5%)")
    if peak > 0.020:
        fails.append(f"peak strain {peak * 100:.2f}% is over 2.0%")
    if sustained > 0.010:
        fails.append(f"sustained strain {sustained * 100:.2f}% will creep")

    # ---- 4. does the lip actually catch? -----------------------------------
    # Rendered, not computed, and as a PAIR. The cam face is tangent to the
    # post's corner, so at rest the two just touch and the overlap is genuinely
    # zero — a "must be zero" test passes on that and would pass just as
    # happily on a lip that missed the post by a mile. The question is only
    # answerable by moving the clip until it fouls.
    rest = render_case("catch", pull=0)
    v = render_case("catch", pull=1.0)
    if rest is None or v is None:
        fails.append("could not render the seated-lip case")
    else:
        print(f"  catch: at rest the cam face just touches ({rest:.1f} mm^3); "
              f"pulled 1.0 mm off, it drives {v:.0f} mm^3 into the post's corner")
        if rest > 20:
            fails.append(f"{rest:.0f} mm^3 of interference at rest — the clip "
                         f"will not seat without forcing")
        if v < 30:
            fails.append(f"pulling 1 mm off only fouls {v:.0f} mm^3: the lip is "
                         f"not reaching the post, it is catching air")

    for f in fails:
        print(f"  FAIL: {f}")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
