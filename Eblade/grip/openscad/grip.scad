// Eblade grip panel — parametric. Read panel() first; it is the whole part.
// plate() renders both hands; grip("right"/"left") renders one alone.
// Coordinates keep the source-mesh frame. Units: mm.
// Rationale, print history, rejected alternatives: see DESIGN.md.

// BOSL2 (local user library) — offset_sweep() chamfers the palm-face perimeter; see blank_swept().
include <BOSL2/std.scad>

/* [Panel] */
panel_thickness = 5.5;   // 5.0->5.5 (+0.5), ALL of it added at the BACK face to deepen the sear pocket 0.5mm more
                         //   (cutout_pocket 3.25->3.75) while holding cutout_floor at 1.75 — the pocket is back-face-
                         //   referenced, so panel and pocket grow 1:1 and the palm-side floor stock (and g2's web) are
                         //   preserved. The palm face is UNCHANGED: every dish's leave and the edge roll grew +0.5 in
                         //   step (scoop_front_leave, thumb_leave, edge_r), so all dish depths and the edge band hold.
corner_r = 0;            // [0:0.5:6]  fillet on groove cusps only; 0 = sharp

/* [Wall] */
// edge_r is capped so it leaves at least min_wall of straight wall at the perimeter (asserted).
// The finger scoops set their own front thickness (scoop_front_leave) and no longer answer to this.
min_wall      = 2.0;     // web left under a perimeter roll; caps edge_r (asserted)
min_wall_cutout = 1.0;     // floor for the roll-keepout math; the cutout floor is no longer this (now 2.0)

/* [Edges] */
// The palm (finger-scoop) face edge is ROLLED, not chamfered — this face is gripped tightly, so it
// must have no hard edges. The roll is an asymmetric bullnose (a quarter-ELLIPSE): it reaches far
// into the palm face but only modestly down the edge, tangent to the palm face at its mouth and to
// the straight wall at its foot, so the whole edge is curved with no crease at either end. See
// ellipse_roll() / blank_swept().
edge_r      = 3.5;       // roll DEPTH down the edge (vertical, z) = the ellipse's vertical semi-axis. Spends the palm
                         //   budget (panel_thickness - min_wall; asserted); 3.5 leaves exactly min_wall of straight
                         //   wall — the thin visible band the eye reads as the panel thickness. Grew 3.0->3.5 with the
                         //   +0.5 panel so the visible band stays min_wall (reads no thicker). 0 = sharp palm edge.
edge_r_reach = 5.0;      // roll REACH into the palm face (horizontal) = the ellipse's horizontal semi-axis, decoupled
                         //   from the depth. 5.0 (twice the old 2.5 round) makes a long, gentle dome that reads far
                         //   thinner than the 5.0mm panel and fills the hand smoothly. 0 = a circular round (reach =
                         //   edge_r); reach > edge_r = the shallow ellipse (what a gripped face wants).
edge_cham = 0;           // FLAT chamfer alternative (edge_cham = depth, edge_cham_top = reach into face). Leaves HARD
                         //   creases top and bottom — do NOT use on this gripped face; kept only for flat-edge parts.
                         //   Set only one of edge_cham / edge_r (asserted). 0 = off.
edge_cham_top = 5.0;     // reach into the face for the flat chamfer (unused while edge_cham = 0). 0 = 45° chamfer.
edge_r_back = 0;         // frame face mates flat; a roll here re-makes the unprintable groove-2 rail
edge_steps = 16;         // facets across each quarter-round / chamfer sweep
groove_round = 2.5;      // ROUNDED relief radius at the FRONT GROOVE edges so the finger scoops DIVE
                         //   smoothly into the perimeter round all along the arc. A concave fillet (cove)
                         //   coaxial with each groove, tangent to both the palm face and the groove wall —
                         //   see groove_reliefs(). Replaces the old 45 deg cone, which left flat facets and
                         //   hard creases off the valley (the "missing chamfer" the user hit). Reach >= the
                         //   scoop front depth (panel_thickness - scoop_front_leave = 2.0) to swallow the
                         //   scoop lip; 2.5 leaves exactly min_wall of straight wall at the groove (RIM). 0 = off.

/* [Outline] */
// Traced circular arcs, cut as arcs rather than approximated by contour points.
back_arc     = [45.88, 82.18];   // centre of the back (web) arc
back_arc_r   = 17.87;
back_edge_hi = [63.16, 77.66];   // arc lands tangent here; reflex vertex
back_edge_lo = [44.15,  4.90];   // sets the back-edge direction only; fillet re-derives tangency
strap_top    = [101.03, 53.29];

/* [Butt] */
// True stadium: flat bottom at butt_y, same radius both corners, strap tangent to butt_lr_x.
butt_y    = -2.43;
butt_r    = 5.84;
butt_lr_x = 81.19;       // front corner centre x

/* [Finger grooves] */
groove_r  = 14.55;                             // both grooves share one radius
finger_shift = 1.5;                            // WIDEN the grip: shift the whole finger region +X toward the
                                               //   front edge — both groove circles, their front-edge cusps
                                               //   (outline 7/8/9 = cusp3), and the squared top-front corner
                                               //   (tr_front_ref) move as one, so the front edge (and the grip's
                                               //   width) grows by this much through the fingers. The scoops
                                               //   follow the groove centres. 0 = as-traced from the scan.
// The finger cusps sat 2.8 mm low above g1's bottom: g1 was RESHAPED (its bottom cusp held on the
//   strap edge, its top cusp raised +2.8 -> centre moved back+up, ~1.2 mm deeper) and g2 TRANSLATED
//   +2.8 straight up. The scoops follow (they key off these centres). Spacing opened 16.7 -> 17.9.
groove_at = [[118.18 + finger_shift, 65.91], [121.39 + finger_shift, 83.54]];// arc centres, outside the panel; 17.9 mm apart (both +finger_shift in X)

