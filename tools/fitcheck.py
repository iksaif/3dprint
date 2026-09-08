#!/usr/bin/env python3
"""Boolean interference between parts that are supposed to mate.

A correct fit leaves only zero-volume contact — a face resting on a face. Any
real overlap becomes a solid with measurable volume. Measuring VOLUME rather
than triangle count is the whole point: coincident faces produce plenty of
triangles and no volume, so a triangle-count test cries wolf on every good fit.

The model supplies a .scad that takes a `which` variable and renders the
intersection for that case, e.g.

    which = "ext";
    if (which == "ext") intersection() { cover(); extension(); }

Usage:
    fitcheck.py --scad tools/fitcheck.scad --cases ext,clamp,pad
    fitcheck.py --scad tools/fitcheck.scad --cases "ext:extension vs cover"

A case may carry a human label after a colon. Exit status is non-zero if any
case shows more than --tolerance mm^3 of overlap.
"""
import argparse
import os
import struct
import subprocess
import sys
import tempfile

OPENSCAD = os.environ.get("OPENSCAD", "/opt/homebrew/bin/openscad")


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
    return n, abs(v)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--scad", required=True, help="the .scad taking a `which` variable")
    ap.add_argument("--cases", required=True,
                    help="comma-separated case[:label] values for `which`")
    ap.add_argument("--tolerance", type=float, default=1.0,
                    help="mm^3 of overlap tolerated (default 1.0)")
    args = ap.parse_args()

    cases = []
    for spec in args.cases.split(","):
        name, _, label = spec.partition(":")
        cases.append((name.strip(), (label or name).strip()))

    width = max(len(label) for _, label in cases) + 2
    fail = False
    for which, label in cases:
        out = os.path.join(tempfile.gettempdir(), f"fit_{which}.stl")
        if os.path.exists(out):
            os.remove(out)
        r = subprocess.run(
            [OPENSCAD, "--backend=manifold", "--export-format", "binstl",
             "-o", out, "-D", f'which="{which}"', args.scad],
            capture_output=True)
        if b"top level object is empty" in r.stderr:
            # nothing at all in common - the cleanest possible pass
            n, v = 0, 0.0
        elif r.returncode != 0 or not os.path.exists(out):
            print(f"{label:{width}s} openscad failed: "
                  f"{r.stderr.decode(errors='replace').strip()[:120]}")
            fail = True
            continue
        else:
            n, v = volume(out)
        ok = v < args.tolerance
        fail |= not ok
        print(f"{label:{width}s} {n:6d} tris  {v:9.4f} mm^3  "
              f"{'OK (contact only)' if ok else 'INTERFERENCE'}")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
