// Walkie Talkie Carabiner Attachment Arch
// This arch attaches to a walkie talkie via two studs and provides
// a permanent carabiner attachment point.

// ============================================
// DIMENSIONS
// ============================================

// Basic pill shape dimensions
attachment_length = 46.5;    // Length of the walkie talkie attachment
attachment_width = 11.5;     // Width of the walkie talkie attachment
attachment_height = 7;       // Height/tall dimension (Z direction)
rounding_diameter = attachment_width; // Diameter of the rounding (matches width)

// Screw hole dimensions
stud_hole_diameter = 5.5;       // Bottom hole for stud (5mm wide)
stud_hole_depth = 1.6;        // Depth of stud hole (1.6mm)
screw_shaft_diameter = 2;     // Screw shaft diameter (2mm)
screw_head_diameter = 5.5;    // Screw head diameter (5.5mm)
screw_head_start = 2.5;         // Height where screw head starts (4mm from bottom)

// Arch cutout dimensions
arch_cutout_width = 15;      // Width of the arch cutout (X direction)
carabiner_clearance_height = 12; // Height above Z=0 for the carabiner opening
arch_top_thickness = 3;      // Material thickness above the carabiner opening
arch_shoulder_width = 3;     // Extra material on each side of the opening
arch_ramp_width = 5;         // Width of each sloped shoulder above the base
arch_profile_steps = 12;     // Smoothness of each curved shoulder
top_edge_chamfer = 0.8;      // Chamfer around the raised bridge top edge
inner_arch_chamfer = 3;      // Chamfer on the upper inside corners of the opening
arch_top_height = carabiner_clearance_height + arch_top_thickness;

// TPU insert side guide dimensions
tpu_insert_width = 7;
tpu_insert_y_clearance = 0.4;
tpu_insert_bottom_trim = 3;
tpu_side_guide_x = 1.2;

// Keying slot dimensions
keying_slot_y = 1.5;    // Width of the keying slot (Y direction, perpendicular to line)
keying_slot_z = 2.5;    // Depth of the keying slot (Z direction)
keying_slot_x = 3.5;  // Distance extending from cutout edge (X direction)

// Quality settings
$fn = 64;  // Number of fragments for circles/cylinders (higher = smoother, slower to render)


// ============================================
// MAIN ARCH MODEL
// ============================================
// Coordinate system:
// X: along the length (left to right)
// Y: width (front to back)
// Z: height/tall (upward)

module attachment_profile() {
    hull() {
        translate([-attachment_length/2 + rounding_diameter/2, 0])
            circle(d=rounding_diameter);

        translate([attachment_length/2 - rounding_diameter/2, 0])
            circle(d=rounding_diameter);
    }
}

module xz_extrude(width) {
    translate([0, width/2, 0])
        rotate([90, 0, 0])
            linear_extrude(height=width)
                children();
}

module raised_arch_profile(top_drop=0) {
    arch_inner_half_width = arch_cutout_width/2 + arch_shoulder_width;
    arch_outer_half_width = arch_inner_half_width + arch_ramp_width;
    ramp_height = arch_top_height - attachment_height;

    polygon(concat(
        [[-arch_outer_half_width, attachment_height]],
        [
            for (i = [1:arch_profile_steps])
                let (
                    t = i/arch_profile_steps,
                    eased = 3*t*t - 2*t*t*t
                )
                    [
                        -arch_outer_half_width + arch_ramp_width*t,
                        attachment_height + ramp_height*eased - top_drop*t
                    ]
        ],
        [[arch_inner_half_width, arch_top_height - top_drop]],
        [
            for (i = [1:arch_profile_steps])
                let (
                    t = i/arch_profile_steps,
                    eased = 3*t*t - 2*t*t*t
                )
                    [
                        arch_inner_half_width + arch_ramp_width*t,
                        arch_top_height - ramp_height*eased - top_drop*(1 - t)
                    ]
        ]
    ));
}

module raised_arch_body() {
    if (top_edge_chamfer > 0) {
        hull() {
            xz_extrude(attachment_width)
                raised_arch_profile(top_drop=top_edge_chamfer);

            xz_extrude(attachment_width - 2*top_edge_chamfer)
                raised_arch_profile();
        }
    } else {
        xz_extrude(attachment_width)
            raised_arch_profile();
    }
}