/* [Finger scoops] */
// One cylinder per finger, laid on its side ALONG the finger and cut into the palm face as a
// smooth channel, then TILTED nose-down at the front: deepest at the groove edge (leaving
// scoop_front_leave of panel) and ramping up out of the material toward the rear, so the rear
// carries no scallop. scoop_angle is the tilt and the MAIN knob — a bigger angle ends the scallop
// closer to the front. Rounded (capsule) ends keep the walls and transitions smooth.
scoop_r           = 12;         // cylinder radius = the cross-finger cradle; bigger = wider, gentler
scoop_front_leave = [3.5, 3.97]; // [g1, g2] panel left behind the valley. g1 -> a full 2.0mm dish, held with the panel
                                //   (1.0 at 3mm, 2.0 at 4mm, 2.5 at 4.5mm, 3.0 at 5mm, 3.5 at 5.5mm). g2 sits 0.47 above
                                //   g1 (a shallower ~1.53mm dish) so its crest clears the sear pocket floor by ~0.4mm
                                //   (scoop_gap). Raised 3.77->3.97 (+0.2) to lift the WHOLE g2 dish 0.2mm off the pocket
                                //   without shortening its tail — so the thumb-index merge survives (angle would not).
                                //   Only g2 needs the extra — g1 is over solid stock. SCOOP echo reports the gap; 1:1.
scoop_angle       = [4, 4];     // [g1, g2] tilt nose-down at the front, deg — per finger, MAIN ramp knob.
                                //   g2 == g1 for now (long scallop). Lower = longer.
scoop_len         = 90;         // body length along the tilted axis; long enough to cover the ramp
scoop_aim         = [0, 0];     // in-plane splay per finger, deg off straight-rearward (+ toward butt)
scoop_fn          = 96;         // facets on the cutter (spheres)
scoop_gap         = 0.4;        // target clearance between groove 2's scoop and the sear cutout (checked, not set;
                                //   raised 0.2->0.4 for more wall over the solenoid). Held by scoop_front_leave[1].

/* [Thumb scoop] */
// A wide, deep relief for the thumb at the WEB of the hand (top-back). Built EXACTLY like a finger
// scoop (finger_scoop): a capsule laid on its side and TILTED nose-down, so it is deepest at one end
// (thumb_at) and ramps up out of the palm face toward the other — the same tapered scallop shape as
// the fingers, not a symmetric dish. Just a bigger cradle (thumb_r >> scoop_r) and, at 3 mm, deeper
// than the 2 mm finger dishes. It sits over solid panel (not the sear pocket), so the depth is capped
// only by the wall budget: thumb_leave >= min_wall (asserted). THUMB echo reports width/depth/taper.
thumb_at    = [64, 85];   // the DEEP end (anchor), where the scoop is deepest & widest — set right AT the back (web) edge
                          //   (edge is ~x63.5 here) so the full-depth end lands on the edge and bites the corner; its 3mm depth
                          //   matches the perimeter roll's 3mm there, so the two rounded surfaces blend (no hard edge). y=85
                          //   keeps it below H1. Push x lower to bite harder, but PAST the edge bites LESS (deep end goes off-panel)
thumb_leave = 2.5;        // panel left at the deep end -> dish depth = panel_thickness - thumb_leave (3.0). Grew 2.0->2.5
                          //   with the +0.5 panel so the 3.0mm thumb dish is unchanged. >= min_wall (asserted).
thumb_r     = 16;         // cradle radius = the cross-thumb width; >> scoop_r (12). Bigger = wider, gentler
thumb_angle = 6;          // tilt nose-down, deg, so the far end ramps out of the face -> a tapered scallop like the
                          //   fingers (their scoop_angle is 4). Higher = a shorter taper (fades sooner); lower = longer.
                          //   8->6 (a ~7mm-longer taper) so the thumb's fade-out OVERLAPS groove 2's (index) scoop
                          //   instead of pinching against it tip-to-tip: the web relief now flows into the index cradle
                          //   as one continuous valley (the old bowtie land is gone). Only the thumb is lengthened —
                          //   every finger scoop is untouched. Lower still = more overlap; 8 = the old sharp pinch.
thumb_aim   = 0;          // in-plane direction the scoop runs & fades FROM the deep end, deg (0=+x front, 90=+y top,
                          //   180=-x back, 270=-y butt). 0 = straight forward, PARALLEL to the level top edge — the thumb
                          //   lies along the top of the grip, so the channel runs horizontally from the web toward the front
thumb_len   = 32;         // capsule length along the tilted axis; long enough the far end sinks below the face (no cut there)
thumb_fn    = 96;         // facets on the cutter spheres
thumb_round = 1.5;        // ROUNDED relief on the thumb scoop's palm-face rim (radius, mm) — the "chamfer"
                          //   on the thumb cut. The fingers relieve their rim with a cove revolved about the
                          //   groove cylinder (groove_reliefs); the thumb sits in the open face with no such
                          //   axis, so thumb_relief() SWEEPS the same quarter-round, SKINNED (lofted) between
                          //   its cross-sections so it comes out smooth. Tangent to the palm face at its
                          //   mouth, so the sharp ~36 deg rim becomes a smooth roll. 0 = sharp thumb rim.
thumb_relief_fn = 32;     // rings sampling the quarter-round the cove is skinned from. Higher = smoother
                          //   roll; cheap (each ring is a hull of 2D circles, then offset+resampled).

/* [Sear solenoid cutout] */
cutout_w_asbuilt  = 17.14;               // as-built, off the source mesh
cutout_at         = [87.63, 82.34];      // bottom-wall corner; set so the scallop reads ~24.6 mm from
                                         //   the (level) top-edge opening (see CUTOUT echo)
cutout_trim_near = 1.0;    // +X wall pulled in; keeps the cutout/groove-2 rail printable
cutout_trim_far  = 3.0;    // -X wall pulled in
cutout_len = 28.26;        // bottom wall to poke-out top; ~3.7 of this is the poke past the top edge
cutout_pocket = 3.75;      // sear pocket DEPTH from the back face. 3.25->3.75 (+0.5), fed entirely by the +0.5 panel so
                           //   cutout_floor holds at 1.75 (floor stock and g2 web unchanged). Referenced to the back face.
cutout_floor = panel_thickness - cutout_pocket;  // material under the floor; grows with the panel, pocket stays put.
cutout_open_w = 18.25;     // opening width (top of the cut = the widest spot); floor stays cutout_w wide
cutout_tilt = 0;           // 0 = vertical, perpendicular to the level top edge (was 1.23 off +Y)

