# TWCS throttle housing for the Prusa MINI

The supplied `throttle-base-remix-v25.step` contains **two separate solids**:
a 45 mm tall shell and a 5 mm bottom plate. Print them separately and assemble
using the existing screw holes. The original STEP has been moved into `models/`
without changing its contents to follow this repository's layout.

## Modification

Two equal-distance **2.5 mm chamfers** run across the width of the shell, at
the front/top and rear/top edges (the two ends of the slider's travel). These
are 45-degree bevels, each with a 2.5 mm setback on the top and end surfaces.
The long edges parallel to the slider are unchanged. There is no scaling.

The bevels remove material only in the outermost 2.5 mm of each end and the
topmost 2.5 mm. They do not enter the existing cavity, move the slider slot,
or change the internal mounts, screw holes, cable opening or bottom interface.
The minimum measured distance from the bevels to the inner roof is about
2.12 mm. The bottom plate now includes two diagonal M6 nut holders, described below.

## Desk mounting: two captive M6 nuts

Designed for the user's [Hikig mount](https://www.amazon.com/dp/B09WR894Q9)
with independently adjustable sliding plates. The user confirmed that diagonal
mounting points can be accommodated; this is **not the factory TWCS hole pattern**.

Use **two plain M6 × 1.0 hex nuts, 10 mm across flats and 5–5.2 mm thick**.
These dimensions accommodate ordinary DIN 934 and ISO 4032 nuts; see the
[manufacturer's M6 dimensional table](https://www.jcfasteners.com/wp-content/uploads/2019/02/ISO-4032-Hex-Nut-B4C32-SS-304.pdf).
Nyloc, flange and coupling nuts are not supported. No heat-set inserts needed.

Each holder has a **10.4 mm across-flats × 5.6 mm high side-loading pocket**,
a **1.6 mm retaining roof**, and a **6.6 mm bolt clearance hole**. The nut sits
on the full original **5 mm plate thickness**; tightening pulls it against
the plate. A 24 mm diameter foot and sloped shoulder reinforce each holder.
Holders protrude **7.2 mm into the housing**. The external underside stays flat,
and all four original cover screw holes/counterbores are preserved.

Mounting centers (original STEP axes: X = width, Y = length):

| Reference | Hole A | Hole B |
| --- | --- | --- |
| From center of plate (X, Y), mm | (−35, +60) | (+35, −60) |
| From X-min / Y-min edges (X, Y), mm | (27.25, 164.99) | (97.25, 44.99) |

The holes are **70 mm apart across the width, 120 mm along the length**,
or **138.92 mm diagonally**. Match these to the sliding plates before printing.
Both nut-entry mouths face +X. Load the nuts with the bottom plate detached:
slide each nut flat into the side opening until it reaches the hexagonal stop.
The roof prevents vertical escape and the pocket prevents rotation; a nut
can still slide back out of its insertion mouth until a bolt is engaged.
Temporary tape across the mouth can hold it during assembly.

Bolts go upward through the desk-mount plate into the printed plate. Use washers
under the bolt heads as needed for the mount slots. Choose bolt length to extend
**about 10.5–11 mm past the underside of the printed plate**: 5 mm plastic plus
the nut's thread thickness. Thus under-head length is mount thickness + washer
stack + 10.5–11 mm. Adjust washers to suit available lengths, and confirm full
thread engagement. Avoid bolt tips extending past the holder's roof (12.2 mm
from the printed underside) into the mechanism. Snug the bolts without crushing
the plastic; no tightening torque has been qualified.

**Print `twcs-m6-nut-fit-test-print.stl` first.** It has the same pocket and the
same on-edge orientation as the full plate. Check nut insertion and rotation
restraint and that your M6 bolt passes through freely. Use the same slicer
settings/material for coupon and plate. `mounting.py` exposes pocket dimensions
if your printer needs more/less clearance; regenerate after adjusting them.

The build checks the nut's insertion path, anti-rotation and vertical retention,
bolt clearance, and interference with the fixed shell. The conservative holder
envelopes clear the fixed housing by at least **11.25 mm**. The moving throttle
mechanism is not included in the STEP: check full travel and cable clearance
with the real hardware before final assembly.

## Files generated in `../outputs/`

- **`twcs-mini-shell-print.stl`**: shell rotated onto its left side, long axis
  at 45 degrees to the bed. Approximately **178.53 × 178.53 × 124.50 mm**.
- **`twcs-bottom-plate-print.stl`**: bottom plate with two M6 nut holders, standing on its long edge,
  at 45 degrees. Approximately **152.02 × 152.02 × 124.50 mm**.
- Matching `*-print.step` files have the same print orientations.
- **`twcs-m6-nut-fit-test-print.stl`**: small one-holder fit test in the same
  print orientation. The version without `-print` retains its flat CAD orientation.
- `twcs-mini-shell.step` / `.stl` and `twcs-bottom-plate.step` / `.stl` retain
  the original assembly coordinates.
- `twcs-mini-assembly.step`: both separate parts together for assembly review;
  **do not slice this as a single assembled print**.
- `twcs-mini.FCStd`: FreeCAD document with original shell, native chamfer feature
  and mounted plate. Both original reference parts are hidden. Regenerate the
  mounted plate by editing `mounting.py`; it is a generated feature, not a
  native parametric FreeCAD nut-holder feature tree.
- `validation.json`: dimensions, volume comparisons and solid/mesh checks.

## Slicing

Select the standard **180 × 180 × 180 mm MINI/MINI+** bed. Import one
`*-print.stl` at a time, keep **100% scale**, and retain its supplied rotation.
The meshes are centered at X=90, Y=90 with their lowest surface at Z=0.
Do not auto-rotate or use "place on face" after import.

Bed dimensions follow [Prusa's MINI specifications](https://blog.prusa3d.com/original-prusa-mini-now-shipping_31136/).

The shell leaves about **0.73 mm clearance on each bed edge**. A full brim
will not fit; disable its brim and skirt (or explicitly check the resulting
toolpaths). Preview supports and the first-layer extrusion paths to ensure
they also stay on the bed. Sideways printing creates internal overhangs:
supports inside the shell may be necessary, including supports starting on
the model. Check that they can be removed through the open bottom/slot and
keep support interfaces clear of precision holes and slider seats.

The bottom plate is too long to lie flat on this bed. Its supplied
orientation stands on a 5 mm wide long edge; a **5 mm brim** fits and is
recommended for stability. Both nut-loading mouths face upward in this print
orientation. Inspect the pockets, retaining roofs and sideways counterbores in
the slicer; prevent automatic supports from filling the nut channels. Use the
coupon to verify these small features before the full print. At a 0.4 mm nozzle,
four or more perimeters are a starting point, not a tested strength guarantee.
Print the parts on separate plates; they are not arranged for simultaneous printing.

This is a geometrically verified candidate, not a physical fit test. The STEP
does not include the moving mechanism, so full-travel clearance and assembly
still need to be checked with the actual throttle. The shell and its original
mechanism mounts are unchanged by the mounting addition, but the nut holders
occupy the local lower 7.2 mm of the cavity. No claim is made about the original
remix's mechanical fit.

## Rebuild

From the repository root:

```sh
make lint
make
```

Or rebuild just the native CAD models:

```sh
make cad
```

`FREECAD_PYTHON` defaults to the macOS FreeCAD application's bundled Python.
Override it for another Python environment that can import `FreeCAD`, `Part`,
`MeshPart` and Pillow. `OPENSCAD` generates the 3D previews; it is not used
to modify the geometry. This script can export without rendering:

```sh
/Applications/FreeCAD.app/Contents/Resources/bin/python \
  twcs-throttle/models/build_mini.py --skip-renders
```

`--chamfer` accepts 2.0–2.5 mm. Larger cuts need a new wall-thickness review.
The editable FreeCAD feature can also be adjusted in its `Edges` property,
but such edits do not update the separately exported STLs automatically.

Generated files belong in `outputs/` and `renders/` and are not committed.
