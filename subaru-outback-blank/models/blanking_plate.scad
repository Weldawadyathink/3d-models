// 2011 Subaru Outback AUX / USB console blank. Dimensions in millimeters.
// Print orientation: cosmetic face at Z=0, open rear at Z=total_depth.
// Rear-rooted clips need removable support beneath their free tips.
// See README.md beside this file for assumptions and fit adjustment.

/* [Measured envelope] */
opening_width = 53;
opening_height = 27;
key_diagonal = 10; // Length of the 45-degree cut edge, not its X/Y inset.
panel_thickness = 2.5;
flange_width = 60.5;
flange_height = 33;
total_depth = 15; // Includes face thickness.

/* [Fit and appearance] */
clearance_per_side = 0.20;
face_thickness = 2.4;
flange_corner_radius = 3;
face_edge_bevel = 0.6;
body_corner_radius = 1.5;
wall_thickness = 1.6;

/* [Clips - physical fit still needs testing] */
// Added to measured panel thickness so all four shoulders can clear the lip.
retention_clearance = 0.2;
tab_width = 8;
tab_spacing = 24; // Center-to-center; leaves solid wall beside the keyed corner.
tab_thickness = 1.2;
tab_projection = 1.0; // Extends beyond sleeve: 0.8 mm overlap past opening.
tab_ramp_length = 3.5;
tab_slot = 0.7;
tab_root_depth = 2;
front_collar_height = 0.6;
tip_clearance = 1.0;

/* [Hidden] */
$fn = 64;
eps = 0.02;
body_width = opening_width - 2 * clearance_per_side;
body_height = opening_height - 2 * clearance_per_side;
key_inset = key_diagonal / sqrt(2);
panel_gap = panel_thickness + retention_clearance;
slot_start = face_thickness + front_collar_height;
tab_start = slot_start + tip_clearance;
root_start = total_depth - tab_root_depth;
shoulder_z = face_thickness + panel_gap;

assert(clearance_per_side >= 0);
assert(panel_thickness > 0 && retention_clearance >= 0);
assert(key_diagonal > 0 && key_inset < min(opening_width, opening_height));
assert(face_thickness > face_edge_bevel && face_edge_bevel >= 0);
assert(flange_width > body_width && flange_height > body_height);
assert(flange_corner_radius > face_edge_bevel);
assert(2 * flange_corner_radius < min(flange_width, flange_height));
assert(body_corner_radius > 0 && 2 * body_corner_radius < body_height);
assert(wall_thickness > 0 && 2 * wall_thickness < body_height);
assert(tab_thickness > 0 && tab_thickness <= wall_thickness);
assert(tab_width > 0 && tab_slot > 0 && tip_clearance > 0);
assert(tab_spacing > tab_width + 2 * tab_slot);
assert(tab_spacing + tab_width + 2 * tab_slot < body_width - 2 * max(body_corner_radius, wall_thickness));
// Keep the left slot clear of the inner diagonal and its rounded transition.
assert(-tab_spacing/2 - tab_width/2 - tab_slot >
       -opening_width/2 + key_inset +
       (clearance_per_side + wall_thickness)*(sqrt(2)-1) + body_corner_radius,
       "Clips are too close to the keyed corner; reduce tab_spacing or tab_width.");
assert(tab_projection > clearance_per_side);
assert(tab_projection < (flange_height - body_height) / 2);
assert(shoulder_z > tab_start, "Increase panel_gap or reduce tip_clearance.");
assert(tab_ramp_length > 0 && shoulder_z + tab_ramp_length < root_start);
assert(tab_root_depth >= wall_thickness && root_start > tab_start);

module rounded_rectangle(w, h, r) {
    if (r > 0)
        offset(r = r) square([w - 2*r, h - 2*r], center = true);
    else
        square([w, h], center = true);
}

module opening_outline() {
    // Looking from the open REAR (+Z), X right and Y up: upper-left key.
    // This matches the photo of the underside of the console. When viewed
    // from the cosmetic face with the same top edge up, the key is upper-right.
    polygon([
        [-opening_width/2, -opening_height/2],
        [ opening_width/2, -opening_height/2],
        [ opening_width/2,  opening_height/2],
        [-opening_width/2 + key_inset, opening_height/2],
        [-opening_width/2, opening_height/2 - key_inset]
    ]);
}

module sleeve_outline() {
    // Offset the measured polygon, including its diagonal, by the fit
    // clearance normal to every edge. Round inward without enlarging it.
    offset(r = body_corner_radius)
        offset(delta = -body_corner_radius)
            offset(delta = -clearance_per_side) opening_outline();
}

module face() {
    // Small cosmetic bevel; maximum flange dimensions are unchanged.
    hull() {
        linear_extrude(height = eps)
            rounded_rectangle(flange_width - 2*face_edge_bevel,
                              flange_height - 2*face_edge_bevel,
                              flange_corner_radius - face_edge_bevel);
        translate([0, 0, face_edge_bevel])
            linear_extrude(height = face_thickness - face_edge_bevel)
                rounded_rectangle(flange_width, flange_height, flange_corner_radius);
    }
}

module sleeve() {
    difference() {
        translate([0, 0, face_thickness - eps])
            linear_extrude(height = total_depth - face_thickness + eps)
                difference() {
                    sleeve_outline();
                    offset(delta = -wall_thickness) sleeve_outline();
                }
        // Four U-shaped openings, two per long edge, isolate the clips.
        // The final 2 mm of sleeve remains intact to anchor each clip at the rear.
        for (side = [-1, 1], x = [-tab_spacing/2, tab_spacing/2])
            translate([x, 0, 0])
                scale([1, side, 1])
                    translate([-tab_width/2 - tab_slot,
                               body_height/2 - wall_thickness - eps, slot_start])
                        cube([tab_width + 2*tab_slot, wall_thickness + 2*eps,
                              root_start - slot_start]);
    }
}

module positive_y_clip() {
    // Bury the root inside the sleeve; avoid coincident faces between the
    // rounded 2D extrusion and 3D beam (which can create STL sliver triangles).
    translate([-tab_width/2, body_height/2 - tab_thickness - eps, tab_start])
        cube([tab_width, tab_thickness, root_start + 0.5 - tab_start]);

    // Y/Z ramp, extruded along X. Rear end enters the cutout first; its slope
    // bends the arm inward. The flat forward shoulder catches behind the trim.
    translate([-tab_width/2, 0, 0])
        rotate([90, 0, 90])
            linear_extrude(height = tab_width)
                polygon([
                    [body_height/2 - 2*eps, shoulder_z],
                    [body_height/2 + tab_projection, shoulder_z],
                    [body_height/2, shoulder_z + tab_ramp_length],
                    [body_height/2 - 2*eps, shoulder_z + tab_ramp_length]
                ]);
}

union() {
    face();
    sleeve();
    for (side = [-1, 1], x = [-tab_spacing/2, tab_spacing/2])
        translate([x, 0, 0])
            scale([1, side, 1]) positive_y_clip();
}