/* [Holes] */
hole_d = 4.5;            // drilled through; the cutout shortens H2's bore to cutout_floor
H2 = [97.79, 102.44];    // CONFIRMED on the marker. Datum — do not move.
H1 = [62.65, H2[1]];     // level with H2 (both sit 4.5 mm below the level top edge)
H3 = [63.01,   4.86];    // nudged +1.5 X (forward) and +0.5 Y (up) from [61.51, 4.36] (which was 4 mm
                         //   rear of [65.51, 4.36]). +X is forward (finger grooves), +Y is up toward the
                         //   top. Unverified — awaiting next print.
holes = [H1, H2, H3];

/* [Countersink] */
// Angled (conical) countersink on the PALM face (z = 0, the outer/grip face) so a flat-head screw
// seats below flush. cs_sink pushes the seat that far under the surface. Defaults are a #8 flat head
// (82° included, ~8.4 mm head) — the 4.5 mm hole is its clearance hole. H1/H3 get the full seat; H2
// sits over the sear cutout with only cutout_floor of palm-side stock, so its cone is CAPPED to leave
// cs_floor of stock — a shallower, smaller-mouth countersink whose head won't fully seat (CSINK echo).
cs_head_d = 8.4;                 // flat-head screw HEAD diameter (mm) = the full-seat mouth diameter
cs_angle  = 82;                  // included angle of the flat head (deg): 82 imperial (#-series), 90 metric
cs_sink   = 0.3;                 // depth the head seats BELOW the palm face (mm) — "below flush"
cs_floor  = 0.5;                 // min palm-side stock left under a countersink (mm); caps H2 over the cutout

/* [Logo] */
// Shallow engrave on the palm (finger-scoop) face, between the lower scoop and the bottom
// screw. Artwork is the Snapshot "S" mark (favicon-no-border.svg), imported directly — its
// filled path becomes the recessed area. The logo is mirrored in X so it reads right on the
// OUTER palm face (you view that face from behind the cut); grip() handles each hand. Swap
// logo_file freely; set logo_svg to the new art's
// bounding size (its viewBox w,h) so it stays centred.
// The real "S" artwork (logo.svg) is a trademark: gitignored, NOT distributed — so clones do not
// have it. The DEFAULT below is therefore logo.placeholder.svg, a committed valid-but-empty SVG
// (no drawable path): a clone imports a real file, the engrave cuts nothing, the console stays
// clean (no "Can't open file" error), and the panel renders unbranded. No toggle needed — the
// presence of the art is the only switch. Branded build (owner, with the real art present):
//     openscad -D 'logo_file="logo.svg"' -o stl/grip.stl openscad/grip.scad
// Both files carry the same viewBox (logo_svg), so logo centering is identical either way.
logo_file   = "logo.placeholder.svg";  // committed empty placeholder; override to "logo.svg" (the gitignored art) to brand
logo_center = [73, 32];          // palm-face placement (mm): x = back<->front, y = butt<->top
logo_width  = 18;                // overall width (mm); height follows the art's aspect (the S is tall)
logo_depth  = 0.2;               // engrave depth into the palm face (mm) — adjustable
logo_rotate = 0;                 // in-plane spin (deg)
logo_svg    = [18.894876, 35.957474];   // art bounding size (viewBox), for centring (art-specific)
logo_h      = logo_width * logo_svg[1] / logo_svg[0];   // derived height (mm)

/* [Output] */
plate_gap = 6;           // true edge-to-edge clearance between panels (see plate())

/* [Hidden] */
$fn = 48;
EPS = 0.01;

// ---------------------------------------------------------------------------
// contour
// ---------------------------------------------------------------------------

// Tangent point on circle (C,R) seen from external A; `side` picks which tangent.
function tangent_from(A, C, R, side = 1) =
    let(v = C - A, d = norm(v), L = sqrt(d*d - R*R),
        a = atan2(v[1], v[0]) + side * asin(R / d))
    A + L * [cos(a), sin(a)];

// Where line A->B crosses the horizontal y.
function line_at_y(A, B, y) = A + (y - A[1]) / (B[1] - A[1]) * (B - A);

// 2D cross product, and where line A->B meets line C->D.
function cross2(u, v) = u[0]*v[1] - u[1]*v[0];
function line_isect(A, B, C, D) =
    let(r = B - A, s = D - C)
    A + (cross2(C - A, s) / cross2(r, s)) * r;

// Distance from P to segment A-B.
function dist_pt_seg(P, A, B) =
    let(v = B - A, w = P - A, t = max(0, min(1, (w * v) / (v * v))))
    norm(P - (A + t * v));

butt_lr = [butt_lr_x, butt_y + butt_r];
strap_T = tangent_from(strap_top, butt_lr, butt_r, 1);

// Butt corners: edges run past their tangent points to a sharp corner on butt_y; fillet takes it off.
back_bottom  = line_at_y(back_edge_hi, back_edge_lo, butt_y);
strap_bottom = line_at_y(strap_top,    strap_T,      butt_y);

// Top of the grip is squared and level: the top edge is horizontal at grip_top_y (4.5 mm above the
// top screw row; H2 is the datum), and both ends are true 90 deg corners — the left side and the
// front edge are made vertical (top_left.x = outline[2].x = 54.17; tr_front_ref.x = cusp3.x). The
// cutout runs vertical (cutout_tilt = 0), so it is perpendicular to this top, and the butt bottom
// (flat at butt_y) is parallel to it. 0.78 mm off the scan's R1.876 arc at the corner, deliberately.
grip_top_y   = H2[1] + 4.5;        // level top edge; the top screw row sits 4.5 mm below it
cusp3        = [109.36 + finger_shift,  91.72];   // top of groove-2 scallop, raised +2.8 with g2 (was 89.01); +finger_shift in X
top_left     = [ 54.17, grip_top_y];   // x = outline[2].x -> left side vertical -> 90 deg corner
tr_front_ref = [109.36 + finger_shift, 105.23];   // x = cusp3.x -> front edge vertical -> 90 deg corner (not a vertex)
tr_top_ref   = [107.57, grip_top_y];   // on the (horizontal) top edge — not a vertex
tr_corner    = line_isect(cusp3, tr_front_ref, tr_top_ref, top_left);

outline = [
    tr_corner,            // 0  top-right
    top_left,             // 1  top-left
    [  54.17,   98.59],   // 2  top block
    back_edge_hi,         // 3  reflex; back arc lands tangent here
    back_bottom,          // 4  butt, back corner
    strap_bottom,         // 5  butt, front corner
    strap_top,            // 6  reflex
    [ 105.78 + finger_shift,   58.29],   // 7  groove cusp — bottom of g1 (+finger_shift in X)
    [ 108.51 + finger_shift,   76.78],   // 8  groove cusp — ridge between the fingers (+finger_shift in X)
    cusp3                 // 9  groove cusp — top of g2 (cusp3 already carries +finger_shift)
];

