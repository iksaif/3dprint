#!/usr/bin/env bash
# Review renders. Not part of verification — `make check` does that. These exist
# so the design can be looked at, which is the only way to catch the problems
# that are about proportion rather than about numbers.
set -euo pipefail
cd "$(dirname "$0")"
OS=/opt/homebrew/bin/openscad
R=build/renders
mkdir -p "$R"

png() { # name, then any -D / --camera options. Frames the whole model.
  local name=$1; shift
  $OS --hardwarnings --backend=manifold --render=1 -o "$R/$name.png" \
      --imgsize=1200,900 --colorscheme=Tomorrow --viewall --autocenter \
      "$@" src/main.scad >/dev/null
}

# Same, but WITHOUT --viewall/--autocenter, so the --camera you pass is actually
# the camera you get. Use it for close-ups on a feature; png() would zoom back
# out to frame the whole part and silently ignore the position you asked for.
pngat() {
  local name=$1; shift
  $OS --hardwarnings --backend=manifold --render=1 -o "$R/$name.png" \
      --imgsize=1200,900 --colorscheme=Tomorrow "$@" src/main.scad >/dev/null
}

echo "== assembly"
png asm_iso    --camera=0,0,0,62,0,32,600
png asm_rear   --camera=0,0,0,62,0,205,600
png asm_side   --camera=0,0,0,90,0,90,600
png asm_front  --camera=0,0,0,90,0,0,600
png asm_top    --camera=0,0,0,0,0,0,600

echo "== sections"
# through the clamp screws: heads flush in the cover, nuts buried in the arms
png sec_screws --camera=0,0,0,0,0,0,600 -D 'cutaway="z"' -D "cut_at=$((40 / 2))"
# up the lock screw's axis: bottom counterbore, through the ridge, into the nut.
# Viewed from the SIDE — the screw, the ridge and the groove all lie in the Y-Z
# plane, so a front camera shows the whole joint edge-on and tells you nothing.
png sec_lock   --camera=0,0,0,90,0,90,600 -D 'cutaway="x"' -D 'cut_at=0' \
               -D 'show_post=false'
# the pads seated in their pockets
png sec_pads   --camera=0,0,0,0,0,0,600 -D 'cutaway="z"' -D 'cut_at=20' \
               -D 'show_ext="none"'

echo "== the adjustment range"
for d in 38 42; do
  png "asm_post$d" --camera=0,0,0,0,0,0,600 -D 'cutaway="z"' -D 'cut_at=20' -D "post_d=$d"
done

echo "== the interface, close up"
# the ridge standing on the cover's finished top face
png ridge_iso --camera=0,0,0,55,0,25,300 -D 'part="cover"' -D 'ext_orient="install"'
# a slice through the snap bump: leaf, bump and the extension's groove
png snap_sec  --camera=0,0,0,0,0,0,400 -D 'cutaway="z"' -D 'cut_at=8' -D 'show_post=false'
# the ridge sitting in the flange's groove, close in on the cover's top edge
pngat joint_sec --camera=0,45,42,90,0,90,90 -D 'cutaway="x"' -D 'cut_at=0' \
                -D 'show_post=false'

echo "== parts"
for p in u_bracket cover pad pad_arm; do
  png "${p}_iso" --camera=0,0,0,60,0,25,500 -D "part=\"$p\""
done

echo "== extensions"
for e in ext_helmet ext_strap ext_lock ext_shelf; do
  # installed orientation, so the profile reads against the plate it hangs off
  png "${e}_side" --camera=0,0,0,90,0,90,400 -D "part=\"$e\"" \
                  -D 'ext_orient="install"' -D 'cutaway="x"' -D 'cut_at=0'
  png "${e}_iso"  --camera=0,0,0,60,0,210,400 -D "part=\"$e\"" -D 'ext_orient="install"'
  png "asm_$e"    --camera=0,0,0,62,0,32,600  -D "show_ext=\"$e\""
done

echo "renders in $R"
