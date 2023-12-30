$fa = 1;
$fs = 0.4;
//$fn = 64;

include <BOSL2/std.scad>
include <BOSL2/screws.scad>

module screws(){
    grid_copies(spacing = 15, n = [2, 3]) single_screw();
}

module single_screw(){
    screw(
        "M3",
        head = "socket",
        drive = "hex",
        length = 10,
        thread = true,
        anchor = TOP,
        orient = DOWN
    );
}

screws();
