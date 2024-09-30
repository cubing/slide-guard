FILE_REVISION = "v0.3.14   |   Lucas Garron   |   2024-09-29";

LOW_FI_DEV = false; // Enable this for faster iteration in OpenSCAD
INCLUDE_FLOATING_TEXT = false; // Can be lowered into the engraving as a different print color.

$fn = LOW_FI_DEV ? 9 : 256;

/*

## v0.3.14

- Add stacking plugs to the ledges.
- Change stacking plugs to be longer and fix up dimensions.
- Add floating text that can be used to fill engraving with a different-colo filament.

## v0.3.13

- Increase holder height by 1mm.
- Move small holes (for timer feet) forward 1mm.
- Add antibevel to the insides of the holders.
- Add anti-bevel to the middle support.

## v0.3.12

- Change the middle support to a bar that goes all the way to the end.
- Resize the big holes in the hopes of reducing forward-rocking.
- Remove x-axis contact spacing from the front stackings bevel.
- Remove contact spacing from the middle support plug.

## v0.3.11

- Reduce size of big holes.
- Adjust the stacking offset z to prevent the top of the clamp stacking port from showing as a thin slot through the top
of the plate.
- Adjust plexiglass holder to line up the top better.
- Move middle support closer to the timer.

## v0.3.10

- Lower trunk height by 0.5mm.
- Add side ledges.
- Add stacking bevels.
- Decrease y depth by 5mm.
- Add middle support.

## v0.3.9

- Slightly adjust the plexiglass slot dimensions.
- Move clamps 1mm apart (yet once more).

## v0.3.8

- Move clamps 1mm apart (once more).
- Reduce plexiglass slot dimensions back.

## v0.3.7

- Add big holes in the baseplate for volume reduction.
- Increase holder anti-bevel size.
- Remove bottom holder bevel.
- Increase plexiglass slot width.

## v0.3.6

- Set base plate height to `timer_ground_clearance`.
- Add holders.
- Carve plexiglass slot.

## v0.3.5

- Add a base plate (test height only)

## v0.3.4

- Changed ground clearance from 1.5mm to 1.2mm
- Added pincer top bevel.
- Changed pincer bottom bevel from 2mm to 3mm.

*/

// All units are millimeters.

EPSILON = 0.1;
CONTACT_SPACING = 0.2;
SNUG_CONTACT_ANTISPACING = 0.2;
INCH = 25.4;

DEFAULT_BEVEL_RADIUS = 2;

/********************************/

module duplicate_to_mirror_x() {
    children();
    if (!LOW_FI_DEV) {
        mirror([1, 0, 0]) children();
    }
}

/********************************/

plate_width_x = 250;
plate_depth_y = 68; // does NOT include pincers

module plate(extrude_height_z)
{
    translate([ -plate_width_x / 2, 0, 0 ]) linear_extrude(extrude_height_z)
    {
        import(file = "slide_guard_bracket_v0.3.13_plate.svg", dpi = INCH);
    }
}

/********************************/

bevel_lip = 1;

module round_bevel_cylinder(radius, width)
{
       translate([ 0, radius, radius ]) rotate([ 0, 90, 0 ]) cylinder(h = width + EPSILON, r = radius, center = true);
    
}

module round_bevel_complement(radius, width)
{
    difference()
    {
        translate([ 0, radius / 2 - bevel_lip / 2, radius / 2 - bevel_lip / 2 ])
            cube([ width, radius + bevel_lip, radius + bevel_lip ], center = true);
        round_bevel_cylinder(radius, width);
    }
}

/********************************/

plug_trunk_height = 4.55;
plug_trunk_radius = 21.1 / 2;
plug_head_lower_slope_height = 2.5; // 2.5 minus a bit to account for the rounded outside

port_barrel_outer_radius = 26 / 2;
port_clip_width = 7.9;

pincer_flex = 2;

pincer_bottom_bevel_radius = 3;

module clamp_carver(z_rot)
{
    z = plug_trunk_height + 1;
    rotate([ 0, 0, z_rot ]) union()
    {
        translate([ port_barrel_outer_radius - z / 2, 0, z ]) rotate([ 0, 45, 0 ]) translate([ 0, 0, z / 2 ])
            cube([ 10, port_clip_width + 2 * CONTACT_SPACING - SNUG_CONTACT_ANTISPACING, z ], center = true);

        translate([ 0, port_clip_width / 2, plug_trunk_height + plug_head_lower_slope_height ]) mirror([ 0, 0, 1 ])
            round_bevel_complement(radius = DEFAULT_BEVEL_RADIUS * 0.9,
                                   width = port_barrel_outer_radius * 2 + EPSILON * 2);

        mirror([ 0, 1, 0 ]) translate([ 0, port_clip_width / 2, plug_trunk_height + plug_head_lower_slope_height ])
            mirror([ 0, 0, 1 ]) round_bevel_complement(radius = DEFAULT_BEVEL_RADIUS * 0.9,
                                                       width = port_barrel_outer_radius * 2 + EPSILON * 2);
    }
}

