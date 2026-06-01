$fn = 96;

disk_diameter = 34;
disk_thickness = 3;
disk_top_chamfer = 0.6;

thread_height = 7;
tripod_pitch = 25.4 / 20;      // 1/4-20 UNC
thread_clearance = 0.15;       // Reduces nominal diameter for printed fit.
thread_major_diameter = 6.35 - thread_clearance;
thread_minor_diameter = 4.95;
thread_segments = 128;
thread_slices_per_turn = 24;

module disk_with_top_chamfer(diameter, height, chamfer) {
    radius = diameter / 2;

    rotate_extrude()
        polygon([
            [0, 0],
            [radius, 0],
            [radius, height - chamfer],
            [radius - chamfer, height],
            [0, height]
        ]);
}

function wrap01(x) = x - floor(x);
function thread_profile(phase, crest_width = 0.12, root_width = 0.18) =
    let(d = min(wrap01(phase), 1 - wrap01(phase)))
    d <= crest_width / 2 ? 1 :
    d >= 0.5 - root_width / 2 ? 0 :
    (0.5 - root_width / 2 - d) / (0.5 - root_width / 2 - crest_width / 2);

function thread_radius(angle, z, major_radius, minor_radius, pitch) =
    minor_radius + (major_radius - minor_radius) *
    thread_profile(angle / 360 - z / pitch);

module printable_external_thread(major_diameter, minor_diameter, height, pitch) {
    major_radius = major_diameter / 2;
    minor_radius = minor_diameter / 2;
    slices = ceil(height / pitch * thread_slices_per_turn);

    points = concat(
        [
            for (i = [0:slices])
                for (j = [0:thread_segments - 1])
                    let(
                        z = height * i / slices,
                        angle = 360 * j / thread_segments,
                        r = thread_radius(angle, z, major_radius, minor_radius, pitch)
                    )
                    [r * cos(angle), r * sin(angle), z]
        ],
        [[0, 0, 0], [0, 0, height]]
    );

    bottom_center = (slices + 1) * thread_segments;
    top_center = bottom_center + 1;

    side_faces = [
        for (i = [0:slices - 1])
            for (j = [0:thread_segments - 1])
                for (tri = [0:1])
                    let(
                        a = i * thread_segments + j,
                        b = i * thread_segments + ((j + 1) % thread_segments),
                        c = (i + 1) * thread_segments + ((j + 1) % thread_segments),
                        d = (i + 1) * thread_segments + j
                    )
                    tri == 0 ? [a, b, c] : [a, c, d]
    ];

    bottom_faces = [
        for (j = [0:thread_segments - 1])
            [bottom_center, (j + 1) % thread_segments, j]
    ];

    top_faces = [
        for (j = [0:thread_segments - 1])
            [
                top_center,
                slices * thread_segments + j,
                slices * thread_segments + ((j + 1) % thread_segments)
            ]
    ];

    polyhedron(points = points, faces = concat(side_faces, bottom_faces, top_faces), convexity = 6);
}

union() {
    disk_with_top_chamfer(disk_diameter, disk_thickness, disk_top_chamfer);

    translate([0, 0, disk_thickness])
        printable_external_thread(
            thread_major_diameter,
            thread_minor_diameter,
            thread_height,
            tripod_pitch
        );
}