I_BUTT_BACK  = 4;
I_BUTT_FRONT = 5;
I_CUSPS      = [7, 8, 9];

panel_max_x = max([for (p = outline) p[0]]);   // widest point (cusp3); the part is always inside its contour

// Waste a round tool of radius R leaves at convex corner P (in from A, out toward B): the wedge
// between the tangent points, less the tool. Outline runs CCW, so material is on the left of travel.
module corner_fillet(A, P, B, R) {
    d1 = (P - A) / norm(P - A);
    d2 = (B - P) / norm(B - P);
    t  = R / tan(acos(-d1 * d2) / 2);
    T1 = P - d1 * t;
    T2 = P + d2 * t;
    C  = T1 + R * [-d1[1], d1[0]];
    difference() {
        polygon([T1, P, T2]);
        translate(C) circle(r = R);
    }
}

module fillet_at(i, R) {
    n = len(outline);
    corner_fillet(outline[(i + n - 1) % n], outline[i], outline[(i + 1) % n], R);
}

module outline_sketch() {
    difference() {
        polygon(outline);
        fillet_at(I_BUTT_BACK,  butt_r);
        fillet_at(I_BUTT_FRONT, butt_r);
        if (corner_r > 0)
            for (i = I_CUSPS) fillet_at(i, corner_r);
    }
}

// ---------------------------------------------------------------------------
// profile — the contour, less everything that runs straight through it
// ---------------------------------------------------------------------------

module back_arc_cut()  { translate(back_arc) circle(r = back_arc_r); }
module finger_grooves(){ for (g = groove_at) translate(g) circle(r = groove_r); }

module profile() {
    difference() {
        outline_sketch();
        back_arc_cut();
        finger_grooves();
    }
}

// ---------------------------------------------------------------------------
// profile as a BOSL2 region (points) — only the offset_sweep blank uses this
// ---------------------------------------------------------------------------
// profile() above stays the source of truth. This rebuilds the SAME contour as a point
// path so BOSL2 can chamfer its edge: round_corners() lays the butt/cusp fillets that
// corner_fillet() lays for profile(), and the back arc and grooves are differenced off as
// circles, exactly as profile() cuts them. Same parameters in, so the two stay in step;
// only the representation differs (2D sketch vs. explicit path).
arc_fn = 96;    // facets per differenced circle (grooves, back arc) in the region

function circ_path(c, r, n = arc_fn) =
    [for (a = [0 : 360 / n : 360 - EPS]) c + r * [cos(a), sin(a)]];

function profile_region() =
    let(rad = [for (i = [0 : len(outline) - 1])
                   (i == I_BUTT_BACK || i == I_BUTT_FRONT) ? butt_r
                 : in_list(i, I_CUSPS)                     ? corner_r
                 :                                           0])
    difference([
        round_corners(outline, radius = rad, closed = true),
        circ_path(back_arc,     back_arc_r),
        circ_path(groove_at[0], groove_r),
        circ_path(groove_at[1], groove_r)
    ]);

// ---------------------------------------------------------------------------
// cutout footprint (the blank and the scoops both key off it)
// ---------------------------------------------------------------------------

cutout_w = cutout_w_asbuilt - cutout_trim_near - cutout_trim_far;   // floor width (the "low side")
cutout_chamfer = (cutout_open_w - cutout_w) / 2;   // flare per long wall so the opening reaches cutout_open_w
cutout_o = [cutout_at[0] + cutout_trim_far, cutout_at[1]];

// Sear-cutout centreline, and how long the scallop reads from the top-edge opening to the bottom wall.
cutout_cl_bottom   = cutout_o + (cutout_w / 2) * [cos(cutout_tilt), -sin(cutout_tilt)];
cutout_axis        = [sin(cutout_tilt), cos(cutout_tilt)];
cutout_top_open    = line_isect(cutout_cl_bottom, cutout_cl_bottom + cutout_axis, top_left, tr_top_ref);
cutout_scallop_len = norm(cutout_top_open - cutout_cl_bottom);

// Cutout footprint at wall offset `out`: 0 = floor, cutout_chamfer = opening. Only the long walls flare.
function cutout_rect(out) =
    let(c = cos(-cutout_tilt), s = sin(-cutout_tilt))
    [for (p = [[-out, 0], [cutout_w + out, 0], [cutout_w + out, cutout_len], [-out, cutout_len]])
        cutout_o + [p[0]*c - p[1]*s, p[0]*s + p[1]*c]];

// Gap from P to the footprint. P is always outside it, so no inside test.
function dist_to_cutout(P, out) =
    let(R = cutout_rect(out))
    min([for (i = [0:3]) dist_pt_seg(P, R[i], R[(i + 1) % 4])]);

// How far out from the floor the ceiling is still too low for a full roll
// (ceiling < min_wall_cutout + edge_r): the chamfer ramp read backwards.
cutout_shadow_out = min(cutout_chamfer,
        max(0, cutout_chamfer * (min_wall_cutout + edge_r - cutout_floor)
                            / (panel_thickness - cutout_floor)));

// ---------------------------------------------------------------------------
// stock
// ---------------------------------------------------------------------------

// One quarter-round bead, z=0..r, as a stack of eroded profiles. offset(delta) — NOT
// minkowski/hull — keeps plan corners sharp and stops the hook filling solid. See DESIGN.md.
module bead(r) {
    for (i = [0 : edge_steps - 1]) {
        a0 = 90 * i / edge_steps;
        a1 = 90 * (i + 1) / edge_steps;
        translate([0, 0, r * (1 - cos(a0))])
            linear_extrude(r * (cos(a0) - cos(a1)) + EPS)
                offset(delta = -r * (1 - sin(a1)))
                    profile();
    }
}

// Strip the palm roll must not run: over the cutout the floor IS min_wall_cutout, so a roll there would
// end the 1 mm lip on the top edge rather than thin it. Bounded by the roll's own band. See DESIGN.md.
module roll_keepout() {
    linear_extrude(edge_r)
        intersection() {
            difference() {
                profile();
                offset(delta = -edge_r) profile();
            }
            polygon(cutout_rect(cutout_shadow_out));
        }
}

