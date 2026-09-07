# Current Modeling Prompt

Revise the dock toward the supplied reference image, but keep the surfaces clean and smooth. Do not model visible print layer lines, striations, grooves, or decorative surface artifacts. The PETG chassis should read as a smooth satin dark-grey molded form.

Create a low wedge-shaped desk dock with softened industrial geometry: rounded exterior corners, a prominent rounded front lip, sloped side profile, and an 18 degree inclined top. No vertical backrest.

Optimize the chassis for likely side printing. Keep the visible exterior smooth, but avoid large decorative radii that become shallow overhangs in the slicer. Prefer smaller radii on upper side edges and internal cable cuts, and keep the print-critical cable bay/access features closer to chamfered/short-radius geometry than large circular fillets.

For 0.2 mm layer-height printing, avoid long shallow visible wedge arcs. In side-print-friendly mode, use a chamfered side profile for the visible front/rear/top profile transitions instead of large rounded profile offsets. Prefer near-45-degree transitions where a visible angled surface must be printed as a slope.

The dock is a two-piece printable assembly:

1. PETG main chassis
2. Flexible TPU top mattress/mat

The TPU top mattress is 5 mm thick. It sits in a recessed top area and finishes flush with the visible top border. Its top CAD surface must remain smooth and flat; any diamond/mesh texture will be produced later in PrusaSlicer using exposed infill.

Use two side-by-side Anker Zolo A25M2 puck positions. Use Anker's advertised puck dimensions of 60 mm diameter x 10.5 mm height. The TPU mattress has two clean 60 mm circular cutouts. The PETG chassis has two aligned puck seats, 60.4 mm diameter, capturing the remaining 5.5 mm of puck height below the 5 mm mattress. The puck should sit level with the top of the mattress.

The chassis depth should be long enough to preserve a visible top border around the TPU mattress after the pucks are shifted rearward for the cable bend envelope. Use about 110 mm front-to-rear depth rather than 94 mm so the recess no longer overruns the rear of the inclined top.

Model non-printing fit dummies in the OpenSCAD assembly: two 60 mm x 10.5 mm puck proxies, a simple estimated cable centerline, and a translucent cable/plug clearance envelope. These dummies are for visual interference checking only and must not be included in the exported `chassis` or `mat` STL parts.

Important cable constraint: each charger cable exits from the 6 o'clock rim of the puck when the charging face is viewed head-on. In the dock this is the lower/front edge of each circular puck cavity, not the underside/back face of the puck. Do not create an underside center cable relief. Instead, create a lower rim channel in the PETG capture zone of each puck seat, opening from the lower/front edge of the cavity into a partly hollow internal cable storage compartment.

Cable management:

- Compact shared hollow compartment lower and farther back inside the chassis, so it does not break into or thin out the inclined top plane
- USB-C plug-clearance pass-through at the lower/front 6 o'clock rim of each puck. Use a parametric clearance around 14 mm wide x 8.5 mm high by default, because a cable-sized slot is not enough to pass the connector/overmold during assembly.
- Reserve a 20 mm x 20 mm local bend envelope in front of each puck's 6 o'clock exit so the attached cable can make a 180-degree turn without kinking. Move the puck centers rearward as needed so this bend envelope stays internal and does not break through the front wall.
- Small visible cable-jacket relief notches in the TPU mat at each puck's 6 o'clock position
- Flat-ceiling PETG plug-clearance slots under those notches, clamped with a front keepout so they remain internal blind reliefs and do not create openings through the front wall
- Hidden plug-clearance feed chases from each rim exit into the shared storage bay
- One visible softened rear access opening, centered behind the dock rather than on the left/right sides, so extra cable from both chargers can be rolled inside and only the desired lengths pulled out
- Avoid sharp internal cable bends where possible

Maintenance:

- Add centered 3 mm push-out holes under each puck so a tool can release the puck from below. The cable no longer uses the center underside path.

Keep the model parametric, printable, and export valid STL files for both parts.
