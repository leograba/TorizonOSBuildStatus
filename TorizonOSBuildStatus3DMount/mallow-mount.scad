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

carrier_frame();