// Full profile through the middle, edges treated on each face that asks.
// A palm treatment (edge_r rolled bullnose or edge_cham flat chamfer) routes through BOSL2 (offset_sweep
// treats the palm/scoop-side perimeter); with neither set, the legacy plain extrude. Back face: edge_r_back.
module blank() {
    if (edge_cham > 0 || edge_r > 0) blank_swept();
    else                             blank_legacy();
}

// Quarter-ellipse roll profile for offset_sweep's os_profile, reach `a` into the face and depth `b`
// down the edge. Points run [a*(1-cos t), b*sin t] for t = 0..90: the exact generalisation of
// os_circle's quarter-arc ([r*(1-cos t), r*sin t]) with the horizontal and vertical semi-axes split.
// Tangent is vertical at t=0 (meets the straight wall with no crease) and horizontal at t=90 (meets
// the palm face with no crease), so a≠b gives a smooth asymmetric bullnose — no hard edges anywhere,
// which a flat chamfer cannot give. a=b degenerates to a circular round of radius a. First point is
// [0,0], as os_profile requires.
function ellipse_roll(a, b, n = edge_steps) =
    [for (i = [0 : n]) let(t = 90 * i / n) [a * (1 - cos(t)), b * sin(t)]];

// BOSL2 path: one offset_sweep of the profile region, edge-treated on the palm face (z = 0, the
// scoop side) — a rolled bullnose (edge_r, elliptical when edge_r_reach differs) or, rarely, a flat
// chamfer (edge_cham) — and optionally rolled on the back (top). offset_sweep sits base-up, so its
// bottom IS the palm. check_valid MUST stay on: it prunes the invalid inward-offset points the
// treatment makes at the concave grooves and reflex corners (the 5 mm roll reach offsets further than
// the old 2.5 mm round, so this matters more, not less). Without it the swept solid renders fine
// alone but trips CGAL's exact booleans when the holes / scoops / cutout cut it (assertion violation).
module blank_swept() {
    reg  = profile_region();
    path = len(reg) == 1 ? reg[0] : reg;   // single closed contour here; stay general for holes
    // Palm (bottom) edge. Preferred: the rolled bullnose (edge_r deep, edge_r_reach into the face) — an
    // ellipse via os_profile when the two differ, else a circular os_circle. edge_cham is the flat-chamfer
    // alternate (hard edges); exactly one of edge_r / edge_cham is set (asserted).
    palm = edge_cham > 0
             ? os_chamfer(width = edge_cham_top > 0 ? edge_cham_top : edge_cham, height = edge_cham)
         : (edge_r_reach > 0 && edge_r_reach != edge_r)
             ? os_profile(points = ellipse_roll(edge_r_reach, edge_r))
             : os_circle(r = edge_r);
    offset_sweep(path, height = panel_thickness,
                 bottom = palm,
                 top    = edge_r_back > 0 ? os_circle(r = edge_r_back) : undef,
                 steps = edge_steps, check_valid = true);
}

// Legacy path: linear extrude + hand-rolled bead() round (see DESIGN.md). Used only when no palm
// treatment is set (edge_cham = edge_r = 0); the palm round now goes through BOSL2 (blank_swept).
module blank_legacy() {
    translate([0, 0, edge_r])
        linear_extrude(panel_thickness - edge_r - edge_r_back) profile();
    if (edge_r > 0) {
        bead(edge_r);
        if (cutout_shadow_out > 0) roll_keepout();
    }
    if (edge_r_back > 0)
        translate([0, 0, panel_thickness]) mirror([0, 0, 1]) bead(edge_r_back);
}

// ---------------------------------------------------------------------------
// operations
// ---------------------------------------------------------------------------

assert(edge_r + edge_r_back <= panel_thickness - min_wall,
       str("edge_r ", edge_r, " + edge_r_back ", edge_r_back,
           " leaves under min_wall (", min_wall, ") of straight wall at the edge"));
assert(edge_cham + edge_r_back <= panel_thickness - min_wall,
       str("edge_cham ", edge_cham, " + edge_r_back ", edge_r_back,
           " leaves under min_wall (", min_wall, ") of straight wall at the edge"));
assert(!(edge_cham > 0 && edge_r > 0),
       "set only one palm-face treatment: edge_cham (chamfer) or edge_r (round), not both");
assert(groove_round <= panel_thickness - min_wall_cutout,
       str("groove_round ", groove_round, " leaves under min_wall_cutout (", min_wall_cutout,
           ") at the groove edge"));
assert(cutout_floor >= min_wall_cutout,
       str("cutout_floor ", cutout_floor, " is under min_wall_cutout (", min_wall_cutout, ")"));
assert(min(scoop_front_leave) > 0 && max(scoop_front_leave) < panel_thickness,
       str("scoop_front_leave ", scoop_front_leave, " must be within (0, ", panel_thickness, ")"));
assert(scoop_r > panel_thickness - min(scoop_front_leave),
       str("scoop_r ", scoop_r, " must exceed the deepest front cut ",
           panel_thickness - min(scoop_front_leave)));
assert(min(scoop_angle) > 0,
       str("scoop_angle ", scoop_angle, " must all be > 0 so the rear ramps out (no scallop)"));
assert(thumb_leave >= min_wall,
       str("thumb_leave ", thumb_leave, " is under min_wall ", min_wall,
           " (dish would leave too little stock)"));
assert(thumb_angle > 0,
       str("thumb_angle ", thumb_angle, " must be > 0 so the scoop tapers out (no scallop at the far end)"));
assert(thumb_r > panel_thickness - thumb_leave,
       str("thumb_r ", thumb_r, " must exceed the dish depth ", panel_thickness - thumb_leave));

// Chamfered pocket, floored at cutout_floor.
module sear_solenoid_cutout() {
    depth = panel_thickness - cutout_floor;
    run   = cutout_chamfer;
    translate([cutout_o[0], cutout_o[1], 0]) rotate([0, 0, -cutout_tilt]) {
        hull() {
            translate([0, 0, cutout_floor]) cube([cutout_w, cutout_len, EPS]);
            translate([-run, 0, panel_thickness - EPS]) cube([cutout_w + 2*run, cutout_len, EPS]);
        }
        // overshoot past the outer face so the cut has no coincident faces
        translate([-run, 0, panel_thickness - EPS]) cube([cutout_w + 2*run, cutout_len, depth]);
    }
}

