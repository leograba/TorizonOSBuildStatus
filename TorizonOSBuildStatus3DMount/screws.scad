$fa = $preview ? 6 : 1;
$fs = $preview ? 0.4: 0.1;

include <BOSL2/std.scad>
include <BOSL2/screws.scad>

module screws(){
    grid_copies(spacing = 100, n = [3, 3]) single_screw();
}

module single_screw(){
    scale([0.98, 0.98, 1])
    screw(
        "M3",
        head = "socket",
        drive = "torx",
        length = 7,
        thread = true,
        blunt_start2 = false,
        anchor = TOP,
        orient = DOWN
    );
}

screws();
