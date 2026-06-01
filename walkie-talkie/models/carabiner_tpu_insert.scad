// TPU insert starting point for the walkie-talkie carabiner arch.
// This part models the negative space of the arch opening in
// carabiner_arch.scad so it can be trimmed into a soft carabiner liner.

// Keep these in sync with carabiner_arch.scad.
insert_width = 7;
arch_cutout_width = 15;
carabiner_clearance_height = 12;
inner_arch_chamfer = 3;
bottom_trim = 3;

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

arch_negative_space();