// Two fingers, two cylinders — one cut each, nothing shared, nothing cut twice.
module finger_scoops() {
    finger_scoop(0);   // upper finger  (groove_at[0])
    finger_scoop(1);   // lower finger  (groove_at[1])
}

// ONE cylinder for finger i: a capsule laid ALONG the finger and TILTED nose-down at the front.
// The front sphere sits at the groove valley, sunk so its crest leaves scoop_front_leave[i] of panel
// there; the axis then descends rearward at scoop_angle[i], so the cut ramps up out of the face and
// the rear carries no scallop. The crest meets the palm face (cut ends) about
// (panel_thickness - scoop_front_leave[i])/tan(scoop_angle[i]) behind the valley.
module finger_scoop(i) {
    aim = 180 + scoop_aim[i];              // 0 = straight rearward (-X)
    u   = [cos(aim), sin(aim)];
    P0  = groove_at[i] + groove_r * u;     // groove valley: front anchor, on the front edge
    d   = [cos(scoop_angle[i])*u[0], cos(scoop_angle[i])*u[1], -sin(scoop_angle[i])];  // rearward + down
    Cf  = [P0[0], P0[1], panel_thickness - scoop_front_leave[i] - scoop_r];   // front sphere centre
    Cr  = Cf + scoop_len * d;              // rear sphere centre (sunk below the face; no cut there)
    hull() {
        translate(Cf) sphere(r = scoop_r, $fn = scoop_fn);
        translate(Cr) sphere(r = scoop_r, $fn = scoop_fn);
    }
}

// Thumb relief at the web — the SAME construction as finger_scoop, scaled up. A capsule TILTED
// nose-down: the deep-end sphere sits at thumb_at, sunk so its crest leaves thumb_leave of panel; the
// axis then descends at thumb_angle along thumb_aim, so the far-end sphere sinks below the palm face
// and the cut ramps up out of the material — a tapered scallop, wide and round at the deep end and
// fading to nothing, exactly like a finger scoop.
module thumb_scoop() {
    u   = [cos(thumb_aim), sin(thumb_aim)];        // in-plane run direction, from the deep end
    d   = [cos(thumb_angle)*u[0], cos(thumb_angle)*u[1], -sin(thumb_angle)];   // along u AND down into the material
    Cf  = [thumb_at[0], thumb_at[1], panel_thickness - thumb_leave - thumb_r]; // deep-end sphere (crest leaves thumb_leave)
    Cr  = Cf + thumb_len * d;                       // far-end sphere, sunk below the face (ramps out, no cut there)
    hull() {
        translate(Cf) sphere(r = thumb_r, $fn = thumb_fn);
        translate(Cr) sphere(r = thumb_r, $fn = thumb_fn);
    }
}

// The thumb scoop's palm-face rim, rounded — the "chamfer" on the thumb cut. The fingers revolve a cove
// about their groove cylinder (groove_reliefs); the thumb has no such axis, so its cove is SWEPT. It is
// the SAME quarter-round, but SKINNED (lofted) between the cove's cross-sections rather than stacked as
// flat extruded slices, so the swept surface comes out smooth — no offset-stack terracing.
//
// thumb_footprint_path(z) is the thumb capsule's cross-section OUTLINE at height z, built from the same
// thumb_at / aim / angle as the cutter so the two can't drift: a capsule is convex, so the convex hull of
// disks sampled along its axis (each disk = the capsule's radius where the axis pierces z) IS that outline.
// The cove walks a = 270 deg down to 180 deg; at each step the outline at depth z(a) = rr*(1+sin a) is
// offset outward by s(a) = rr*(1+cos a) — a concave quarter-round tangent to the palm face at its mouth
// (a = 270) and reaching depth rr at the scoop wall (a = 180). skin() lofts those rings into ONE smooth
// solid that, subtracted, rounds the rim. The mouth ring is repeated EPS below the face so the cut has no
// coincident face there. Near the web edge the round runs off the panel into the perimeter roll (blends
// the deep end into the edge). thumb_relief_fn = rings (cove smoothness); thumb_fn = points per ring.
function thumb_footprint_path(z) =
    let(u  = [cos(thumb_aim), sin(thumb_aim)],
        d  = [cos(thumb_angle)*u[0], cos(thumb_angle)*u[1], -sin(thumb_angle)],
        Cf = [thumb_at[0], thumb_at[1], panel_thickness - thumb_leave - thumb_r],
        pts = [for (i = [0 : thumb_relief_fn])
                   let(C = Cf + (i / thumb_relief_fn) * thumb_len * d,
                       rad2 = thumb_r*thumb_r - pow(z - C[2], 2))
                   if (rad2 > EPS)
                       for (a = [0 : 360 / thumb_fn : 360 - EPS])
                           [C[0] + sqrt(rad2)*cos(a), C[1] + sqrt(rad2)*sin(a)]])
    [for (i = hull2d_path(pts)) pts[i]];

module thumb_relief(rr = thumb_round) {
    n   = thumb_relief_fn;
    zs  = [for (i = [0:n]) rr * (1 + sin(270 - 90*i/n))];   // depth along the quarter-round (0 -> rr)
    ss  = [for (i = [0:n]) rr + rr * cos(270 - 90*i/n)];    // outward offset  along it   (rr -> 0)
    r2d = [for (i = [0:n])
               let(fp = thumb_footprint_path(zs[i]))
               resample_path(ss[i] > EPS ? offset(fp, r = ss[i], closed = true) : fp,
                             n = thumb_fn, closed = true)];  // uniform point count -> method="direct"
    profiles = concat([ path3d(r2d[0], -EPS) ],             // mouth, EPS below the face (clean overshoot)
                      [ for (i = [0:n]) path3d(r2d[i], zs[i]) ]);
    skin(profiles, slices = 0, method = "direct", closed = false, caps = true);
}

