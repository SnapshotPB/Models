// lib/ivg_shared.scad -- single source of truth for the IVG <-> driver interface.
// Included by models/ivg.scad AND models/ivg-driver.scad so the two parts can
// never drift out of sync. Contains NO geometry (safe to include).
//
// build.sh globs models/*.scad (non-recursive), so this file is not rendered.

// ---- fundamental inputs ----
D                = 19.05;      // thread major diameter (3/4")
P                = 25.4/16;    // pitch (16 TPI) = 1.5875
thread_clearance = 0.15;       // radial crest shrink for print fit (0 = nominal)
length           = 12.7;       // overall length (0.5")
bore_d           = 6.0;        // center through-bore diameter
scallop_wall     = 1.2;        // radial wall left at the thread ROOT
scallop_floor    = 1.2;        // floor thickness on the closed end
drive_wall       = 0.8;        // min material around the two drive holes

// ---- derived thread / cavity geometry ----
H        = 0.8660254 * P;                 // sharp 60-deg triangle height
h        = 5/8 * H;                        // engaged thread depth
rroot    = D/2 - h;                        // thread minor radius
rcrest   = D/2 - thread_clearance;         // thread crest radius
cavity_r = rroot - scallop_wall;           // scalloped cavity radius
cavity_d = 2 * cavity_r;
cavity_depth = length - scallop_floor;     // hollow depth (floor to open rim)

// ---- derived drive-hole interface --------------------------------------
// Four identical holes, 90 deg apart, sized as large as fits in the radial
// band between the center bore and the cavity wall (both offset by drive_wall),
// and within cavity_r so a straight-in pin tool reaches them from the open end.
// The IVG cuts all four; the driver fills three (its side slot omits the +Y
// one). Count/positions live in the part files -- only size + bolt circle here.
_r_in          = bore_d/2 + drive_wall;    // inner keep-out (center bore)
_r_out         = cavity_r - drive_wall;    // outer keep-out (cavity wall)
drive_hole_d   = _r_out - _r_in;           // largest hole that fits the band
drive_circle_r = (_r_in + _r_out) / 2;     // bolt-circle radius of the pair
