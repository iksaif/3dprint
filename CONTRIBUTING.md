# Contributing

## What you need

- **OpenSCAD with the Manifold backend** — 2023.x or newer, or a nightly. The
  build passes `--backend=manifold`, which the 2021.01 release does not know.
- **Python 3**, standard library only. No venv, no numpy; the checkers are
  deliberately dependency-free.
- **GNU make**.

The Makefiles look for OpenSCAD at `/opt/homebrew/bin/openscad`. Override it:

```bash
make OPENSCAD=/usr/bin/openscad
```

## Build and check

```bash
cd models/charging-dock
make            # STLs, 3MFs, plates, then every check
make check      # just the verification (needs the STLs)
make clean
```

CI runs exactly this for every model on every push, so if `make` is green
locally it will be green there.

## The rules a change has to keep

1. **Every dimension lives in `src/params.scad`.** Nothing hardcoded downstream,
   and anything derivable is derived.
2. **No supports.** A part prints support-free iff, at every layer, its material
   rests on material in the layer below. `tools/support.py` measures this on the
   exported mesh and fails the build. A part may be exempted only via
   `SUPPORT_EXEMPT` in its Makefile, and only when it exists *because* it trades
   support-free printing for a shape the 45° limit will not give.
3. **Render it and look at it.** OpenSCAD code is not verifiable by reading. A
   part compiles cleanly and is completely wrong.
4. **Assert what you believe.** If a wall must stay above `min_wall`, write the
   assert; a broken assumption should stop the build, not reach the printer.
5. **Check the checker.** When you add a test, make it fail first — deliberately
   break the geometry and watch the number move. A test that cannot fail proves
   nothing.

## Adding a model

```
models/<name>/
  src/params.scad     every dimension
  src/main.scad       dispatches on `part`, plus a `dims` part that echoes numbers
  tools/fitcheck.scad intersections of parts that mate, dispatching on `which`
  Makefile            PARTS, PLATES, FIT_CASES, then include ../../mk/model.mk
  README.md
```

Then add a row to the root README's model table. The Makefile is about fifteen
lines; everything else comes from `mk/model.mk`.

## Conventions

Longer form in [CLAUDE.md](CLAUDE.md), which is written for an AI assistant but
describes the house style either way: print orientation is a design input,
removed material is free and added material is not, derive rather than restate.

## Licence

Contributions to `lib/`, `tools/`, `mk/` are MIT. Contributions under `models/`
are CC BY-SA 4.0. By opening a pull request you agree to those terms.
