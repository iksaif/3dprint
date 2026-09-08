#!/usr/bin/env bash
# Render one .scad file from several camera angles into PNGs you can then read.
# Usage: scad-preview.sh <file.scad> [outdir] [-- extra openscad args...]
#   e.g. scad-preview.sh part.scad /tmp/prev -- -D 'part_to_render="front_saddle"'
set -euo pipefail

src=${1:?usage: scad-preview.sh <file.scad> [outdir] [-- extra openscad args]}
out=${2:-$(dirname "$src")/preview}
shift $(( $# > 1 ? 2 : 1 ))
[ "${1:-}" = "--" ] && shift
mkdir -p "$out"
base=$(basename "$src" .scad)

# name:rot_x,rot_y,rot_z  -- OpenSCAD Euler angles, dist auto-fit via --viewall
views="iso:55,0,25 front:90,0,0 right:90,0,90 top:0,0,0"

for v in $views; do
  name=${v%%:*}; rot=${v#*:}
  openscad -o "$out/${base}_${name}.png" \
    --imgsize=800,600 --viewall --autocenter \
    --camera=0,0,0,"$rot",0 \
    --colorscheme=Tomorrow \
    "$@" "$src" 2>&1 | grep -Ei 'error|warning' || true
  echo "$out/${base}_${name}.png"
done
