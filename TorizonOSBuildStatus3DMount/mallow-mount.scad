$fa = 1;
$fs = 0.4;
//$fn = 64;

include <BOSL2/std.scad>
include <BOSL2/screws.scad>
include <NopSCADlib/vitamins/antennas.scad>

mallow_width = 100;
mallow_height = 72;
mallow_depth = 5;
// the Mallow holes have radius 1.6mm and distance from hole to edge 1.4mm
// thus baord edge to hole center is 3mm
hole_padding = 3;
wall_padding = 2;
// very small value for good intersection
delta = 0.001;

module carrier_frame(){
    diff("remove_screws")
        // base frame to attach the Mallow
        rect_tube(
            size=[mallow_width + wall_padding, mallow_height + wall_padding],
            // some arbitrary numbers that looked good
            wall = 3, rounding = 4, ichamfer = 8, height = mallow_depth,
            anchor = BOTTOM)
            {
                // add one element to each side
                for ( dx = [
                            -mallow_width / 2 + hole_padding,
                            +mallow_width / 2 - hole_padding
                            ]) {
                    // add one element to each of the four edges
                    for ( dy = [
                                -mallow_height / 2 + hole_padding,
                                +mallow_height / 2 - hole_padding
                                ]) {
                        translate([dx, dy, 0]) {
                            // screw holes
                            tag("remove_screws") screw_hole(
                                "M3", head = "flat small",
                                length = 18,
                                thread = true,
                                anchor = BOTTOM
                                );
                            // top padding to avoid the pin headers hitting the frame
                            position(TOP) cyl(
                                r1 = 3, r2 = 2.5, h = 10,
                                rounding1 = -1,
                                anchor = BOTTOM);
                        }
                    }
                }

                // ready for dual-antenna setup
                antenna_holder(LEFT, -mallow_width / 2);
                antenna_holder(RIGHT, +mallow_width / 2);

                // dovetail to connect the base
                translate([0, -mallow_height / 2 + wall_padding, 0]){
                    dovetail_housing();
                    translate([0, 2 * wall_padding, 0])
                        tag("remove_screws") dovetail_carving();
                }
            }
}

module antenna_holder(holder_side=LEFT, holder_xpos=0){
    diff("remove_antennas")
        translate ([holder_xpos, 0, 0]){
            // extends the base frame
            prismoid(
                size1 = [mallow_depth, mallow_height / 2],
                size2 = [mallow_depth, mallow_height / 5],
                h = 1.5 * antenna_bot_d(ESP201_antenna),
                orient = holder_side){
                    prismoid(
                        anchor=holder_side,
                        size1 = [mallow_depth / 4, mallow_height / 2],
                        size2 = [mallow_depth * 2.5, mallow_height / 5],
                        h = 1.5 * antenna_bot_d(ESP201_antenna),
                        shift = (holder_side == LEFT) ? [3, 0] : [-3, 0]
                    );
            }
            rotate ([90, 0, 0]){
                // use dimensions of the antenna included in NopSCADlib
                // to create the C-section
                antenna_pad = (holder_side == LEFT) ? -7 : 7;
                translate ([antenna_pad, 5, 0]){
                    tag("remove_antennas") cyl(
                        h = antenna_length(ESP201_antenna),
                        d1 = antenna_bot_d(ESP201_antenna),
                        d2 = antenna_top_d(ESP201_antenna)
                    );
                }
            }
        }
}

module dovetail_housing(){
    // dovetail to connect the base
    cuboid(
        size = [mallow_width / 4, mallow_height / 5, mallow_depth],
        rounding = 1,
        edges = [BACK],
        anchor = CENTER+FRONT
    ){
        position(BOTTOM+FRONT+LEFT) wedge(
            size = [mallow_depth, mallow_depth, mallow_depth],
            spin = [0, 90, 90],
            //center = true,
            anchor = RIGHT+FRONT+BOTTOM
        );
        position(BOTTOM+FRONT+RIGHT) wedge(
            size = [mallow_depth, mallow_depth, mallow_depth],
            spin = [0, 90, 0],
            //center = true,
            anchor = RIGHT+FRONT+BOTTOM
        );
    }
}

module dovetail_carving(){
    // carving to insert and lock the dovetail
    diff("dovetail_snap")
    prismoid(
        // the carving can have the same height as the housing
        // because it will also carve the carrier frame wall
        size1=[mallow_width / 4 - 2 * wall_padding, mallow_height / 5],
        size2=[mallow_width / 4 - 4 * wall_padding, mallow_height / 5],
        h = mallow_depth / 2 + delta
    ){
        position(BOTTOM) tag("dovetail_snap") cyl(
            length = mallow_width / 10,
            d = wall_padding / 2,
            rounding = wall_padding / 10,
            orient = LEFT
        );
    }
}

carrier_frame();
