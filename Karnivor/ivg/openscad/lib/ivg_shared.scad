// lib/ivg_shared.scad -- single source of truth for the IVG <-> driver interface.
// Included by models/ivg.scad AND models/ivg-driver.scad so the two parts can
// never drift out of sync. Contains NO geometry (safe to include).
//
// build.sh globs models/*.scad (non-recursive), so this file is not rendered.

// ---- fundamental inputs ----
D                = 19.05;      // thread major diameter (3/4") -- HELD EXACTLY
P                = 25.4/16;    // pitch (16 TPI) = 1.5875
thread_clearance = 0.06;       // radial PITCH-dia relief for print fit (0 = nominal)
                               // Taken out of the FLANKS, never the crest, so the
                               // outside diameter is always exactly D. 0.06 here
                               // reproduces the pitch dia the old 0.15 crest-shrink
                               // gave (PD 17.899) -- same fit, full 3/4" OD.
length           = 12.7;       // overall length (0.5")
bore_d           = 6.0;        // center through-bore diameter
scallop_wall     = 2.5;        // radial wall left at the thread ROOT
scallop_floor    = 6.75;        // floor thickness on the closed end (17/64")
drive_wall       = 0.8;        // min material around the two drive holes

// ---- derived thread / cavity geometry ----
H        = 0.8660254 * P;                 // sharp 60-deg triangle height
h        = 5/8 * H;                        // engaged thread depth
rroot    = D/2 - h;                        // thread minor radius
rcrest   = D/2;                            // crest == nominal major radius. NEVER
                                           // offset this: it IS the 3/4" OD.
cavity_r = rroot - scallop_wall;           // scalloped cavity radius
cavity_d = 2 * cavity_r;
cavity_depth = length - scallop_floor;     // hollow depth (floor to open rim)

// ---- derived thread-form angles (one pitch = 360 deg of cam rotation) ----
// Basic UN profile: root flat P/4 -> 90 deg, each flank 5P/16 -> 112.5 deg,
// crest flat P/8 -> 45 deg.
//
// Clearance is applied by backing BOTH FLANKS off radially by thread_clearance,
// which thins the tooth axially by 2*tc*tan(30) at every radius. As a fraction
// of one pitch that is `flank_relief` degrees, and it lands entirely on the two
// flats: the root flat widens by it, the crest flat narrows by it. A_FLANK is
// untouched, so the flank slope stays tan(30) -- a true 60-deg form at ANY
// clearance -- and rcrest stays at D/2, so the OD stays 19.05 at any clearance.
flank_relief = 360 * (2 * thread_clearance * 0.5773503) / P;

A_FLANK = 112.5;                           // 5P/16 axial rise; fixes the 60-deg flank
A_ROOT  = 90 + flank_relief;               // root flat, widened by the relief
A_CREST = 45 - flank_relief;               // crest flat, narrowed by the same

// Pitch dia: the radius where tooth width == P/2, i.e. t = (90-relief)/225 up
// the root->crest span. Nominal (relief 0) lands on 18.0189 = D - 0.64952*P.
pitch_d = 2 * (rroot + h * (90 - flank_relief) / 225);

assert(A_CREST > 2, str("thread_clearance ", thread_clearance,
       " eats the crest flat (A_CREST = ", A_CREST, " deg). Max is ",
       45 * P / (720 * 0.5773503), " mm."));

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
