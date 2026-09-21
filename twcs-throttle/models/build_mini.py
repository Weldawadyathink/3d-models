"""Preserve the TWCS internals; chamfer the two top end edges for a MINI bed.

Run with FreeCAD's bundled Python (see `make cad`). Source axes: X is width,
Y is slider travel, Z is height. The original STEP contains a shell AND a lid.
Only the shell receives two equal-distance chamfers; the lid is unchanged.
"""
import argparse
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import tempfile

# The macOS bundle doesn't automatically expose its CAD extension modules.
bundle_lib = Path(sys.executable).resolve().parent.parent / "lib"
sys.path.insert(0, str(bundle_lib))
import FreeCAD as App
import Mesh
import MeshPart
import Part

HERE = Path(__file__).resolve().parent
OUT = HERE.parent / "outputs"
RENDERS = HERE.parent / "renders"
SOURCE = HERE / "throttle-base-remix-v25.step"


def dimensions(shape):
    b = shape.BoundBox
    return [b.XLength, b.YLength, b.ZLength]


def print_orientation(shape):
    """Rigid rotation: left side down, long direction at 45 degrees; center on bed."""
    s = math.sqrt(0.5)
    matrix = App.Matrix()
    # (X,Y,Z) -> ((Y-Z)/sqrt(2), (Y+Z)/sqrt(2), X), determinant +1.
    matrix.A11, matrix.A12, matrix.A13 = 0, s, -s
    matrix.A21, matrix.A22, matrix.A23 = 0, s, s
    matrix.A31, matrix.A32, matrix.A33 = 1, 0, 0
    result = shape.copy()
    result.Placement = App.Placement(matrix).multiply(result.Placement)
    b = result.BoundBox
    result.translate(App.Vector(90 - (b.XMin + b.XMax) / 2,
                                90 - (b.YMin + b.YMax) / 2, -b.ZMin))
    return result


def export_mesh(shape, name):
    mesh = MeshPart.meshFromShape(Shape=shape, LinearDeflection=0.05,
                                  AngularDeflection=0.15, Relative=False)
    filename = OUT / (name + ".stl")
    mesh.write(str(filename))
    # Validate the delivered STL after reloading. Its shared vertices are
    # welded by the STL reader; the in-memory tessellation contains duplicate
    # seam vertices from this imported STEP's coplanar faces.
    mesh = Mesh.Mesh(str(filename))
    assert mesh.isSolid(), f"{name}: mesh is not closed"
    assert mesh.countComponents() == 1, f"{name}: disconnected mesh"
    assert not mesh.hasNonManifolds(), f"{name}: nonmanifold mesh"
    assert abs(mesh.Volume-shape.Volume)/shape.Volume < 0.001, f"{name}: volume mismatch"
    if name.endswith("-print"):
        b = mesh.BoundBox
        assert min(b.XMin, b.YMin, b.ZMin) >= -0.0001
        assert max(b.XMax, b.YMax, b.ZMax) <= 180
    return mesh.CountFacets


def render(openscad, name, content, camera):
    # Transient OpenSCAD files are outside the repository, not model sources.
    with tempfile.TemporaryDirectory(prefix="twcs-preview-") as folder:
        script = Path(folder) / "preview.scad"
        script.write_text(content)
        subprocess.run([openscad, "-q", "-o", str(RENDERS / (name + ".png")),
                        "--imgsize", "1600,1100", "--colorscheme", "Tomorrow",
                        "--autocenter", "--viewall", "--camera", camera,
                        str(script)], check=True)


