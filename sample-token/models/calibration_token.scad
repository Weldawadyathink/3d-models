$fn = 64;

token_radius = 24;
token_height = 4;
rim_height = 1.2;
rim_width = 2.2;
hole_radius = 3.2;

module rounded_token() {
    cylinder(h = token_height, r = token_radius);
}

module raised_rim() {
    difference() {
        cylinder(h = rim_height, r = token_radius);
        translate([0, 0, -0.1])
            cylinder(h = rim_height + 0.2, r = token_radius - rim_width);
    }
}

module center_mark() {
    translate([0, 0, token_height])
        linear_extrude(height = 0.9)
            text("OS", size = 9, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
}

difference() {
    union() {
        rounded_token();
        translate([0, 0, token_height])
            raised_rim();
        center_mark();
        for (angle = [0:90:270]) {
            rotate([0, 0, angle])
                translate([13, 0, token_height])
                    cylinder(h = 1.1, r = 1.6);
        }
    }

    translate([0, token_radius - 8, -0.1])
        cylinder(h = token_height + rim_height + 1.4, r = hole_radius);

    for (angle = [45:90:315]) {
        rotate([0, 0, angle])
            translate([token_radius - 7, 0, -0.1])
                cylinder(h = token_height + 0.2, r = 1.2);
    }
}
