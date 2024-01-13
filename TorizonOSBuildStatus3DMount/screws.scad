$fa = $preview ? 6 : 1;
$fs = $preview ? 0.4: 0.1;

include <BOSL2/std.scad>
include <BOSL2/screws.scad>

screw_spacing = 25;

module screws(){
    left(screw_spacing) grid_copies(spacing = screw_spacing, n = [2, 3]) carrier_board_screw();
    right(screw_spacing) grid_copies(spacing = screw_spacing, n = [1, 3]) tv_screw();
}

module carrier_board_screw(){
    // to attach the carrier board to the mount
    scale([0.98, 0.98, 1])
    screw(
        "M3",
        head = "socket",
        drive = "torx",
        length = 7,
        thread = true,
        blunt_start2 = false,
        anchor = TOP+LEFT,
        orient = DOWN
    );
}

module tv_screw(){
    // to finely adjust the distance between the TV and the clip
    scale([0.98, 0.98, 1])
    screw(
        "M6",
        head = "socket",
        drive = "torx",
        length = 15,
        thread = true,
        blunt_start2 = false,
        anchor = TOP+RIGHT,
        orient = DOWN
    );
}

screws();