// Round the front groove edges deep enough to swallow the scoop's front lip, so each scoop DIVES
// smoothly into the palm-face round all along the arc — not just at the valley. A concave fillet
// (cove) of radius groove_round, revolved coaxially with the groove cylinder (the groove IS a
// vertical cylinder): tangent to the palm face at its mouth and to the groove wall at its foot, so
// it blends with no hard edge. It bites only along the scallop and stops where the circle leaves the
// panel. Applied after the scoops.
//
// Was a 45 deg CONE (a straight hypotenuse in this profile). The cone met the palm face at a hard
// crease and showed a flat triangular facet everywhere the scoop did not undercut it — off the
// valley, toward the cusps — which is exactly the "missing chamfer" the fillet fixes.
module groove_reliefs() {
    // Relief profile in the (r, z) half-plane revolved about the groove axis: z = 0 is the palm
    // face, +z runs into the panel. Quarter-circle centred at [groove_r + groove_round, groove_round],
    // swept from the palm face (a = 270 deg, tangent horizontal) round to the groove wall
    // (a = 180 deg, tangent vertical).
    rr = groove_round;
    prof = concat(
        [[groove_r - EPS, -EPS], [groove_r + rr, -EPS]],
        [for (i = [0 : edge_steps]) let(a = 270 - 90 * i / edge_steps)
            [groove_r + rr, rr] + rr * [cos(a), sin(a)]],
        [[groove_r - EPS, rr]]);
    for (g = groove_at)
        translate([g[0], g[1], 0])
            rotate_extrude($fn = scoop_fn)
                polygon(prof);
}

// H1/H2/H3, drilled through.
module holes() {
    for (h = holes)
        translate([h[0], h[1], -EPS])
            cylinder(d = hole_d, h = panel_thickness + 2*EPS);
}

// Conical countersink on the palm face for each hole: a cone wide at the face (mouth sized so
// the head seats cs_sink below flush) narrowing to the bore, run past the bore so it never leaves a
// coincident face for the boolean. Each hole's depth is capped to leave cs_floor of palm-side stock:
// harmless for the through-holes H1/H3 (full seat), but it shortens H2 (only cutout_floor of stock over
// the sear pocket) to a shallower, smaller-mouth cone — its head then sits proud (CSINK echo reports it).
module countersinks() {
    half = cs_angle / 2;
    full = (cs_head_d/2 - hole_d/2) / tan(half) + cs_sink;   // depth to seat the head cs_sink below flush
    over = 0.6;                                              // run past the bore (no coincident face)
    for (i = [0 : len(holes) - 1]) {
        stock = (i == 1) ? cutout_floor : panel_thickness;  // H2 (index 1) sits over the sear cutout
        depth = min(full, stock - cs_floor);                // leave >= cs_floor of stock under the cone
        r_top = hole_d/2 + depth * tan(half);               // mouth radius (< head/2 once capped)
        translate([holes[i][0], holes[i][1], -EPS])
            cylinder(h  = depth + over + EPS,
                     r1 = r_top + EPS * tan(half),
                     r2 = max(EPS, r_top - (depth + over) * tan(half)),
                     $fn = 48);
    }
}

// Shallow logo engrave on the palm face (z = 0). The SVG's filled paths recess logo_depth;
// the lettering (negative space) stays proud. Centred on logo_center, scaled to logo_width.
module logo_2d() {
    translate([-logo_width/2, -logo_h/2])
        resize([logo_width, 0, 0], auto = true)
            // tessellate curves relative to the art's own size, so it stays smooth whatever
            // units the source SVG uses.
            import(logo_file, $fn = 0, $fs = logo_svg[0]/300, $fa = 6);
}
module logo_cut(flip = false) {
    translate([logo_center[0], logo_center[1], -EPS])
        scale([flip ? -1 : 1, 1, 1])   // mirror so the logo reads right on the OUTER palm face (see grip())
            rotate([0, 0, logo_rotate])
                linear_extrude(logo_depth + EPS)
                    logo_2d();
}

// ---------------------------------------------------------------------------
// the part
// ---------------------------------------------------------------------------

module panel(logo_flip = false) {
    difference() {
        blank();
        sear_solenoid_cutout();
        finger_scoops();
        thumb_scoop();
        if (thumb_round > 0) thumb_relief();   // round the thumb rim (its groove_reliefs)
        if (groove_round > 0) groove_reliefs();
        logo_cut(logo_flip);
        holes();
        countersinks();
    }
}

module grip(h = "right") {
    // The palm (scoop) face is the OUTER face — viewed from behind the cut — so the logo is
    // mirrored in X to read right there. The right panel does that mirror itself (logo_flip);
    // the left panel already gets an X-mirror from mirror([1,0,0]), so it must NOT flip again.
    if (h == "left") mirror([1, 0, 0]) panel(logo_flip = false);
    else                               panel(logo_flip = true);
}

// Both hands: left = right mirrored in X, shifted by 2*panel_max_x so plate_gap is the true gap.
module plate() {
    grip("right");
    translate([2*panel_max_x + plate_gap, 0, 0]) grip("left");
}

echo(str("BUTT  bottom y=", butt_y, "  R=", butt_r,
         "  back corner=", back_bottom, "  front corner=", strap_bottom));
echo(str("STRAP tangent=", strap_T, "  to butt corner at ", butt_lr));
echo(str("WALL  min ", min_wall, " everywhere, ", cutout_floor, " under the cutout floor (pocket ", cutout_pocket, " deep)",
         "  palm budget=", panel_thickness - min_wall,
         "  (palm roll edge_r=", edge_r, " deep x ", edge_r_reach, " reach", edge_cham > 0 ? str(" [FLAT chamfer ", edge_cham, "x", edge_cham_top, "]") : "",
         ", scoop front_leave=", scoop_front_leave, ")"));
// Scoop crest height on the centreline, s along-axis behind groove i's valley (for the gap check).
function scoop_top(i, s) =
    let(T = panel_thickness - scoop_front_leave[i], a = scoop_angle[i], r = scoop_r,
        sstar = (s - sin(a) * r) / cos(a))
    sstar < 0 ? (s <= r ? (T - r) + sqrt(r*r - s*s) : 0)
              : (T - r) - s * tan(a) + r / cos(a);
function scoop_valley(i) =
    groove_at[i] + groove_r * [cos(180 + scoop_aim[i]), sin(180 + scoop_aim[i])];
// gap between groove i's scoop crest and the cutout floor, at the cutout's nearest edge
function scoop_cutout_gap(i) = cutout_floor - scoop_top(i, dist_to_cutout(scoop_valley(i), 0));

