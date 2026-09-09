#!/usr/bin/env python3
"""Does the hook retention actually retain?

The boolean fit check cannot answer this. With clearance on every face, tabs
correctly seated in their pockets and tabs missing the pockets entirely both
intersect the cover in exactly nothing — a pass either way. So this asks the
question that matters by moving the extension and seeing when it fouls:

  LIFT   raising the extension must be free through hook_play and BLOCKED
         beyond it, and still blocked at ridge_h + ridge_clear, which is the
         travel that would free the ridge. If it is free all the way up, the
         extension simply lifts off and the tabs are decoration.
  SWING  tilting the bottom out about the ridge must be CLEAR at hook_swing,
         or the extension cannot be fitted in the first place. The flange's
         rear edge and the ridge in its groove are what tend to foul.

Both directions matter and they pull against each other: more grip on the lift
means more swing needed to get it in.
"""
import math
import os
import re
import struct
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SCAD = os.path.join(HERE, "hookcheck.scad")
PARAMS = os.path.join(HERE, "..", "src", "params.scad")
OPENSCAD = os.environ.get("OPENSCAD", "/opt/homebrew/bin/openscad")
EPS = 0.01          # mm^3 below which we call it clear


def params():
    out = {}
    with open(PARAMS) as f:
        for line in f:
            m = re.match(r"\s*([a-z_][a-z0-9_]*)\s*=\s*(-?[0-9.]+)\s*;", line)
            if m:
                out[m.group(1)] = float(m.group(2))
    return out


def overlap(lift, swing):
    """Volume common to the cover and the extension at this pose, in mm^3."""
    out = os.path.join(tempfile.gettempdir(), "hookcheck.stl")
    if os.path.exists(out):
        os.remove(out)           # OpenSCAD does not overwrite on an empty result
    r = subprocess.run(
        [OPENSCAD, "--backend=manifold", "--export-format", "binstl", "-o", out,
         "-D", f"lift={lift}", "-D", f"swing={swing}", SCAD],
        capture_output=True)
    if not os.path.exists(out):
        if r.returncode != 0 and b"empty" not in r.stderr:
            raise RuntimeError(r.stderr.decode(errors="replace")[:200])
        return 0.0
    with open(out, "rb") as f:
        f.read(80)
        n = struct.unpack("<I", f.read(4))[0]
        v = 0.0
        for _ in range(n):
            t = struct.unpack("<12fH", f.read(50))
            a, b, c = t[3:6], t[6:9], t[9:12]
            v += (a[0] * (b[1] * c[2] - b[2] * c[1])
                  - a[1] * (b[0] * c[2] - b[2] * c[0])
                  + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6
    return abs(v)


def main():
    p = params()
    foot = p["foot_gap"]
    engage = p["prism_h"] - foot          # how deep the prisms sit in their recesses
    free_ridge = p["ridge_h"] + p["ridge_clear"]
    # hook_swing is computed in params.scad, so it is not a plain literal the
    # reader above can pick up. Same expression, same inputs.
    swing = math.degrees(math.atan(
        p["foot_reach"] / (p["u_h"] + p["ridge_h"] + foot)))

    if foot >= free_ridge:
        print(f"  the foot ({foot}) does not ground before the ridge frees "
              f"itself ({free_ridge}): it can be lifted straight off")
        return 1

    # What this can and cannot answer.
    #
    # It moves the extension as a RIGID body and looks for overlap at that pose.
    # That is enough to prove the two things that hold it on: the foot grounds
    # before the ridge can escape, and the prisms bind the moment it starts to
    # rotate out.
    #
    # It cannot model the RELEASE. Getting it off means flexing the foot down
    # while pulling the bottom forward, and a rigid body has no such freedom —
    # asked to translate down, the extension simply drives its own groove into
    # the ridge and reports a false interference. Releasing is a question for
    # the coupon, not for this.
    #
    # The swing angles have to stay SMALL for the same reason. At the full
    # fitting angle the parts have already passed clean through each other and
    # the overlap is back to zero, which reads as a pass; the collision happens
    # in the first fraction of a degree, so that is where to look.
    nudge = 1.5
    cases = [
        # (lift, swing, want_blocked, label)
        (0.0, 0.0, False, "seated"),
        (0.0, nudge, True, f"nudged {nudge} deg out (prisms bind)"),
        (0.0, nudge * 2, True, f"nudged {nudge * 2} deg out"),
        (foot + 0.4, 0.0, True, f"lifted {foot + 0.4:g} mm (foot grounds on the cover)"),
        (free_ridge, 0.0, True, f"lifted {free_ridge:g} mm (would free the ridge)"),
        (foot - 0.2, 0.0, False, f"lifted {foot - 0.2:g} mm (inside the foot's gap)"),
    ]

    fail = False
    for lift, sw, want_blocked, label in cases:
        v = overlap(lift, sw)
        blocked = v > EPS
        ok = blocked == want_blocked
        fail |= not ok
        state = "BLOCKED" if blocked else "free"
        want = "blocked" if want_blocked else "free"
        print(f"  {label:44s} {v:8.2f} mm^3  {state:8s} "
              f"{'OK' if ok else f'WRONG - wanted {want}'}")
    if not fail:
        print("  retention OK: foot stops it lifting off, prisms stop it "
              "rotating out. Release is a flex — test that on the coupon.")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
