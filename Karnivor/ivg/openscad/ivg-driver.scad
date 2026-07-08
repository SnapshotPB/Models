// ivg-driver.scad -- pin-spanner tool to screw the scalloped IVG in and out.
//
// A plug that slides into the cup cavity (self-centering), with drive pins on
// its face that drop into the IVG's floor holes, and a fluted grip to turn it
// by hand. The IVG has four holes (90 deg apart); the tool lays out four
// matching pins but its full-length side slot carves the +Y one away, leaving
// three -- the slot is exactly why the fourth pin can't exist. A 6 mm hole runs
// all the way THROUGH the tool, matching the IVG's center bore. Mating dims come
// from the SAME shared file the IVG uses, so the pins always match the holes.
//
// Length is capped at 1" (pin tips -> grip end); see the assert below.
include <lib/ivg_shared.scad>

$fn = 64;

/* [Fit] */
fit_clear   = 0.30;   // pin slip fit into the drive holes (diametral)
plug_clear  = 0.00;   // plug-to-cavity-wall clearance (diametral)

/* [Sizes] */
pin_engage  = 1.6;    // pin protrusion into the floor holes
grip_h      = 11.0;   // grip height
flutes      = 14;     // finger flutes cut into the grip
flute_d     = 2.6;
center_fn   = 120;    // facets on the center through-hole

/* [Slot] */
slot        = true;   // full-length radial slot opening the center hole (+Y)

max_length  = 25.4;   // hard cap: 1", pins to opposite end

// ---- derived from the shared interface ----
pin_d    = drive_hole_d - fit_clear;   // slip fit into the drive holes
plug_d   = cavity_d     - plug_clear;  // slides into the cavity, centers the tool
grip_d   = plug_d;                     // UNIFORM diameter: grip == plug (flutes cut in)
plug_h   = cavity_depth;               // spans cavity so pins reach the floor
tool_len = pin_engage + plug_h + grip_h;

assert(tool_len <= max_length,
       str("driver length ", tool_len, " mm exceeds ", max_length, " mm (1\")"));

module tapered_pin(d, len, tip = 0.5) {    // built pointing +Z, lead-in on top
    union() {
        cylinder(d = d, h = len - tip);
        translate([0, 0, len - tip]) cylinder(d1 = d, d2 = d - 2*tip, h = tip);
    }
}

module grip() {
    difference() {
        cylinder(d = grip_d, h = grip_h);
        for (i = [0 : flutes - 1])
            rotate([0, 0, i * 360 / flutes])
                translate([grip_d/2, 0, -0.1])
                    cylinder(d = flute_d, h = grip_h + 0.2);
    }
}

module driver() {
    difference() {
        union() {
            grip();                                              // z 0..grip_h
            translate([0, 0, grip_h]) cylinder(d = plug_d, h = plug_h);
            // four pins to match the IVG's four holes; the +Y (90 deg) pin sits
            // inside the side slot below and gets carved away, leaving three.
            for (a = [0, 90, 180, 270])
                rotate([0, 0, a])
                    translate([drive_circle_r, 0, grip_h + plug_h])
                        tapered_pin(pin_d, pin_engage);
        }
        // center hole all the way through, matching the IVG bore
        translate([0, 0, -0.1])
            cylinder(d = bore_d, h = tool_len + 0.2, $fn = center_fn);

        // radial slot: full length, width = center hole (bore_d), from the axis
        // out to ONE edge only (a radius, not end-to-end). It opens toward +Y,
        // straight through where the fourth (90 deg) pin would be -- carving it
        // away so only three pins remain. Its walls are tangent to the bore, so
        // it reads as the bore opened out to the side.
        if (slot)
            translate([-bore_d/2, 0, -0.1])
                cube([bore_d, plug_d/2 + 1, tool_len + 0.2]);
    }
}

echo(str("DRIVER  len=", tool_len, "mm (<=", max_length, ")  3 pins d=", pin_d,
         " on R=", drive_circle_r, " (4th carved by slot)  center hole d=", bore_d,
         " thru"));

driver();