module clamp(radius_epsilon)
{
    h = plug_trunk_height + plug_head_lower_slope_height;
    difference()
    {
        union()
        {
            translate([ 0, 0, h / 2 ]) cylinder(
                h = h, r = (port_barrel_outer_radius + radius_epsilon) + SNUG_CONTACT_ANTISPACING, center = true);

            // translate([ 0, (port_barrel_outer_radius + radius_epsilon), timer_ground_clearance / 2 ]) cube(
            //     [ (port_barrel_outer_radius + radius_epsilon) * 2, (port_barrel_outer_radius + radius_epsilon) * 2,
            //     timer_ground_clearance ], center = true);
        }

        union()
        {
            translate([ 0, 0, plug_trunk_height + plug_head_lower_slope_height / 2 + EPSILON / 2 ])
                cylinder(h = plug_head_lower_slope_height + EPSILON,
                         r1 = (port_barrel_outer_radius + radius_epsilon) - plug_head_lower_slope_height,
                         r2 = (port_barrel_outer_radius + radius_epsilon) + EPSILON, center = true);

            translate([ 0, 0, h / 2 ])
                cylinder(h = h + EPSILON, r = (plug_trunk_radius - radius_epsilon) - CONTACT_SPACING, center = true);

            clamp_carver(0);
            clamp_carver(90);
            clamp_carver(180);
            clamp_carver(270);
            translate([ 0, -10, 0 ])
                cube([ (plug_trunk_radius - radius_epsilon) * 2 - pincer_flex, 20, 20 ], center = true);

            MAGIC_NUMBER_TO_AVOID_TRIG = -9.115;
            // Bottom pincer bevel
            translate([ 0, MAGIC_NUMBER_TO_AVOID_TRIG, 0 ])
                round_bevel_complement(radius = pincer_bottom_bevel_radius,
                                       width = (port_barrel_outer_radius + radius_epsilon) * 2 + EPSILON * 2);

            // Top pincer bevel
            translate([ 0, MAGIC_NUMBER_TO_AVOID_TRIG, plug_trunk_height + plug_head_lower_slope_height ])
                mirror([ 0, 0, 1 ])
                    round_bevel_complement(radius = DEFAULT_BEVEL_RADIUS,
                                           width = (port_barrel_outer_radius + radius_epsilon) * 2 + EPSILON * 2);
        }
    }
}

module clamps(radius_epsilon)
{
    interclamp_distance = 204 - 25.7 + 2;

    translate([ interclamp_distance / 2, 0, 0 ]) clamp(radius_epsilon);
    translate([ -interclamp_distance / 2, 0, 0 ]) clamp(radius_epsilon);

    main_width = 10 * INCH;
    length = 2 * INCH;
}

/********************************/

timer_ground_clearance = 1.2;

holder_width_x = 15;
holder_depth_y = 9;
holder_height_z = INCH + 1; // 1 to accommodate for imperfect plexiglass and plastic.
holder_bevel_radius = 10;
holder_front_antibevel_radius = plug_trunk_height;

plexiglass_carving_width_x = 9 * INCH + 1 + CONTACT_SPACING * 2;
plexiglass_carving_depth_y = INCH / 8 - SNUG_CONTACT_ANTISPACING / 2; // snug
plexiglass_carving_height_z = holder_height_z + EPSILON; // 0.5 to accommodate for imperfect plexiglass and plastic.

plexiglass_inset_z = 0.5;

stacking_offset_y = holder_depth_y;
stacking_offset_z = timer_ground_clearance + plug_trunk_height +
                    0.2; // 0.2 avoids the top of the clamp stacking receiver from showing through the top of the plate.

module middle_plexiglass()
{
    translate([
        0, plate_depth_y - holder_depth_y / 2, plexiglass_carving_height_z / 2 + timer_ground_clearance + EPSILON / 2 -
        plexiglass_inset_z
    ]) cube([ plexiglass_carving_width_x, plexiglass_carving_depth_y, plexiglass_carving_height_z + EPSILON ],
            center = true);
}

stacking_holder_bevel = 2;