echo(str("SCOOP r=", scoop_r, "  front_leave=", scoop_front_leave, "  angle=", scoop_angle,
         "  aim=", scoop_aim,
         "  |  g1 scallop ends ~", (panel_thickness - scoop_front_leave[0]) / tan(scoop_angle[0]),
         " mm behind groove",
         "  |  g2 gap to cutout=", scoop_cutout_gap(1), " (target ", scoop_gap, ")",
         scoop_cutout_gap(1) < 0
            ? str("  <<< g2 CUTS THROUGH the cutout by ", -scoop_cutout_gap(1), " mm")
            : (scoop_cutout_gap(1) < scoop_gap - 0.05 ? "  <<< g2 under target" : "")));
thumb_depth_v = panel_thickness - thumb_leave;                             // dish depth at the deep end
thumb_dish_w  = 2*sqrt(thumb_r*thumb_r - pow(thumb_r - thumb_depth_v, 2));  // dish width across, at the palm face
echo(str("THUMB  deep end=", thumb_at, "  aim=", thumb_aim, "  angle=", thumb_angle,
         "  dish ~", thumb_dish_w, " wide x ", thumb_depth_v, " deep, tapers out ~", thumb_depth_v/tan(thumb_angle),
         " mm along aim",
         "  (vs finger ~", 2*sqrt(scoop_r*scoop_r - pow(scoop_r - (panel_thickness-scoop_front_leave[0]), 2)),
         " wide x ", panel_thickness - scoop_front_leave[0], " deep)",
         "  |  wall left=", thumb_leave, " (min_wall=", min_wall, ")  rim round=", thumb_round));
// Thumb-to-index transition: the thumb fades out at thumb_fade_x; groove 2's (index) scoop reaches back to
// g2_back_x. Overlap > 0 means they merge into one valley (no bowtie pinch); <= 0 means they pinch/gap.
thumb_fade_x = thumb_at[0] + (thumb_depth_v / tan(thumb_angle)) * cos(thumb_aim);
g2_back_x    = scoop_valley(1)[0]
             + ((panel_thickness - scoop_front_leave[1]) / tan(scoop_angle[1])) * cos(180 + scoop_aim[1]);
echo(str("THUMB->INDEX  thumb fades at x=", thumb_fade_x, "  index scoop reaches back to x=", g2_back_x,
         "  overlap=", thumb_fade_x - g2_back_x, " mm",
         thumb_fade_x - g2_back_x <= 0 ? "  <<< NO overlap: thumb & index pinch (raise the overlap: lower thumb_angle)" : ""));
palm_cut = max(edge_r, edge_cham);   // vertical depth of whichever palm-face treatment is active (sets the straight wall)
echo(str("EDGE  palm ",
         edge_cham > 0 ? str("FLAT chamfer ", edge_cham_top > 0 ? edge_cham_top : edge_cham, " into face x ",
                             edge_cham, " deep mm (hard edges) (BOSL2 offset_sweep)")
       : edge_r > 0 && edge_r_reach > 0 && edge_r_reach != edge_r
                       ? str("elliptical roll ", edge_r_reach, " reach x ", edge_r, " deep mm (curved, no hard edge) (BOSL2 offset_sweep)")
       : edge_r    > 0 ? str("round ", edge_r, " mm (BOSL2 offset_sweep)")
       :                 "sharp",
         "  back ", edge_r_back > 0 ? str("round ", edge_r_back, " mm") : "flat",
         "  |  straight wall at the perimeter=", panel_thickness - palm_cut));
rim_groove = groove_round > 0 ? panel_thickness - groove_round
           :                    panel_thickness - palm_cut;
echo(str("RIM   straight wall: ", panel_thickness - palm_cut, " at the perimeter, ",
         rim_groove, " at the groove  (min_wall=", min_wall, ")",
         rim_groove < min_wall
             ? str("  <<< THE GROOVE EDGE IS UNDER min_wall, SPENT ON groove_round=",
                   groove_round)
             : ""));
echo(str("RAIL  cutout opening to groove 2 valley=",
         dist_to_cutout(groove_at[1], cutout_chamfer) - groove_r - edge_r_back));
echo(str("CUTOUT scallop=", cutout_scallop_len, " mm from the top opening",
         "  opening width=", cutout_w + 2*cutout_chamfer, " (floor ", cutout_w, ", chamfer ", cutout_chamfer, ")",
         "  (cutout_len=", cutout_len, ", pokes ", cutout_len - cutout_scallop_len, " past the edge)"));
logo_scoop_low = groove_at[0][1]
    - sqrt(max(0, scoop_r*scoop_r - pow(panel_thickness - scoop_front_leave[0] - scoop_r, 2)));
echo(str("LOGO  center=", logo_center,
         "  ", logo_width, " x ", logo_h, " mm  depth=", logo_depth, "  (", logo_file, ")",
         "  |  clearances mm: H3=", (logo_center[1] - logo_h/2) - (H3[1] + hole_d/2),
         "  scoop=", logo_scoop_low - (logo_center[1] + logo_h/2),
         "  back-edge=", (logo_center[0] - logo_width/2)
                         - line_at_y(back_edge_hi, back_edge_lo, logo_center[1] + logo_h/2)[0],
         "  front-edge=", line_at_y(strap_top, strap_T, logo_center[1] - logo_h/2)[0]
                          - (logo_center[0] + logo_width/2)));
cs_full    = (cs_head_d/2 - hole_d/2)/tan(cs_angle/2) + cs_sink;      // full-seat depth (H1/H3)
cs_h2_depth = min(cs_full, cutout_floor - cs_floor);                  // capped depth over the cutout (H2)
cs_h2_mouth = 2*(hole_d/2 + cs_h2_depth*tan(cs_angle/2));             // H2 mouth diameter once capped
echo(str("CSINK  head ", cs_head_d, " mm x ", cs_angle, " deg  sink ", cs_sink, " below flush",
         "  |  H1/H3 full: mouth d=", 2*(cs_head_d/2 + cs_sink*tan(cs_angle/2)), " depth=", cs_full,
         "  |  H2 capped: mouth d=", cs_h2_mouth, " depth=", cs_h2_depth,
         " (", cutout_floor, " stock, leave ", cs_floor, ")",
         cs_h2_mouth < cs_head_d - 0.01
            ? str("  <<< H2 head sits proud (mouth < ", cs_head_d, " head)") : ""));
echo(str("PLATE right + left, gap=", plate_gap, "  mirror plane x=",
         panel_max_x + plate_gap/2, "  left panel offset=", 2*panel_max_x + plate_gap));

plate();
