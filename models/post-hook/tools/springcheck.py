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
    preload, lip_catch = p["preload"], p["lip_catch"]
    pad_t, post_w, post_d = p["pad_t"], p["post_w"], p["post_d"]
    r = p["post_corner_r"]
    load = p["load_kg"] * G
    mu = p["mu_tpu"]

    # Rederived exactly as params.scad does, and only from literals — anything
    # that file computes is recomputed here rather than scraped, because the
    # scraper only sees plain numbers and would silently miss an expression.
    lip_reach = pad_t + lip_catch
    hw_in = post_w / 2 + pad_t - preload
    cam_c = post_w / 2 + post_d / 2 - 2 * r + math.sqrt(2) * (r + p["lip_clear"])
    y_cam_start = cam_c - preload - hw_in
    arm_free = y_cam_start + lip_reach / 2 + post_d / 2 + pad_t
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
    # TWO sources, and getting this wrong by leaving the second one out is what
    # broke the first print: the preload was sized to carry the load on friction
    # alone, which needed 2.5 mm of interference per arm.
    #
    #   preload  the arms squeezing the pads onto the post. Load-independent.
    #   moment   the load's own couple. It presses the back pad and the lips
    #            into the post, and that normal force is proportional to the
    #            load — so this term is self-energising, and its MARGIN is
    #            roughly constant whatever you hang on it.
    #
    # The second is the larger of the two and was excluded as "conservative".
    # It is not conservative to leave out the mechanism doing most of the work;
    # it just moves the error into the parameter that compensates.
    normal = k * preload
    f_preload = 2 * normal * mu

    # The load sits mid-cradle on whichever hook is fitted; the deepest one is
    # the worst case. Read from the size table rather than restated, so a new
    # row cannot quietly invalidate this.
    rows = re.findall(r'\["\w+",\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+)\]',
                      open(os.path.join(HERE, "..", "src", "params.scad")).read())
    load_arm = max((float(r[0]) - p["tip_t"]) / 2 for r in rows)
    a = post_d / 2 + pad_t + p["back_t"] + load_arm
    couple = p["couple_frac"] * h
    f_couple = load * a / couple
    f_moment = f_couple * (mu + p["mu_petg"])

    friction = f_preload + f_moment
    margin = friction / load
    print(f"  grip: {preload} mm of preload per arm -> {normal:.0f} N normal, "
          f"{f_preload:.0f} N of friction")
    print(f"        the load's own moment adds {f_couple:.0f} N at each contact "
          f"({a:.0f} mm arm over a {couple:.0f} mm couple) -> {f_moment:.0f} N more")
    print(f"        total {friction:.0f} N against a {p['load_kg']} kg "
          f"({load:.1f} N) load  = {margin:.1f}x")
    if margin < 2.0:
        fails.append(f"grip margin {margin:.1f}x is under 2x")
    if f_preload < 0.4 * f_moment:
        fails.append(f"preload contributes only {f_preload:.0f} N against the "
                     f"moment's {f_moment:.0f} — too little left if the load comes off")

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

    # ---- 3b. root stress, where the arm meets the back wall ----------------
    # The arms are pushed OUTWARD, so the tension face at the root is the inner,
    # cavity-facing one — and that is the corner fillet_r rounds. The outer
    # corners are in compression and concentrate nothing, which is why making
    # them rounder is not the lever it looks like.
    #
    # Kt is the standard stepped-bar-in-bending concentration, fitted from the
    # published charts. Approximate, and deliberately on the conservative side:
    # it is here to show whether the margin is 1.2 or 2, not to be exact.
    #
    # Thickening the arm does not help. This spring is deflection-controlled, so
    # sigma = E * 3 t d / (2 L^2) rises with t — a stiffer arm carries MORE root
    # stress at the same imposed deflection.
    r_fil = p["fillet_r"]
    kt = 1 + 0.27 * (r_fil / arm_t) ** -0.55
    s_sus, s_peak = E * sustained * kt, E * peak * kt
    yld = p["petg_yield_mpa"]
    print(f"  root stress: fillet r{r_fil} on a {arm_t} mm arm is r/t "
          f"{r_fil / arm_t:.2f}, Kt {kt:.2f} -> {s_peak:.0f} MPa peak while "
          f"fitting ({yld / s_peak:.2f}x on yield), {s_sus:.0f} MPa sustained")
    if s_peak > yld / 1.3:
        fails.append(f"peak root stress {s_peak:.0f} MPa leaves under 1.3x on "
                     f"a {yld:.0f} MPa yield — open up fillet_r")
    if s_sus > 22:
        fails.append(f"sustained root stress {s_sus:.0f} MPa will creep the "
                     f"preload away over months")

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
