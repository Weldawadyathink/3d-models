# Outback console blank — fit and retention refinement

Blank cover for the AUX / USB module opening in a 2011 Subaru Outback.
The supplied measurements define the envelope; the clips are a new mechanism,
not a measured reproduction of the factory clips. The user preferred the original 2.7 mm
panel seating gap after comparing test prints, so that gap is restored. This
revision retains the thicker walls/arms, deeper teeth and softer cosmetic
perimeter. This combination still needs a physical fit test.

| Feature | Dimension (mm) |
| --- | ---: |
| Nominal opening | 53 × 27 |
| Keyed corner diagonal / X and Y inset | 10 / 7.071 |
| Sleeve outside bounding box, excluding clips | 52.6 × 26.6 |
| Flange maximum | 60.5 × 33 |
| Total depth, including face | 15 |
| Face thickness / sleeve extension behind face | 2.4 / 12.6 |
| Sleeve wall | 2.0 (previously 1.6) |
| Flange / sleeve corner radii | 4 / 1.5 |
| Cosmetic perimeter roundover radius | 0.9 |
| Measured panel thickness | 2.5 |
| Flange underside to retaining shoulder | 2.7 (2.5 + 0.2 seating allowance) |
| Clip width / beam thickness | 8 / 1.4 |
| Clip center spacing along each long edge | 24 |
| Clip projection beyond sleeve / overlap past opening | 1.3 / 1.1 |
| Uncompressed height across clips | 29.2 |

The 10 mm measurement is the diagonal edge of an isosceles right triangle:
its X and Y insets are `10 / sqrt(2) = 7.0710678 mm`. Looking at the open rear
with X right and Y up, the clipped corner is upper-left, matching the underside
photo. Viewed from the cosmetic face with the same top edge up, it is upper-right.
The sleeve is inset 0.2 mm perpendicular to every opening edge, including the
45-degree edge, then its corners are rounded inward. Its inner wall follows the
same keyed outline at a constant 2.0 mm offset. Added wall thickness grows inward
so the sleeve retains the outside dimensions that fitted well. The flange remains rectangular
and covers the entire keyed opening. Clip spacing is reduced to keep the relief
slots clear of the diagonal wall.

The face is solid, flat and unmarked, with a 0.9 mm radius perimeter
roundover and 4 mm plan-view corner radii (previously 3 mm). The hollow
sleeve guides the part into the opening. Four clips, two on each long edge like
the stock module, are anchored at the rear and separated from the sleeve by relief slots. The sloped
teeth enter first; their flat front shoulders catch behind the console lip.
The arms need roughly 1.1 mm inward travel each to pass the nominal opening,
plus whatever clearance is needed for the actual corner shape and print finish.
The open back exposes the arms: depress both clips on each long edge inward
from inside the console, then push the plate outward. All four teeth must clear
the lip; a flat tool may help depress a pair together. Check access before snapping it fully into place.

## Fit adjustments

Edit the parameters at the top of `blanking_plate.scad`, or override them with
OpenSCAD `-D` arguments. Measured dimensions take priority over photo estimates.

- `panel_thickness`: measured 2.5 mm. `retention_clearance` adds 0.2 mm,
  placing each retaining shoulder 2.7 mm behind the flange underside, restoring
  the original gap preferred in fit testing. With the face seated, the shoulder
  clears the rear panel surface by 0.2 mm. Reduce the
  allowance if a test print has excessive play; increase it if clips cannot
  fully spring out. The derived `panel_gap` must remain greater than 1.6 mm and
  less than 7.1 mm with the other defaults.
- `key_diagonal`: the measured length along the slanted cutout edge, default
  10 mm. The source calculates both adjoining insets; do not enter 7.071 here.
- `clearance_per_side`: start at 0.20 mm; increase if the sleeve binds. This also
  reduces effective tooth overlap. Check the sleeve fit before forcing clips.
- `tab_projection`: reduce if insertion is too stiff, keeping enough overlap to
  retain the plate. Clip stiffness and durability require a physical test.
- `body_corner_radius`: preserves the keyed sleeve geometry that fitted well.
  `flange_corner_radius` and `face_edge_radius` affect the visible face only.
- `tab_spacing`: default 24 mm between clip centers on each long edge. The stock
  module uses four clips, and the user confirmed that they catch the plain cutout
  edge. Their exact stock spacing therefore does not need to be copied.
- `tab_width`, `tab_thickness`, `tab_root_depth`: tune clip flexibility and
  strength. The thicker beams and larger teeth require more insertion/release
  force than the previous revision; test movement after removing supports.
  Thin beams and sharp layer defects can break during squeezing.

## Printing this revision

Use the exported orientation: cosmetic face on the bed, hollow side upward.
A starting profile is a 0.4 mm nozzle, 0.2 mm layers and 4 perimeters. Preview
the 1.4 mm clip beams in the slicer to ensure continuous extrusion paths.

**Support is needed under the four floating clip tips and the flat tooth
undersides.** The clips begin 1.6 mm above the flange's back surface. Paint
support only beneath those regions, using removable interfaces and access
through the open back/side slots. Remove all supports from each relief slot;
the arms must move independently before installation. Do not add a brim that
extends into the clip slots. The main sleeve walls need no support.

PETG is a reasonable fit-test starting material; ASA is a candidate for a final
car-interior part if your printer handles it. Material, print orientation and
layer bonding affect clip performance. Qualify retention and heat resistance
with the actual print before treating it as a finished vehicle part.

## Build and inspect

From the repository root:

```sh
make lint
make
```

Outputs are `../outputs/blanking_plate.stl` and the standard views under
`../renders/`. The default isometric and top views show the open rear; the
cosmetic face is on the opposite side. For a direct view of the cosmetic face:

```sh
/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD \
  --render true --autocenter --viewall --camera 0,0,0,180,0,0,180 \
  --imgsize 1400,1000 --colorscheme Tomorrow \
  -o subaru-outback-blank/renders/blanking_plate-face.png \
  subaru-outback-blank/models/blanking_plate.scad
```

STLs and render PNGs are generated artifacts and should not be committed.
