$fa = 1;
$fs = 0.4;
//$fn = 64;

include <BOSL2/std.scad>

mallow_width = 100;
mallow_height = 72;
mallow_depth = 5;
// the Mallow holes have radius 1.6mm and distance from hole to edge 1.4mm
// thus baord edge to hole center is 3mm
hole_padding = 3;
wall_padding = 2;
tvclip_height = 40;
// very small value for good intersection
delta = 0.001;

module tvclip(){
    // base frame to attach to the TV
    diff("tvclip_remove")
    tvclip_frame(){
        tag("tvclip_remove") tvclip_carving();
    }
}

module tvclip_frame(){
    rect_tube(
        size=[mallow_width / 3, mallow_height / 2],
        // some arbitrary numbers that looked good
        wall = 3, rounding = 4, ichamfer = 4,
        height = tvclip_height,
        anchor = BOTTOM){
            position(CENTER+BOTTOM) children(0); // carving area
            position(BACK+BOTTOM) dovetail_carving();
        }
}

module tvclip_carving(){
    translate([0, - 6, mallow_depth / 2]) cuboid(
        size = [
            mallow_width / 3 + delta,
            mallow_height / 2,
            tvclip_height - 2 * mallow_depth / 2],
        anchor = BOTTOM
    );
}

module dovetail_carving(){
    // carving to insert and lock the dovetail
    diff("dovetail_snap")
    prismoid(
        // the carving can have the same height as the housing
        // because it will also carve the carrier frame wall
        size1=[mallow_width / 4 - 2 * wall_padding, mallow_height / 5],
        size2=[mallow_width / 4 - 4 * wall_padding, mallow_height / 5],
        h = mallow_depth / 2 + delta,
        anchor = FRONT+BOTTOM
    ){
        position(BOTTOM) tag("dovetail_snap") cyl(
            length = mallow_width / 10,
            d = wall_padding / 3,
            rounding = wall_padding / 10,
            orient = LEFT
        );
    }
}

tvclip();