module uncarved_holder()
{
    difference()
    {
        translate([ -plate_width_x / 2, plate_depth_y - holder_depth_y, timer_ground_clearance - plexiglass_inset_z ])
            cube([ holder_width_x, holder_depth_y, holder_height_z ]);

        translate([
            -plate_width_x / 2, plate_depth_y - holder_depth_y / 2, holder_height_z + timer_ground_clearance -
            plexiglass_inset_z
        ]) rotate([ 0, 0, -90 ]) mirror([ 0, 0, 1 ])
            round_bevel_complement(radius = holder_bevel_radius, width = holder_depth_y + EPSILON);
    }

    translate([ -plate_width_x / 2 + holder_width_x / 2, plate_depth_y - holder_depth_y, timer_ground_clearance ])
        mirror([ 0, 1, 0 ]) round_bevel_complement(radius = holder_front_antibevel_radius, width = holder_width_x);

difference() {
    translate([-plate_width_x / 2 + holder_width_x, plate_depth_y - holder_depth_y / 2 - holder_front_antibevel_radius / 2, timer_ground_clearance])
    rotate([0, 0, -90])
    round_bevel_complement(radius = holder_front_antibevel_radius, width = holder_depth_y + holder_front_antibevel_radius);


    translate([ -plate_width_x / 2 + holder_width_x, plate_depth_y - holder_depth_y, timer_ground_clearance ])
        mirror([ 0, 1, 0 ]) round_bevel_cylinder(radius = holder_front_antibevel_radius, width = holder_width_x);
}
}


module holders()
{
    difference()
    {
        union()
        {
            duplicate_to_mirror_x() uncarved_holder();
        }
        middle_plexiglass();
    }
}

/********************************/

stacking_ledge_depth_y = 60;
stacking_ledge_width_x = 7;
stacking_front_radius = 5;

module left_ledge()
{
    intersection()
    {
        union()
        {
            translate([ -plate_width_x / 2, plate_depth_y - stacking_ledge_depth_y - holder_depth_y, 0 ])
            {
                cube([ stacking_ledge_width_x, stacking_ledge_depth_y, stacking_offset_z ]);
            }

            translate([
                -plate_width_x / 2 + stacking_ledge_width_x, plate_depth_y - stacking_ledge_depth_y / 2,
                timer_ground_clearance
            ]) rotate([ 0, 0, -90 ]) round_bevel_complement(radius = plug_trunk_height, width = stacking_ledge_depth_y);
        }

        plate(stacking_offset_z + 20);
    }

    translate([ -plate_width_x / 2 + stacking_ledge_width_x / 2, plate_depth_y - holder_depth_y, stacking_offset_z ])
        mirror([ 0, 1, 0 ])
            round_bevel_complement(radius = holder_front_antibevel_radius, width = stacking_ledge_width_x);
}
module ledges()
{
    duplicate_to_mirror_x() left_ledge();
}

/********************************/

module front_stacking_bevel_left()
{

    translate([ -plate_width_x / 2 + stacking_ledge_width_x / 2 - EPSILON / 2, plate_depth_y, 0 ]) mirror([ 0, 1, 0 ])
        round_bevel_complement(radius = holder_front_antibevel_radius + CONTACT_SPACING,
                               width = stacking_ledge_width_x + EPSILON);
}

module front_stacking_bevels()
{
    front_stacking_bevel_left();
    mirror([ 1, 0, 0 ]) front_stacking_bevel_left();
}

/********************************/

middle_support_depth_y = 43;
middle_support_center_y = 46.5;
middle_support_uncarved_width_x = 10;

module middle_support()
{

            difference()
            {
                translate([ 0, middle_support_center_y, stacking_offset_z / 2 ])
                    cube([ middle_support_uncarved_width_x, middle_support_depth_y, stacking_offset_z ], center = true);

                translate([ 0, middle_support_center_y - middle_support_depth_y / 2, stacking_offset_z ])
                    mirror([ 0, 0, 1 ]) round_bevel_complement(radius = plug_trunk_height / 2,
                                                               width = middle_support_uncarved_width_x + EPSILON);
                // translate([ 0, middle_support_center_y + middle_support_depth_y / 2, stacking_offset_z ])
                //     mirror([ 0, 1, 1 ]) round_bevel_complement(radius = plug_trunk_height / 2,
                //                                                width = middle_support_uncarved_width_x + EPSILON);

                translate([ -middle_support_uncarved_width_x / 2, middle_support_center_y, stacking_offset_z ])
                    rotate([ 0, 0, -90 ]) mirror([ 0, 0, 1 ])
                        round_bevel_complement(radius = stacking_offset_z / 2, width = 50);

                mirror([ 1, 0, 0 ])
                    translate([ -middle_support_uncarved_width_x / 2, middle_support_center_y, stacking_offset_z ])
                        rotate([ 0, 0, -90 ]) mirror([ 0, 0, 1 ])
                            round_bevel_complement(radius = stacking_offset_z / 2, width = 50);
            }