def bed_diagram(shell, original, plate, distance):
    """Dimensioned orthographic silhouettes, using the actual projected vertices."""
    from PIL import Image, ImageDraw, ImageFont

    def hull(points):
        points = sorted(set(points))
        def cross(o, a, b):
            return (a[0]-o[0])*(b[1]-o[1]) - (a[1]-o[1])*(b[0]-o[0])
        lo, hi = [], []
        for p in points:
            while len(lo) >= 2 and cross(lo[-2], lo[-1], p) <= 0:
                lo.pop()
            lo.append(p)
        for p in reversed(points):
            while len(hi) >= 2 and cross(hi[-2], hi[-1], p) <= 0:
                hi.pop()
            hi.append(p)
        return lo[:-1] + hi[:-1]

    def font(size):
        for path in ["/System/Library/Fonts/Supplemental/Arial.ttf",
                     "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"]:
            if Path(path).exists():
                return ImageFont.truetype(path, size)
        return ImageFont.load_default()

    canvas = Image.new("RGB", (1800, 1160), "#f4f6f8")
    draw = ImageDraw.Draw(canvas)
    draw.text((55, 30), "TWCS / Prusa MINI fit", font=font(44), fill="#152c3b")
    draw.text((55, 93), f"Two {distance:g} mm top-end chamfers. Two separate prints. All dimensions in mm.",
              font=font(26), fill="#405669")
    for i, (shape, title) in enumerate([(shell, "SHELL / left side down"), (plate, "BOTTOM PLATE / long edge down")]):
        left, top, scale = 80 + i*885, 215, 4.0
        def xy(p):
            return (left + p[0]*scale, top + (180-p[1])*scale)
        draw.text((left, 160), title, font=font(29), fill="#152c3b")
        draw.rectangle([xy((0,180)), xy((180,0))], fill="white", outline="#354c60", width=3)
        for v in range(10,180,10):
            draw.line([xy((0,v)),xy((180,v))], fill="#e6ebef")
            draw.line([xy((v,0)),xy((v,180))], fill="#e6ebef")
        coords = hull([(v.Point.x,v.Point.y) for v in shape.Vertexes])
        draw.polygon([xy(p) for p in coords], fill="#72b7b0", outline="#125c59", width=3)
        if i == 0:
            coords = hull([(v.Point.x,v.Point.y) for v in original.Vertexes])
            draw.line([xy(p) for p in coords + coords[:1]], fill="#e3783e", width=3)
        b = dimensions(shape)
        draw.text((left, 963), f"Footprint  {b[0]:.2f} x {b[1]:.2f}    Height  {b[2]:.2f}", font=font(26), fill="#152c3b")
        draw.text((left, 1006), "180 x 180 bed / 45 degree orientation", font=font(25), fill="#405669")
    draw.text((80, 1060), "Orange: unmodified shell outline (180.30 x 180.30). Teal: printable part.", font=font(27), fill="#405669")
    margin = (180-max(dimensions(shell)[:2]))/2
    draw.text((80, 1102), f"Shell: {margin:.2f} mm edge margin; no full brim. Plate: room for a 5 mm brim.", font=font(26), fill="#405669")
    canvas.save(RENDERS / "mini-bed-fit.png")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--chamfer", type=float, default=2.5)
    parser.add_argument("--openscad", default=os.environ.get("OPENSCAD", "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"))
    parser.add_argument("--skip-renders", action="store_true")
    args = parser.parse_args()
    # Larger bevels require a separate wall-thickness / mounting-feature review.
    if not 2 <= args.chamfer <= 2.5:
        parser.error("Validated chamfer range is 2 to 2.5 mm")
    OUT.mkdir(exist_ok=True)
    RENDERS.mkdir(exist_ok=True)
    imported = Part.read(str(SOURCE))
    assert imported.isValid() and len(imported.Solids) == 2
    body, plate = sorted(imported.Solids, key=lambda s: s.BoundBox.ZLength, reverse=True)
    assert abs(body.BoundBox.ZLength - 45) < 0.001
    assert abs(plate.BoundBox.ZLength - 5) < 0.001
    b = body.BoundBox
    edges = [i for i, e in enumerate(body.Edges, 1)
             if e.BoundBox.XLength > 120 and e.BoundBox.ZLength < 0.001
             and abs(e.BoundBox.ZMax-b.ZMax) < 0.001
             and (abs(e.BoundBox.YMin-b.YMin) < 0.001
                  or abs(e.BoundBox.YMax-b.YMax) < 0.001)]
    assert len(edges) == 2, "Input no longer has the expected two top end edges"

    doc = App.newDocument("TWCS_Mini")
    source = doc.addObject("Part::Feature", "OriginalShell")
    source.Label = "Original shell (reference)"
    source.Shape = body
    chamfer = doc.addObject("Part::Chamfer", "MiniShell")
    chamfer.Label = f"MINI shell - {args.chamfer:g} mm top end chamfers"
    chamfer.Base = source
    chamfer.Edges = [(i, args.chamfer, args.chamfer) for i in edges]
    lid = doc.addObject("Part::Feature", "BottomPlate")
    lid.Label = "Original bottom plate - unchanged"
    lid.Shape = plate
    doc.recompute()
    source.Visibility = False
    # Use the direct OCC result for comparisons/export. The document feature
    # copies the imported shape; booleans between those copies can fail on this
    # STEP's thousands of nearly coplanar triangular faces. The direct operation
    # retains shared topology for unchanged features.
    result = body.makeChamfer(args.chamfer, [body.Edges[i-1] for i in edges])
    assert abs(result.Volume - chamfer.Shape.Volume) < 1e-5
    assert result.isValid() and len(result.Solids) == 1
    removed = body.cut(result)
    added_volume = result.cut(body).Volume
    assert added_volume < 1e-5, "Modification must not intrude into the cavity"
    assert removed.BoundBox.ZMin >= b.ZMax-args.chamfer-1e-5
    # The entire central body, slider slot, mounting features and bottom interface
    # must be identical; only the top two end-edge regions can change.
    protected = Part.makeBox(b.XLength+2, b.YLength-2*args.chamfer-0.002,
                             b.ZLength+2, App.Vector(b.XMin-1, b.YMin+args.chamfer+0.001, b.ZMin-1))
    protected_removed = removed.common(protected).Volume
    assert protected_removed < 1e-5
    inner_roof = max((f for f in body.Faces if f.Area > 10000 and
                     abs(f.BoundBox.ZMax-(b.ZMax-2.5)) < 0.001), key=lambda f:f.Area)
    bevels = [f for f in result.Faces if abs(f.Area-args.chamfer*math.sqrt(2)*b.XLength) < 0.1]
    assert len(bevels) == 2
    roof_clearance = min(f.distToShape(inner_roof)[0] for f in bevels)
    assert roof_clearance > 2.1

    print_body = print_orientation(result)
    print_plate = print_orientation(plate)
    for shape in [print_body, print_plate]:
        assert shape.isValid() and all(d < 180 for d in dimensions(shape))
    facets = {}
    for shape, name in [(result, "twcs-mini-shell"), (plate, "twcs-bottom-plate"),
                        (print_body, "twcs-mini-shell-print"), (print_plate, "twcs-bottom-plate-print")]:
        shape.exportStep(str(OUT / (name + ".step")))
        facets[name] = export_mesh(shape, name)
    Part.makeCompound([result, plate]).exportStep(str(OUT / "twcs-mini-assembly.step"))
    doc.saveAs(str(OUT / "twcs-mini.FCStd"))
    report = {
        "chamfer_mm": args.chamfer,
        "original_assembly_dimensions_mm": dimensions(imported),
        "original_shell_print_dimensions_mm": dimensions(print_orientation(body)),
        "shell_print_dimensions_mm": dimensions(print_body),
        "plate_print_dimensions_mm": dimensions(print_plate),
        "shell_bed_edge_margin_mm": (180-max(dimensions(print_body)[:2]))/2,
        "volume_removed_mm3": removed.Volume,
        "volume_added_mm3": added_volume,
        "protected_region_volume_removed_mm3": protected_removed,
        "minimum_bevel_to_inner_roof_distance_mm": roof_clearance,
        "plate_unchanged": True,
        "brep_valid": True,
        "stl_closed_single_component_manifold": True,
        "mesh_facets": facets,
        "limitations": "Geometric verification only; mechanism assembly and physical printing are not tested."
    }
    (OUT / "validation.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    if not args.skip_renders:
        shell_import = 'import(' + json.dumps(str(OUT / "twcs-mini-shell.stl")) + ');'
        render(args.openscad, "twcs-mini-shell-iso", shell_import, "0,0,0,55,0,30,500")
        render(args.openscad, "twcs-mini-shell-inside", shell_import, "0,0,0,235,0,30,500")
        render(args.openscad, "twcs-mini-shell-side", shell_import, "0,0,0,90,0,90,500")
        lid_import = 'import(' + json.dumps(str(OUT / "twcs-bottom-plate.stl")) + ');'
        render(args.openscad, "twcs-bottom-plate", lid_import, "0,0,0,235,0,30,500")
        original_print = print_orientation(body)
        # Match the original to the modified shell's centering translation so
        # overlaid edges share the same physical coordinates.
        # Equal symmetric bevels shift the two footprint centers oppositely.
        original_print.translate(App.Vector(-args.chamfer/(2*math.sqrt(2)),
                                             args.chamfer/(2*math.sqrt(2)), 0))
        bed_diagram(print_body, original_print, print_plate, args.chamfer)
    App.closeDocument(doc.Name)


if __name__ == "__main__":
    main()
