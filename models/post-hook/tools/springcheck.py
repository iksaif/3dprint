#!/usr/bin/env python3
"""The questions that decide whether this clip works, none of which any other
check in the repo can ask.

1. DOES IT GRIP?  Nothing here is bolted. The clip stays put on three things:
   the grip lands near the front of each arm squeezing the post, the load's
   own moment pressing the back wall and the lips into it, and — when fitted —
   a cable tie pulling the arms in. Those are forces, and no boolean or mesh
   check computes a force. The first two are reported as the no-tie margin;
   the tie is reported as the tension it needs to bring the total to 2x.

2. DOES THE LIP ACTUALLY CATCH?  This is the trap CLAUDE.md names: a clearance
   fit passes a boolean interference check BY MISSING ENTIRELY, because
   correctly-engaged and completely-disengaged both intersect in zero volume.
   Worse, the grip lands spread the arms once seated, which carries the lips
   outward — so this measures the overlap with the lips MOVED to where they
   sit in use, and requires it to be large.

3. DOES THE LOAD OPEN THE LIPS?  The load's moment presses the lip tops into
   the post's corners, and the cam face turns part of that into outward push
   on the arms. With a 45 deg face a dropped-on helmet would have popped them.
   Checked with a dynamic factor, against the catch that is actually left once
   the grip lands have spread the tip.

The spring model is a cantilever of length arm_free, section collar_h x arm_t,
whose root is allowed to rotate as the back wall bends under the arms' moments.
That rotation is about a quarter of the compliance. An earlier version left it
out and claimed the back wall stiffened the arm, which had the sign backwards:
it overstated every force by ~25%. What is still left out — the stiff lip at
the tip — does stiffen it, somewhat, which is why the insertion figure is
quoted as "at least".
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
        # OpenSCAD exits non-zero on an empty top-level object, which for the
        # tangent-at-rest case is the CORRECT answer, not a broken render.
        if "top level object is empty" in r.stderr:
            return 0.0
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
    lip_catch, grip = p["lip_catch"], p["grip"]
    # The DRAWN post, as params.scad builds the geometry around it — see
    # fit_adjust. Leaving this at the measured post would check a different clip
    # from the one being printed as soon as a correction was set.
    post_w = p["post_w"] + 2 * p.get("fit_adjust", 0)
    post_d = p["post_d"] + 2 * p.get("fit_adjust", 0)
    r = p["post_corner_r"]
    load = p["load_kg"] * G
    mu = p["mu_petg"]

    # Rederived exactly as params.scad does, and only from literals — anything
    # that file computes is recomputed here rather than scraped, because the
    # scraper only sees plain numbers and would silently miss an expression.
    lip_reach = p["arm_clear"] + lip_catch
    hw_in = post_w / 2 + p["arm_clear"]
    y_back_in = -(post_d / 2 + p["back_clear"])
    cam = math.radians(p["lip_cam"])
    cam_c = ((post_w / 2 - r) * math.sin(cam) + (post_d / 2 - r) * math.cos(cam)
             + r + p["lip_clear"])
    spread_peak = post_w / 2 - (hw_in - lip_reach)

    # ---- the spring, including the back wall ------------------------------
    # The arm is NOT a cantilever off a rigid root. It is rooted in a 6 mm back
    # wall spanning the post, and the arms load that wall with F*L moments at
    # each end, so the roots rotate too. That is about a quarter of the whole
    # compliance.
    #
    # Deflection per newton, for a force at distance a along the arm, at a
    # point x along it (x >= a for the tip):
    #   arm bending   a^2 (3x - a) / (6 E I_arm)
    #   root rotation (F a) b / (2 E I_wall), times x
    Ia = h * arm_t ** 3 / 12
    Ib = h * p["back_t"] ** 3 / 12
    b = 2 * hw_in                            # back wall span between the roots

    def comp(a, x):
        """Deflection at x per newton applied at a (x >= a)."""
        return a * a * (3 * x - a) / (6 * E * Ia) + a * b * x / (2 * E * Ib)

    # The cam is drawn tangent with the arms SEATED — spread by the grip lands
    # — so its position needs the spring first. params.scad takes the arm
    # length for that at rest, to break the circle; so does this.
    grip_y1 = post_d / 2 - p["grip_front"]
    grip_y0 = grip_y1 - p["grip_len"]
    a_land = grip_y0 - y_back_in
    free_rest = ((cam_c - hw_in * math.sin(cam)) / math.cos(cam)
                 + lip_reach / 2 - y_back_in)
    grip_tip = grip * comp(a_land, free_rest) / comp(a_land, a_land)
    y_cam_start = (cam_c - (hw_in + grip_tip) * math.sin(cam)) / math.cos(cam)
    arm_free = y_cam_start + lip_reach / 2 - y_back_in

    L = arm_free
    k_rigid = 3 * E * Ia / L ** 3
    k = 1 / comp(L, L)                       # real tip stiffness, per arm
    print(f"  arm spring: {arm_t} x {h} mm section, {L:.1f} mm free -> "
          f"{k:.1f} N/mm at the tip  ({k_rigid:.1f} if the back wall were rigid; "
          f"the wall is {1 - k / k_rigid:.0%} of the compliance)")

    # ---- 1. grip -----------------------------------------------------------
    # Three sources, reported separately because only the first two are always
    # there.
    #
    #   lands    the grip lands pushing the post, `grip` proud of the arm near
    #            its front. Load-independent: this is what holds the clip in
    #            place with nothing on it.
    #   moment   the load's own couple. It presses the back wall and the lips
    #            into the post, and that normal force is proportional to the
    #            load — so this term is self-energising, and its MARGIN is
    #            roughly constant whatever you hang on it.
    #   tie      a cable tie through the lips, closed behind the tabs.
    #
    # The arm bends, so a land does not sit flat on the post: its BACK end
    # bears and the front lifts off. That is where the force acts, and the arm
    # is much stiffer there than at the tip — k / r^3 — which is the whole
    # reason the lands are short and forward. At the root they would jam.
    r_land = a_land / L
    k_land = 1 / comp(a_land, a_land)
    normal = k_land * grip
    f_lands = 2 * normal * mu
    # The TIP moves further than the land does — and the tip is where the lip
    # is. So seated, the lip is carried outward, and the catch it keeps is
    # less than lip_catch says.
    tip_spread = normal * comp(a_land, L)
    catch = lip_catch - tip_spread
    print(f"  grip lands bear {r_land:.2f} of the way along the arm, where it is "
          f"{k_land:.1f} N/mm, not the tip's {k:.1f}")
    print(f"        {grip} mm of interference -> {normal:.0f} N per side, "
          f"{f_lands:.0f} N of friction; the tip spreads {tip_spread:.2f} mm, "
          f"leaving {catch:.2f} of the {lip_catch} mm catch")

    # The load sits mid-cradle on whichever hook is fitted; the deepest one is
    # the worst case. Read from the size table rather than restated, so a new
    # row cannot quietly invalidate this.
    rows = re.findall(r'\["\w+",\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+)\]',
                      open(os.path.join(HERE, "..", "src", "params.scad")).read())
    load_arm = max((float(r[0]) - p["tip_t"]) / 2 for r in rows)
    a = post_d / 2 + p["back_clear"] + p["back_t"] + load_arm
    couple = p["couple_frac"] * h
    f_couple = load * a / couple
    f_moment = f_couple * 2 * mu

    no_tie = f_lands + f_moment
    margin = no_tie / load
    print(f"        the load's own moment adds {f_couple:.0f} N at each contact "
          f"({a:.0f} mm arm over a {couple:.0f} mm couple) -> {f_moment:.0f} N more")
    print(f"        without the tie: {no_tie:.0f} N against a {p['load_kg']} kg "
          f"({load:.1f} N) load = {margin:.1f}x")

    # The tie loop runs across the post's front face and back over the two
    # tabs. Pulled to T, it presses the post onto the back wall with ~2T and
    # squeezes each arm onto the post with ~T: 4T of normal force, all of it
    # on PETG-on-steel.
    need = max(2 * load - no_tie, 0) / (4 * mu)
    print(f"        with the tie: 2x needs {need:.0f} N of tie tension; a hand "
          f"pull is ~{p['tie_hand_n']:.0f} N, which makes it "
          f"{(no_tie + 4 * mu * p['tie_hand_n']) / load:.1f}x")
    if need > p["tie_hand_n"]:
        fails.append(f"reaching 2x needs {need:.0f} N of tie tension, more than a "
                     f"hand pull's {p['tie_hand_n']:.0f}")
    if margin < 1.0:
        print(f"        NOTE: under 1x without the tie — the tie is not optional")

    # ---- 2. what it costs to get it on and off -----------------------------
    # Peak spread is when the lip's crest rides over the post's side face. By
    # then the tip is out lip_catch, and the lands, further back, are out
    # grip_shape of that — clear of the post, so they add nothing to the peak.
    lat = k * spread_peak
    axial = 2 * lat * math.tan(math.radians(p["lead_angle"]))
    print(f"  fitting: tip spreads {spread_peak:.2f} mm ({lat:.0f} N lateral per arm); "
          f"over the {p['lead_angle']:.0f} deg lead-in that is at least "
          f"{axial:.0f} N ({axial / G:.1f} kgf) of push")
    if axial / G > 15:
        fails.append(f"insertion force {axial / G:.1f} kgf is too high to press on by hand")

    # ---- 2b. does the LOAD open the lips? ----------------------------------
    # The load's moment is reacted as a couple: back wall at the bottom, lips
    # at the TOP, where they are pressed into the post's front corners with
    # f_couple between them. The cam face turns that into outward push on the
    # arm tip in the ratio tan(lip_cam - friction angle). If the tip opens by
    # the catch, the lip rides over the corner and nothing holds the clip on.
    #
    # Two things make it worse than the plain tip stiffness suggests: the push
    # lands at the TOP corner of a 36 mm tall arm, not along its whole edge
    # (CORNER — an estimate, and the softest number in this file), and hanging
    # a load on a hook is not a static load (DYNAMIC).
    CORNER, DYNAMIC = 0.6, 2.0
    phi = math.atan(mu)
    ratio = max(math.tan(cam - phi), 0.0)
    push = ratio * f_couple / 2              # per lip
    opens = push / (CORNER * k)
    print(f"  holding on: the load presses each lip into its corner with "
          f"{f_couple / 2:.1f} N; a {p['lip_cam']:.0f} deg face turns {ratio:.2f} of "
          f"that into outward push")
    print(f"        the top of each arm opens {opens:.2f} mm static, "
          f"{opens * DYNAMIC:.2f} hanging it on, of {catch:.2f} mm of catch  "
          f"({catch / (opens * DYNAMIC) if opens else float('inf'):.1f}x)")
    if opens * DYNAMIC > 0.7 * catch:
        fails.append(f"hanging the load opens the lips {opens * DYNAMIC:.2f} mm of "
                     f"{catch:.2f} — steepen lip_cam")
    # Straight pull, for information. Removal is by squeezing the tabs; a steep
    # face makes this deliberately large.
    pull_ratio = max(math.tan(cam - phi), 0.05)
    pull_off = 2 * k * catch / pull_ratio
    print(f"        straight pull to remove: {pull_off:.0f} N "
          f"({pull_off / G:.1f} kgf) — squeeze the tabs instead, "
          f"{2 * k * catch:.0f} N between them")

    # ---- 3. strain ---------------------------------------------------------
    # Peak is momentary, during insertion; sustained is what sits there for
    # years and is the one creep cares about. From the root MOMENT, not the
    # rigid-root strain formula: the back wall takes a share of the deflection.
    # At the ROOT section, which relief_off has thinned: the moment there is
    # the same, the section modulus goes as t^2.
    t_root = arm_t - p["relief_off"]
    sect = h * t_root ** 2 / 6
    peak = k * spread_peak * L / sect / E
    sustained = normal * a_land / sect / E
    print(f"  strain: {peak * 100:.2f}% peak while fitting, "
          f"{sustained * 100:.2f}% sustained once on  (PETG yields around 2.5%)")
    if peak > 0.020:
        fails.append(f"peak strain {peak * 100:.2f}% is over 2.0%")
    if sustained > 0.010:
        fails.append(f"sustained strain {sustained * 100:.2f}% will creep")

    # ---- 3b. root stress, where the arm meets the back wall ----------------
    # The arms are pushed OUTWARD, so the tension face at the root is the inner,
    # cavity-facing one. With the corner relief, that face no longer turns the
    # fillet: it runs straight down into the relief slot and turns round its
    # radius, relief_r, which is what sets Kt now.
    #
    # Kt is the standard stepped-bar-in-bending concentration, fitted from the
    # published charts. Approximate, and deliberately on the conservative side:
    # it is here to show whether the margin is 1.2 or 2, not to be exact.
    r_root = p["relief_r"]
    kt = 1 + 0.27 * (r_root / t_root) ** -0.55
    s_peak = E * peak * kt
    s_sus = E * sustained * kt
    yld = p["petg_yield_mpa"]
    print(f"  root stress: relief r{r_root} on the root's {t_root} mm "
          f"({arm_t} less relief_off) is r/t "
          f"{r_root / t_root:.2f}, Kt {kt:.2f} -> {s_peak:.0f} MPa peak while "
          f"fitting ({yld / s_peak:.2f}x on yield), {s_sus:.0f} MPa sustained")
    if s_peak > yld / 1.3:
        fails.append(f"peak root stress {s_peak:.0f} MPa leaves under 1.3x on "
                     f"a {yld:.0f} MPa yield — open up relief_r")
    if s_sus > 22:
        fails.append(f"sustained root stress {s_sus:.0f} MPa will creep the "
                     f"grip away over months")

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
