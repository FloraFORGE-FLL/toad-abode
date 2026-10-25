// Toad Abode
// A ground-level toad house: a faceted, gem-like dome with a roomy, dark cave
// inside and a rain-catching cup in the top.
//
//  - Dome is 180 mm across at the ground (200 mm over the flange), 108 mm tall
//  - Clean faceted shell: rings of flat triangular facets, staggered so they
//    interlock like a geodesic dome (or stacked trapezoids, see facet_offset)
//  - Thin, even 4 mm walls: the cave is faceted to match the outside, so it
//    fills almost the whole dome
//  - Tall archway at ground level: straight sides rising into a round arch
//    with a softened 45 degree crown, bevelled at the mouth
//  - Drift-well: a deep cup with vertical sides and a bowl-shaped floor that
//    hangs into the cave. Rain pools in the middle of the bowl; a ring of tiny
//    holes lets it drip slowly onto the soil below, leaving a puddle to drink
//  - Thin base flange, filleted into the wall, beds into the soil to seal the
//    cave and steady the house
//  - Open bottom, so the toad sits on damp earth
//
// Printing: print upright on the flange (part = "model"). The walls and the
// archway print without help, but the upper cave roof and the underside of the
// cup are steeper than 45 degrees: turn on tree supports from the build plate.
// They come out through the open bottom. Print height is 108 mm.

/* [Part to show / export] */
part = "model"; // ["model", "section"]

/* [Color] */
print_color = "#5E7A4A"; // matte green

/* [Dome] */
dome_d   = 180; // outer diameter at the ground (mm)
dome_h   = 122; // height the profile would reach if not cut flat (mm)
top_z    = 108; // height of the flat rim, i.e. total height (mm)
fullness = 2.5; // profile exponent: 2 = ellipse, higher = fuller shoulders
wall     = 4;   // wall and roof thickness (mm)

/* [Facets] */
facets       = 16;  // facets around the dome
tiers        = 6;   // rings of facets from ground to rim
tier_curve   = 1.2; // > 1 packs rings closer near the top, evening out facet size
facet_offset = 0.5; // 0.5 = staggered triangles, 0 = stacked trapezoids

/* [Drift-well] */
well_d     = 76;  // cup diameter (mm)
well_depth = 24;  // depth from the rim to where the bowl floor starts (mm)
well_dip   = 8;   // how far the bowl floor sinks in the middle (mm)
cup_wall   = 3;   // thickness of the cup's sides and floor (mm)
well_lip   = 1.5; // 45 degree chamfer round the rim of the cup (mm)
drip_count = 4;   // drip holes through the cup floor
drip_ring  = 14;  // distance of the drip holes from the centre (mm)
drip_d     = 1.5; // drip hole diameter; smaller = slower (mm)

/* [Archway] */
entry_count  = 1;  // archways, spaced evenly
entry_w      = 70; // width at the ground (mm)
entry_spring = 14; // height of the straight sides (mm)
entry_round  = 35; // radius of the curve into the 45 degree crown; entry_w / 2 = round arch (mm)
entry_tip    = 8;  // rounding at the very top of the arch (mm)
entry_flare  = 6;  // how much the mouth widens at the outside (mm)

/* [Base flange] */
flange_w = 10;  // how far it sticks out past the dome (mm)
flange_t = 2.4; // thickness (mm)
fillet_r = 5;   // fillet between flange and wall (mm)

$fn = 96;

// --- DERIVED ---
R        = dome_d / 2;
Ri       = R - wall;                          // cave radius at the ground
Hi       = dome_h - wall;
well_r   = well_d / 2;
well_z   = top_z - well_depth;                // where the bowl floor meets the cup side
bowl_rho = (well_r * well_r + well_dip * well_dip) / (2 * well_dip); // bowl radius
bowl_c   = well_z - well_dip + bowl_rho;      // bowl centre height
e_c      = entry_w / 2 - entry_round;
e_x1     = e_c + entry_round * cos(45);       // archway: end of the curve
e_y1     = entry_spring + entry_round * sin(45);
e_top    = e_y1 + e_x1;                       // archway apex before rounding (~64 mm)

// Dome profile: radius at height z for a dome of radius a and height h
function prof(a, h, z) = a * pow(max(0, 1 - pow(max(z, 0) / h, fullness)), 1 / fullness);
// Height of facet ring j
function tier_z(j) = top_z * (1 - pow(1 - j / tiers, tier_curve));