module arch_cutout() {
    chamfer = min(inner_arch_chamfer, arch_cutout_width/2, carabiner_clearance_height);

    xz_extrude(attachment_width + 0.2)
        polygon([
            [-arch_cutout_width/2, 0],
            [arch_cutout_width/2, 0],
            [arch_cutout_width/2, carabiner_clearance_height - chamfer],
            [arch_cutout_width/2 - chamfer, carabiner_clearance_height],
            [-arch_cutout_width/2 + chamfer, carabiner_clearance_height],
            [-arch_cutout_width/2, carabiner_clearance_height - chamfer]
        ]);
}

module attachment_body() {
    linear_extrude(height=attachment_height)
        attachment_profile();

    // Raised bridge for carabiner clearance while keeping the screw pads low.
    raised_arch_body();
}

module cut_arch_opening() {
    difference() {
        attachment_body();
        arch_cutout();
    }
}

module tpu_side_guides() {
    guide_y_inner = tpu_insert_width/2 + tpu_insert_y_clearance/2;
    guide_y_outer = attachment_width/2;
    guide_y_width = guide_y_outer - guide_y_inner;
    guide_y_center = (guide_y_inner + guide_y_outer)/2;

    for (x_side = [-1, 1], y_side = [-1, 1])
        translate([
            0,
            y_side*guide_y_center,
            0
        ])
            xz_extrude(guide_y_width)
                if (x_side > 0) {
                    polygon([
                        [arch_cutout_width/2 - tpu_side_guide_x, tpu_insert_bottom_trim],
                        [arch_cutout_width/2, tpu_insert_bottom_trim],
                        [arch_cutout_width/2, carabiner_clearance_height - inner_arch_chamfer],
                        [arch_cutout_width/2 - tpu_side_guide_x, carabiner_clearance_height - inner_arch_chamfer + tpu_side_guide_x]
                    ]);
                } else {
                    polygon([
                        [-arch_cutout_width/2, tpu_insert_bottom_trim],
                        [-arch_cutout_width/2 + tpu_side_guide_x, tpu_insert_bottom_trim],
                        [-arch_cutout_width/2 + tpu_side_guide_x, carabiner_clearance_height - inner_arch_chamfer + tpu_side_guide_x],
                        [-arch_cutout_width/2, carabiner_clearance_height - inner_arch_chamfer]
                    ]);
                }
}

difference() {
    union() {
        cut_arch_opening();
        tpu_side_guides();
    }
    
    // Left side screw hole
    translate([-attachment_length/2 + rounding_diameter/2, 0, 0]) {
        // Bottom stud hole (5mm diameter, 1.6mm deep)
        cylinder(h=stud_hole_depth, d=stud_hole_diameter);
        
        // Screw shaft (2mm diameter, from 1.6mm to 4mm)
        translate([0, 0, stud_hole_depth])
            cylinder(h=screw_head_start - stud_hole_depth, d=screw_shaft_diameter);
        
        // Screw head clearance (5.5mm diameter, from 4mm to top)
        translate([0, 0, screw_head_start])
            cylinder(h=arch_top_height - screw_head_start + 0.1, d=screw_head_diameter);
    }
    
    // Right side screw hole
    translate([attachment_length/2 - rounding_diameter/2, 0, 0]) {
        // Bottom stud hole (5mm diameter, 1.6mm deep)
        cylinder(h=stud_hole_depth, d=stud_hole_diameter);
        
        // Screw shaft (2mm diameter, from 1.6mm to 4mm)
        translate([0, 0, stud_hole_depth])
            cylinder(h=screw_head_start - stud_hole_depth, d=screw_shaft_diameter);
        
        // Screw head clearance (5.5mm diameter, from 4mm to top)
        translate([0, 0, screw_head_start])
            cylinder(h=arch_top_height - screw_head_start + 0.1, d=screw_head_diameter);
    }
    
    translate([arch_cutout_width/2, -keying_slot_y/2, 0])
        cube([keying_slot_x, keying_slot_y, keying_slot_z]);
}
