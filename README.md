# Dual Wedge Charging Dock

Parametric OpenSCAD model for a two-piece inclined desk charging dock sized for two Anker Zolo A25M2 round magnetic chargers.

## Dimensions

- Chassis footprint: 158 mm wide x 110 mm deep
- Inclined top face: 18 degrees
- Side-print-friendly radii enabled by default with `side_print_friendly = true`
- Side profile uses chamfers instead of large radius arcs in side-print mode, making visible profile transitions closer to 45-degree printable surfaces at 0.2 mm layers
- Global TPU mattress recess: 5 mm deep, 4 mm border
- Advertised puck size used: 60 mm diameter x 10.5 mm high
- Chassis puck cavities: 60.4 mm diameter x 10.5 mm total depth
- PETG capture below TPU mattress: 5.5 mm
- TPU mattress: 5 mm thick, 0.2 mm total perimeter clearance
- TPU mat charger cutouts: 60 mm diameter
- Internal cable bay: compact shared hollow volume set lower/rearward to preserve the inclined plane
- Cable relief: lower/front 6 o'clock rim plug-clearance blind slot from each puck, front-keepout clamped, then hidden plug-clearance chases into the hollow bay
- Cable bend envelope: 20 mm x 20 mm reserved in front of each puck exit; the body depth is extended so the puck/mattress area keeps a real rear top border
- TPU cable relief: small 6 o'clock notches in the mat cutouts for the cable jacket
- Assembly preview: `part = "assembly"` shows non-printing puck and cable fit dummies; `part = "fit_dummies"` shows only those reference solids
- Ejection holes: centered 3 mm holes through the chassis base to each cavity

## Export

The installed OpenSCAD snapshot works through the x86_64 slice on this machine:

```sh
make version
make
```

Outputs:

- `dual_wedge_chassis.stl`
- `dual_wedge_tpu_mat.stl`

Side-print oriented chassis export:

```sh
make chassis-side
```

Output:

- `dual_wedge_chassis_side_print.stl`

To preview the assembly in OpenSCAD, open `dual_wedge_charging_dock.scad` and leave `part = "assembly"`.

The active design prompt is tracked in `PROMPT.md`.
