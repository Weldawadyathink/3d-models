"""Side-loading M6 hex-nut holders; dimensions in mm, assembly coordinates.

Plain M6 DIN 934 / ISO 4032 nuts: 10 mm across flats, up to 5.2 mm high.
No nyloc/flange/coupling nuts. Both insertion mouths face +X so their slot
openings face upward in the plate's supplied on-edge print orientation.
"""
import math

import FreeCAD as App
import Part

POCKET_AF = 10.4
POCKET_HEIGHT = 5.6
ROOF = 1.6
HEIGHT = POCKET_HEIGHT + ROOF
FOOT_RADIUS = 12.0
BOLT_DIAMETER = 6.6
OFFSETS = [(-35.0, 60.0), (35.0, -60.0)]


def hex_prism(x, y, z, across_flats, height):
    radius = across_flats / math.sqrt(3)
    points = [App.Vector(x + radius*math.cos(i*math.pi/3),
                         y + radius*math.sin(i*math.pi/3), z) for i in range(6)]
    return Part.Face(Part.makePolygon(points + points[:1])).extrude(App.Vector(0, 0, height))


def holder_geometry(x, y, top, bottom):
    # Broad foot and sloped shoulder spread the holder's loads into the plate.
    foot = Part.makeCylinder(FOOT_RADIUS, 2.05, App.Vector(x, y, top-0.05))
    shoulder = Part.makeCone(FOOT_RADIUS, 10, 2, App.Vector(x, y, top+2))
    crown = Part.makeCylinder(10, HEIGHT-4, App.Vector(x, y, top+4))
    boss = foot.fuse(shoulder).fuse(crown)
    pocket = hex_prism(x, y, top, POCKET_AF, POCKET_HEIGHT)
    entry = Part.makeBox(FOOT_RADIUS+1, POCKET_AF, POCKET_HEIGHT,
                         App.Vector(x, y-POCKET_AF/2, top))
    bore = Part.makeCylinder(BOLT_DIAMETER/2, top+HEIGHT-bottom+2,
                             App.Vector(x, y, bottom-1))
    return boss, pocket.fuse(entry).fuse(bore), bore


def add_holders(plate, centers):
    top, bottom = plate.BoundBox.ZMax, plate.BoundBox.ZMin
    result = plate.copy()
    bores = []
    b = plate.BoundBox
    above = Part.makeBox(b.XLength+10, b.YLength+10, HEIGHT+1,
                         App.Vector(b.XMin-5, b.YMin-5, top))
    added_volume = 0
    for x, y in centers:
        boss, void, bore = holder_geometry(x, y, top, bottom)
        result = result.fuse(boss).cut(void)
        bores.append(bore)
        added_volume += boss.cut(void).common(above).Volume
    result = result.removeSplitter()
    assert result.isValid() and len(result.Solids) == 1
    # Only the two bolt bores may remove material from the original plate.
    expected = plate.cut(Part.makeCompound(bores))
    assert abs(result.Volume-expected.Volume-added_volume) < 1e-4
    # OCC differences between almost-coplanar imported/generated faces produce
    # invalid phantom solids on this STEP. Use independent volume balance and
    # material probes at two depths instead of treating those failed booleans
    # as evidence of a change. Also probe every original screw-hole/counterbore.
    probes = [App.Vector(b.XMin+5*ix, b.YMin+5*iy, z)
              for z in [bottom+1, top-0.75]
              for ix in range(1, int(b.XLength/5))
              for iy in range(1, int(b.YLength/5))]
    for f in plate.Faces:
        if isinstance(f.Surface, Part.Cylinder):
            fb = f.BoundBox
            cx, cy, cz = (fb.XMin+fb.XMax)/2, (fb.YMin+fb.YMax)/2, (fb.ZMin+fb.ZMax)/2
            for rad in [f.Surface.Radius-0.1, f.Surface.Radius+0.1]:
                for angle in [0, math.pi/2, math.pi, 3*math.pi/2]:
                    probes.append(App.Vector(cx+rad*math.cos(angle), cy+rad*math.sin(angle), cz))
    for point in probes:
        assert expected.isInside(point, 1e-6, True) == result.isInside(point, 1e-6, True)
    # A full-size nut can slide in, can't spin 30 degrees, and is retained by
    # the roof. Check hardware envelopes rather than modelling cosmetic threads.
    for x, y in centers:
        for shift in range(0, 23, 2):
            nut = hex_prism(x+shift, y, top+0.1, 10, 5.2)
            assert result.common(nut).Volume < 1e-5, "Nut insertion is obstructed"
        nut = hex_prism(x, y, top+0.1, 10, 5.2)
        nut.rotate(App.Vector(x, y, 0), App.Vector(0, 0, 1), 30)
        assert result.common(nut).Volume > 0.1, "Nut must be restrained from rotating"
        lifted = hex_prism(x, y, top+0.8, 10, 5.2)
        assert result.common(lifted).Volume > 0.1, "Nut must be retained vertically"
        bolt = Part.makeCylinder(3, top+HEIGHT-bottom, App.Vector(x, y, bottom))
        assert result.common(bolt).Volume < 1e-5, "M6 bolt path obstructed"
    return result


def mounted_plate(plate, shell):
    b = plate.BoundBox
    cx, cy = (b.XMin+b.XMax)/2, (b.YMin+b.YMax)/2
    centers = [(cx+dx, cy+dy) for dx, dy in OFFSETS]
    result = add_holders(plate, centers)
    clearances = []
    for x, y in centers:
        # Conservative solid cylinder encloses the complete holder AND nut.
        envelope = Part.makeCylinder(FOOT_RADIUS, HEIGHT, App.Vector(x, y, b.ZMax+0.001))
        assert envelope.common(shell).Volume < 1e-5
        clearances.append(envelope.distToShape(shell)[0])
    assert result.common(shell).Volume < 1e-5
    assert abs(result.BoundBox.ZMin-b.ZMin) < 1e-6
    for name in ['XMin', 'XMax', 'YMin', 'YMax']:
        assert abs(getattr(result.BoundBox, name)-getattr(b, name)) < 1e-6
    coupon_base = Part.makeBox(28, 28, 5, App.Vector(-14, -14, 0))
    coupon = add_holders(coupon_base, [(0, 0)])
    report = {
        'type': 'two side-loading captive plain M6 hex nuts; bolts enter from below',
        'centers_from_plate_center_xy_mm': OFFSETS,
        'centers_in_original_step_xy_mm': centers,
        'centers_from_xmin_ymin_mm': [(x-b.XMin, y-b.YMin) for x, y in centers],
        'xy_spacing_mm': [70, 120],
        'diagonal_spacing_mm': math.hypot(70, 120),
        'nut_nominal_af_mm': 10,
        'nut_max_height_mm': 5.2,
        'pocket_af_mm': POCKET_AF,
        'pocket_height_mm': POCKET_HEIGHT,
        'bolt_clearance_diameter_mm': BOLT_DIAMETER,
        'holder_height_above_plate_mm': HEIGHT,
        'holder_foot_diameter_mm': 2*FOOT_RADIUS,
        'roof_thickness_mm': ROOF,
        'floor_thickness_mm': b.ZLength,
        'holder_envelope_to_fixed_shell_clearance_mm': clearances,
        'nut_insertion_rotation_retention_and_bolt_path_checks_passed': True,
        'original_plate_preserved_except_two_bolt_bores': True,
        'moving_mechanism_clearance': 'Not verified: moving hardware is absent from STEP',
        'mount_slot_alignment': 'Based on user-confirmed adjustable sliding plates; not physically tested'
    }
    return result, coupon, report