            translate([ 0, middle_support_center_y - middle_support_depth_y / 2, timer_ground_clearance ])
                mirror([ 0, 1, 0 ])
                    round_bevel_complement(radius = plug_trunk_height / 2, width = middle_support_uncarved_width_x);

            // translate([ 0, middle_support_center_y + middle_support_depth_y / 2, timer_ground_clearance ])
            //     mirror([ 0, 0, 0 ])
            //         round_bevel_complement(radius = plug_trunk_height / 2, width = middle_support_uncarved_width_x);
  
    difference() {
        union() {
            translate([ -middle_support_uncarved_width_x / 2, middle_support_center_y - plug_trunk_height / 4, timer_ground_clearance ])
                rotate([ 0, 0, -90 ]) mirror([ 0, 1, 0 ])
                    round_bevel_complement(radius = stacking_offset_z / 2, width = middle_support_depth_y + plug_trunk_height/2);

            mirror([1, 0, 0])
                translate([ -middle_support_uncarved_width_x / 2, middle_support_center_y - plug_trunk_height / 4, timer_ground_clearance ])
                    rotate([ 0, 0, -90 ]) mirror([ 0, 1, 0 ])
                        round_bevel_complement(radius = stacking_offset_z / 2, width = middle_support_depth_y + plug_trunk_height/2);
        }
        translate([ 0, middle_support_center_y - middle_support_depth_y / 2, timer_ground_clearance ])
            mirror([ 0, 1, 0 ])
                round_bevel_cylinder(radius = plug_trunk_height / 2, width = middle_support_uncarved_width_x + plug_trunk_height);
        
    }

}

/********************************/

stacking_plug_radius = 2;
stacking_plug_height_z = 2;
stacking_plug_central_depth_y = 5;

middle_support_plug_center_y = 32;
ledge_support_plug_center_y = 42;

// Extends below as much as it extends above.
module middle_support_stacking_plug(extra_spacing) {
    // TODO: Minkowski sum of a cylinder and a line?
    translate([ 0, -stacking_plug_central_depth_y / 2, -stacking_plug_height_z - extra_spacing ])
        cylinder(h = stacking_plug_height_z * 2 + extra_spacing * 2 , r = stacking_plug_radius + extra_spacing);
    translate([ 0, stacking_plug_central_depth_y / 2, -stacking_plug_height_z - extra_spacing ])
        cylinder(h = stacking_plug_height_z * 2 + extra_spacing * 2, r = stacking_plug_radius + extra_spacing);

    translate([0, 0, 0])
        cube([stacking_plug_radius * 2 + extra_spacing * 2, stacking_plug_central_depth_y, stacking_plug_height_z * 2 + extra_spacing * 2], center=true);
}

module stacking_plugs()
{
    translate([0, 0, stacking_offset_z])
    {
        translate([0, middle_support_plug_center_y, 0]) middle_support_stacking_plug(0);
        duplicate_to_mirror_x() translate([- plate_width_x / 2 + stacking_ledge_width_x / 2, ledge_support_plug_center_y, 0]) middle_support_stacking_plug(0);
    }
}

module stacking_sockets() {
    translate([0, middle_support_plug_center_y + stacking_offset_y, 0]) middle_support_stacking_plug(CONTACT_SPACING);
    duplicate_to_mirror_x() translate([- plate_width_x / 2 + stacking_ledge_width_x / 2, ledge_support_plug_center_y + stacking_offset_y, 0]) middle_support_stacking_plug(CONTACT_SPACING);
}

/********************************/

version_text_offset_y = 10;

module version_text() {
    translate([0, version_text_offset_y, 0])
        text(FILE_REVISION, size = 5, font = "Ubuntu:style=bold", valign = "center", halign = "center");
}

/********************************/

engraving_depth = 0.5;
floating_text_offset_z = 10;

module main()
{
    difference()
    {
        union()
        {
            plate(timer_ground_clearance);
            clamps(0);
            holders();
            ledges();
            middle_support();
            stacking_plugs();
            if (INCLUDE_FLOATING_TEXT) {
                translate([ 0, 0, timer_ground_clearance - engraving_depth + floating_text_offset_z]) linear_extrude(engraving_depth ) version_text();
            }
        }

        union()
        {
            middle_plexiglass();
            front_stacking_bevels();
            translate([ 0, holder_depth_y + EPSILON, -stacking_offset_z - EPSILON ])
                clamps(EPSILON);
            translate([ 0, 0, timer_ground_clearance - engraving_depth ]) linear_extrude(engraving_depth * 2)
                version_text();
            stacking_sockets();
        }
    }
}

/********************************/

main();
