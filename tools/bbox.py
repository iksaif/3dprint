#!/usr/bin/env python3
"""Print the bounding box of binary STL files and flag anything over the bed.

The MIN corner is printed as well as the size, because a plate file has to place
parts by it: OpenSCAD cannot measure a child, so plates.scad carries the minimum
corners as constants and shifts each part by its own. Those constants used to say
"re-read them from make check" while make check printed only sizes.
"""
import struct, sys
BED = (250, 210, 220)   # Prusa MK4S usable build volume
for path in sys.argv[1:]:
    with open(path, 'rb') as f:
        f.read(80); n = struct.unpack('<I', f.read(4))[0]
        mn = [1e9]*3; mx = [-1e9]*3; vol = 0.0
        for _ in range(n):
            rec = struct.unpack('<12fH', f.read(50))
            a0, a1, a2 = rec[3:6], rec[6:9], rec[9:12]
            for v in (a0, a1, a2):
                for a in range(3):
                    mn[a] = min(mn[a], v[a]); mx[a] = max(mx[a], v[a])
            # signed volume of the tetrahedron (origin, a0, a1, a2)
            vol += (a0[0]*(a1[1]*a2[2]-a1[2]*a2[1]) - a0[1]*(a1[0]*a2[2]-a1[2]*a2[0]) + a0[2]*(a1[0]*a2[1]-a1[1]*a2[0])) / 6.0
    size = [mx[a]-mn[a] for a in range(3)]
    ok = all(size[a] <= BED[a] for a in range(3))
    at = f"[{mn[0]:.1f}, {mn[1]:.1f}, {mn[2]:.1f}]"
    print(f"{path:28s} {size[0]:7.1f} x {size[1]:7.1f} x {size[2]:6.1f} mm  "
          f"{abs(vol)/1000:6.1f} cm3  tris={n:6d}  min {at:22s} "
          f"{'OK' if ok else 'TOO BIG'}")
