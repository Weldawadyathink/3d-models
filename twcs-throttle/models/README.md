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
2.12 mm. The bottom plate is completely unchanged.

## Files generated in `../outputs/`

- **`twcs-mini-shell-print.stl`**: shell rotated onto its left side, long axis
  at 45 degrees to the bed. Approximately **178.53 × 178.53 × 124.50 mm**.
- **`twcs-bottom-plate-print.stl`**: bottom plate standing on its long edge,
  at 45 degrees. Approximately **152.02 × 152.02 × 124.50 mm**.
- Matching `*-print.step` files have the same print orientations.
- `twcs-mini-shell.step` / `.stl` and `twcs-bottom-plate.step` / `.stl` retain
  the original assembly coordinates.
- `twcs-mini-assembly.step`: both separate parts together for assembly review;
  **do not slice this as a single assembled print**.
- `twcs-mini.FCStd`: editable FreeCAD document with original shell, native
  chamfer feature and original plate. The original shell is hidden.
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

The unchanged bottom plate is too long to lie flat on this bed. Its supplied
orientation stands on a 5 mm wide long edge; a **5 mm brim** fits and is
recommended for stability. Inspect the sideways counterbores in the slicer.
Print the parts on separate plates; they are not arranged for simultaneous printing.

This is a geometrically verified candidate, not a physical fit test. The STEP
does not include the moving mechanism, so full-travel clearance and assembly
still need to be checked with the actual throttle. Existing cavity geometry
is preserved; no claim is made about the original remix's mechanical fit.

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
