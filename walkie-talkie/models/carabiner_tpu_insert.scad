// TPU insert starting point for the walkie-talkie carabiner arch.
// This part models the negative space of the arch opening in
// carabiner_arch.scad so it can be trimmed into a soft carabiner liner.

// Keep these in sync with carabiner_arch.scad.
insert_width = 7;
arch_cutout_width = 15;
carabiner_clearance_height = 12;
inner_arch_chamfer = 3;
bottom_trim = 3;

// Carabiner relief dimensions. The squeeze value makes the printed cutout
// smaller than the measured carabiner so TPU compresses around it.
carabiner_cutout_z_depth = 9;
carabiner_cutout_top_width = 8;
carabiner_cutout_stalk_width = 5;
carabiner_cutout_mushroom_height = 4.5;
carabiner_squeeze = 0.7;

$fn = 48;

module xz_extrude(width) {
    translate([0, width/2, 0])
        rotate([90, 0, 0])
            linear_extrude(height=width)
                children();
}

module arch_negative_space() {
    chamfer = min(inner_arch_chamfer, arch_cutout_width/2, carabiner_clearance_height);

    xz_extrude(insert_width)
        polygon([
            [-arch_cutout_width/2, bottom_trim],
            [arch_cutout_width/2, bottom_trim],
            [arch_cutout_width/2, carabiner_clearance_height - chamfer],
            [arch_cutout_width/2 - chamfer, carabiner_clearance_height],
            [-arch_cutout_width/2 + chamfer, carabiner_clearance_height],
            [-arch_cutout_width/2, carabiner_clearance_height - chamfer]
        ]);
}

module carabiner_cutout_profile() {
    cutout_depth = carabiner_cutout_z_depth - carabiner_squeeze;
    cap_width = carabiner_cutout_top_width - carabiner_squeeze;
    stalk_width = carabiner_cutout_stalk_width - carabiner_squeeze;
    cap_height = carabiner_cutout_mushroom_height - carabiner_squeeze/2;
    stalk_height = cutout_depth - cap_height;
    z0 = bottom_trim - 0.01;

    union() {
        translate([-stalk_width/2, z0])
            square([stalk_width, stalk_height + 0.01]);

        translate([0, z0 + stalk_height])
            hull() {
                translate([-cap_width/2 + cap_height/2, 0])
                    circle(d=cap_height);

                translate([cap_width/2 - cap_height/2, 0])
                    circle(d=cap_height);

                translate([-stalk_width/2, 0])
                    square([stalk_width, cap_height/2]);
            }
    }
}

module carabiner_cutout() {
    xz_extrude(insert_width + 0.2)
        carabiner_cutout_profile();
}

difference() {
    arch_negative_space();
    carabiner_cutout();
}