// Faceted solid dome of radius a, height h: rings of points on the profile joined by
// flat triangles. The bottom ring sits at z0, the rest at the shared tier heights.
module facet_dome(a, h, z0 = 0) {
    na = facets; nz = tiers;
    b = (nz + 1) * na; // bottom centre point; top centre is b + 1
    pts = concat(
        [for (j = [0 : nz], i = [0 : na - 1])
            let(z = j == 0 ? z0 : tier_z(j), t = 360 * (i + (j % 2) * facet_offset) / na,
                r = prof(a, h, z))
                [r * cos(t), r * sin(t), z]],
        [[0, 0, z0], [0, 0, top_z]]);
    faces = concat(
        [for (j = [0 : nz - 1], i = [0 : na - 1], f = [0, 1])
            let(a = j * na + i, n = j * na + (i + 1) % na, u = a + na, v = n + na)
            facet_offset == 0 ? (f == 0 ? [a, u, v] : [a, v, n])
            : j % 2 == 0      ? (f == 0 ? [a, u, n] : [n, u, v])
            :                   (f == 0 ? [a, u, v] : [a, v, n])],
        [for (i = [0 : na - 1]) [b, i, (i + 1) % na]],
        [for (i = [0 : na - 1]) [b + 1, nz * na + (i + 1) % na, nz * na + i]]);
    polyhedron(pts, faces, convexity = 6);
}

// Thin ring round the base, matching the facets, with a concave fillet up into the wall
module flange() {
    rotate_extrude($fn = facets) difference() {
        union() {
            translate([Ri, 0]) square([R + flange_w - Ri - flange_t / 2, flange_t]);
            translate([R + flange_w - flange_t / 2, flange_t / 2]) circle(d = flange_t, $fn = 24);
            translate([Ri, 0]) square([R - Ri + fillet_r, flange_t + fillet_r]);
        }
        translate([R + fillet_r, flange_t + fillet_r]) circle(r = fillet_r, $fn = 48);
    }
}

// Cup shape grown by g: straight sides down to well_z, then a bowl-shaped floor
module cup_shape(g) {
    translate([0, 0, well_z]) cylinder(r = well_r + g, h = top_z - well_z + 1);
    intersection() {
        translate([0, 0, bowl_c]) sphere(r = bowl_rho + g, $fn = 192);
        translate([0, 0, well_z - well_dip - g - 1]) cylinder(r = well_r + g, h = well_dip + g + 1);
    }
}

// Drift-well: the cup, a chamfered lip, and a ring of drip holes through its floor
module well() {
    cup_shape(0);
    translate([0, 0, top_z - well_lip])
        cylinder(r1 = well_r, r2 = well_r + well_lip + 0.01, h = well_lip + 0.01);
    for (k = [0 : drip_count - 1])
        rotate([0, 0, 45 + k * 360 / drip_count])
            translate([drip_ring, 0, well_z - well_dip - cup_wall - 1])
                cylinder(d = drip_d, h = well_dip + cup_wall + 2, $fn = 16);
}

// Cave: the dome shrunk by the wall thickness, under the roof, around the hanging cup
module cave() {
    difference() {
        intersection() {
            facet_dome(Ri, Hi, -1);
            translate([-R, -R, -2]) cube([2 * R, 2 * R, top_z - wall + 2]);
        }
        cup_shape(cup_wall);
    }
}

// Archway outline: straight sides curving into a 45 degree crown with a softened tip
module arch_2d() {
    side = [[entry_w / 2, -2],
            for (a = [0 : 3 : 45]) [e_c + entry_round * cos(a), entry_spring + entry_round * sin(a)],
            [0, e_top]];
    offset(r = entry_tip) offset(delta = -entry_tip)
        polygon(concat(side, [for (k = [len(side) - 2 : -1 : 0]) [-side[k].x, side[k].y]]));
}

// Opening through the wall, bevelling out toward the mouth
module entry() {
    rotate([90, 0, 90]) {
        linear_extrude(R) arch_2d();
        hull() {
            translate([0, 0, R - 12]) linear_extrude(0.01) arch_2d();
            translate([0, 0, R + flange_w + 5]) linear_extrude(0.01) offset(delta = entry_flare) arch_2d();
        }
    }
}

module abode() {
    difference() {
        union() { facet_dome(R, dome_h); flange(); }
        cave();
        well();
        for (k = [0 : entry_count - 1]) rotate([0, 0, -90 + k * 360 / entry_count]) entry();
    }
}

// Render
color(print_color)
if (part == "section")
    difference() {
        abode();
        translate([0, 0, -1]) cube([R + flange_w + 1, R + flange_w + 1, top_z + 2]);
    }
else abode();
