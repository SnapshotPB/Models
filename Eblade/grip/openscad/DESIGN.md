# Eblade grip panel — design notes

Rationale, print history, and rejected alternatives for `grip.scad`. The source
keeps only the constraints an editor needs at the point of editing; the *why*
lives here. Units: mm.

## Approach

The part is modelled the way it is made: one blank, then a single `difference()`
holding the operations that shape it — the sear solenoid cutout, the finger scoops, and
the holes. `panel()` is the whole part; read it first.

`plate()` renders both hands every time — the right panel and its X-mirror.
`grip("right")` / `grip("left")` render one alone.

Coordinates keep the source mesh's frame, so the right panel drops straight onto
the scan overlay for comparison. Re-zero with one `translate()` if that stops
being useful.

This approximates the original mesh rather than copying it. The source mesh was
itself irregular — its "circular" holes wander 0.15 mm — and print validation
showed several of its features are wrong, so nothing here is held to the mesh
tighter than ~1 mm.

## The outline is a sketch, not a stack of cuts

The outline stays a 2D contour handed to a profile op, not something built from
half-plane cuts. It cannot be built that way: the profile is a hook, not a
convex blank. It has two reflex vertices (`back_edge_hi`, where the top block
meets the back edge, and `strap_top`), and five of its edges cut real material
if run as unbounded half-planes — the back edge alone would take 2093 mm² of the
lower body. Every such cut would need a hand-tuned bound. So: sketch the
contour, then cut it. (10-point contour, max 0.78 mm from the source profile at
the squared top-right corner — see below.)

The back arc and the finger grooves live in that sketch (`profile()`) rather
than as cylinders differenced off the blank. They always went straight through,
so they were always contour, never feature. Once the palm face is rolled over
they *have* to be, because the roll follows the whole perimeter and the grooves
are as much perimeter as the back edge is. A full-height prism cut off a prism
is just a 2D difference.

Traced curves are real circular arcs, cut as such:
- **Back curve** (web of the hand): an 84° concave arc, `back_arc_r = 17.87`,
  tangent to the back edge at `back_edge_hi`, biting up into the top block's
  lower edge. The old contour faked it with three chords — that is where the
  visible facets came from.
- **Finger grooves**: both grooves in the source mesh fit R = 14.58 / 14.52, so
  they share one radius (`groove_r = 14.55`). Centres sit outside the panel. The
  ridge between the fingers and groove 2's top read 2.8 mm low against the hand, so
  groove 1 was reshaped (bottom cusp held on the strap edge, top cusp raised 2.8 mm —
  its centre moved back and up, so the scallop is ~1.2 mm deeper) and groove 2 was
  translated 2.8 mm straight up; the scoops follow (they key off the centres). Only
  the bottom cusp is unchanged. Spacing opened from 16.7 to 17.9 mm as a result.
  The whole finger region is then shifted `finger_shift = 1.5` mm toward the front edge to **widen
  the grip**: both groove circles, their three front-edge cusps (`outline` 7/8/9 = `cusp3`), and the
  squared top-front reference (`tr_front_ref`) all carry `+finger_shift` in X, so they move as one and
  the cusps stay exactly on their groove circles (the front edge grows 1.5 mm through the fingers with
  no notch — the `strap_top→cusp7` segment still meets the g1 circle only at the cusp). The scoops
  follow the centres, so the g2 scoop slid away from the sear cutout and its clearance grew with the
  shift (0.4 → 0.51 mm); the thumb→index overlap eased from 7.6 to 6.1 mm (still merged). Widening the
  front edge changes the panel footprint, so re-check the frame/marker fit on the next print.
- **Butt**: a true stadium — one flat bottom (`butt_y`, traced −2.400, bow
  0.14 mm over 28 mm) and the same radius in both corners (`butt_r`). Both
  corner circles bottom out on `butt_y`, and that shared tangent *is* the flat
  bottom edge. So the back edge and the strap line simply run down to `butt_y`
  and the two corners are filleted — no hull, no contour points parked inside
  the butt. `butt_lr_x` sets the front corner centre; the strap line is tangent
  to it, which is what makes the butt a stadium instead of two unrelated radii
  (mirroring how the back edge meets the rear corner). The original reached the
  strap via a short 10.3 mm transition line; that line is gone.

`back_edge_lo` was traced as the tangent to the back butt corner; it now only
sets the back edge's *direction*, and the corner fillet re-derives the tangency
(landing within 0.014 mm of it).

### The top is squared and level — a deliberate scan departure

The source mesh had the top of the grip slightly askew: the top edge tilted
~0.32° off level, the two ends were ~89.96° / ~90.45° rather than square, and the
top screw row sat ~5.0–5.2 mm below the edge instead of the intended 4.5 mm. The
top is now built true instead of traced:

- The top edge is **horizontal** at `grip_top_y = H2[1] + 4.5` — i.e. 4.5 mm above
  the top screw row, with H2 as the datum, so both top holes sit exactly 4.5 mm
  below it and level with each other (`H1.y = H2[1]`).
- Both ends are **true 90° corners**: the left side is made vertical
  (`top_left.x = outline[2].x = 54.17`) and the front edge is made vertical
  (`tr_front_ref.x = cusp3.x = 109.36`); `tr_corner` is then their intersection at
  `[109.36, grip_top_y]`.
- The sear cutout runs **vertical** (`cutout_tilt = 0`), so it is perpendicular to
  this top, and the butt bottom (a flat at `butt_y`) is parallel to it.

The source mesh has a true R1.876 arc at the top-right; squaring it sits 0.78 mm
outside that arc, making this the least scan-faithful feature on the part —
deliberate. Don't "fix" it back to the arc or re-tilt it to the mesh.

## Corner radii are cut, locally

Each radius is `corner_fillet()` — the waste a round tool leaves at a corner,
less the tool itself. Exact and strictly local, so no corner can reach another.
This replaced a global `offset()` rounding pass that had to be clipped to a
hand-drawn box to keep it away from the sharp corners it would otherwise have
eaten. The top block's corners are genuine and must stay sharp; the butt is
filleted. The groove cusps are currently left sharp as well (`corner_r = 0`) —
`corner_fillet()` still rounds them if `corner_r` is set above 0.

## The wall budget

Two floors govern every cut:
- `min_wall = 2.0` — web left under any cut, anywhere. It caps `edge_r` / `edge_cham`
  (the palm-edge treatment's depth) — both asserted.
- `min_wall_cutout = 1.0` — a floor the roll-keepout math still reads. It used to be
  the cutout's own floor as well (they were equal), but the floor is now
  `panel_thickness - cutout_pocket = 1.75` — see the cutout section.

Read `min_wall` and the palm relief as one budget. The palm face may be relieved by
`panel_thickness - min_wall = 3.5`, whether that relief is the edge roll or the scoop along a
groove. The roll's *depth* (`edge_r`) and the scoop cut the same face, so the deeper one wins
and neither can spend it twice; the roll's *reach into the face* (`edge_r_reach`) is a separate,
wider horizontal budget bounded only by feature collisions, not by `min_wall`. The tightest spot
against the depth floor is the web where groove 2's dish passes over the sear pocket: deepening
the pocket to 3.25 would have driven the full 2 mm dish 0.065 mm *through* the 1.75 mm floor, so
g2 is shallowed alone (`scoop_front_leave[1] = 3.27`) to hold a ~0.2 mm web there. The SCOOP echo
reports the gap rather than asserting it (see the scoop section).

`min_wall_cutout` used to bound the scoops too. It no longer does — the two
grooves want different reaches and only one of them is over the cutout at all, so
each scoop's reach is set per groove by hand rather than clamped to a shared floor.

## Palm-face edge — a rolled asymmetric bullnose (NOT a chamfer), via BOSL2 (offset_sweep)

**This face is gripped tightly, so it must have no hard edges.** A flat chamfer was tried and
rejected: it gave the reach we wanted but left a hard crease where the bevel met the palm face and
another where it met the wall. The palm-face perimeter is therefore **rolled**, not chamfered — a
smooth curve tangent to both surfaces.

`edge_r = 3.5`, `edge_r_reach = 5.0`: a roll runs the whole palm-face (finger-scoop side) perimeter —
the outline, the back arc, and both groove scallops. It is an **asymmetric bullnose**, a quarter-
*ellipse* rather than a quarter-circle, with the two axes as separate knobs:
- `edge_r` is the **depth down the edge** (vertical semi-axis). At 3.5 it spends the full palm budget
  (`panel_thickness - min_wall = 3.5`), leaving exactly `min_wall` (2 mm) of straight wall under it —
  the thin visible band the eye reads as the panel's thickness. This is the axis `min_wall` caps
  (asserted); to push deeper, lower `min_wall`.
- `edge_r_reach` is the **reach into the palm face** (horizontal semi-axis). At 5.0 (twice the old
  2.5 mm circular round) the roll is a long, gentle dome: it drops the visible thickness to the 2 mm
  band and curves the rest away, so the 5 mm panel reads far thinner and fills the hand smoothly. Not
  bound by `min_wall` (it removes nothing from the load-bearing back wall) — only by running into
  other palm-face features, so it is left un-asserted; watch the render if you push it much past the
  finger grooves. `edge_r_reach = 0` (or `= edge_r`) degenerates to a plain circular round.

The curve is tangent-vertical at its foot (meets the straight wall with no crease) and tangent-
horizontal at its mouth (meets the palm face with no crease), so there is no hard edge anywhere on
the gripped face — the whole point. `edge_cham` / `edge_cham_top` remain as a **flat-chamfer**
alternate (hard edges — for flat, un-gripped parts only); set exactly one of `edge_r` / `edge_cham`
(asserted). The EDGE echo reports the active treatment and the straight wall left. This is the one
place the model leans on the BOSL2 library (`include <BOSL2/std.scad>`, installed in the local
OpenSCAD library dir — **not** vendored in the repo, so a fresh clone must install it to render).

**Why BOSL2 here.** `offset_sweep()` extrudes a 2D region to a height and lays a rounding (circle,
ellipse-via-profile, chamfer, …) around the top and/or bottom edge, honouring concavities — exactly
the palm-edge treatment, and the same offset-based idea as `bead()` but as a library call. `blank()`
dispatches: a palm treatment set (`edge_r` or `edge_cham` > 0) → `blank_swept()` (BOSL2); neither →
the legacy `blank_legacy()` (plain linear extrude, sharp palm). offset_sweep sits base-up, so its
*bottom* is the palm (z = 0); the treatment goes there — `blank_swept()` picks `os_profile(points =
ellipse_roll(edge_r_reach, edge_r))` for the asymmetric roll (or `os_circle(edge_r)` when the two are
equal, or `os_chamfer(...)` for the flat alternate). `ellipse_roll()` builds the quarter-ellipse as
`[edge_r_reach·(1−cos t), edge_r·sin t]` for t = 0..90 — the exact generalisation of the quarter-arc
`os_circle` lays (`[r·(1−cos t), r·sin t]`), with the horizontal and vertical semi-axes split.

**The region.** `offset_sweep()` needs the profile as a point path, but `profile()` is a 2D
sketch (a polygon cut by circles) and OpenSCAD can't hand a sketch's boundary back as
points. So `profile_region()` rebuilds the *same* contour as a path: `round_corners()` lays
the butt/cusp fillets that `corner_fillet()` lays for `profile()`, and the back arc and
grooves are `difference()`d off as circles, exactly as `profile()` cuts them. It is a second
rendering of one set of parameters, not a second design — they can't drift because they
share every value. (This is the one spot that softens the "outline is a single sketch" rule,
and only for the swept blank.)

**`check_valid` must stay on.** The bottom roll (or chamfer) offsets the profile *inward* at z = 0;
at the concave grooves and the two reflex corners that inward offset throws off invalid points (the
5 mm roll reach offsets further still than the old 2.5 mm round, so this matters more, not less — it
was verified to render clean at 5 mm reach, but a wider `edge_r_reach` leans on this pruning harder).
`offset_sweep(..., check_valid = true)` prunes them. With it off, the swept solid renders
fine on its own but trips CGAL's exact booleans the moment the holes / scoops / cutout cut it
(`CGAL ERROR: assertion violation`). It is on deliberately; don't turn it off to save time.

**The back face is untouched** (`edge_r_back = 0` → flat top), same reason as always: it
mates flat, and a roll there re-makes the unprintable groove-2 rail.

**The finger scoops dive into the front groove edge through a rounded relief.** The perimeter roll
is on the blank; the scoops are cut afterward and reach the front groove ~2 mm deep. `groove_reliefs()`
lays a clean blend there: a concave **fillet** (cove) of radius `groove_round = 2.5`, revolved coaxially
with each groove cylinder and cut *after* the scoops, sized (≥ the scoop front depth
`panel_thickness - scoop_front_leave = 2.0`) to swallow the scoop's lip. Tangent to the palm face at its
mouth and to the groove wall at its foot, so it meets both with no hard edge. It bites only along the
scallop — the revolve finds material only where the groove circle *is* the panel edge, and stops at the
cusps where the circle leaves the panel. The RIM echo reports the straight wall left at the groove
(`2.5` leaves exactly `min_wall`).

*Was a 45° cone (`groove_cham`).* The cone met the palm face at a hard 45° crease and, crucially, showed
a **flat triangular facet wherever the scoop did not undercut it** — i.e. everywhere *off* the valley,
along the flanks and into the cusps. Dead-centre (where the scoop runs straight into the groove) it read
smooth, but the finger's transition into the groove hit that facet and its creases on both sides. The
fillet has no flat face and no top edge, so the whole arc — flanks included — dives smoothly into the
scoop bottom. (The remaining short ridge *between* the two grooves at the shared cusp is the deliberate
finger-divider, not a facet; soften it further with `corner_r` if wanted.)

## Palm-face roll-over (legacy round)

> Fully dormant. The palm round is now done through BOSL2 (`edge_r` → `os_circle` in
> `blank_swept()`, section above), NOT this hand-rolled `bead()`. `blank_legacy()` now runs only
> when no palm treatment is set (`edge_cham = edge_r = 0`), so `bead()` / `roll_keepout()` below are
> unreached in the shipping config — kept for reference. The figures below are the old `edge_r = 1.0`,
> 3 mm `bead()` build; they no longer describe the shipping edge.

`edge_r = 1.0`: a 1.0 mm roll on a 3.0 mm panel leaves `min_wall` of straight
wall at the edge. The edge is broken everywhere the hand can find it and the
section never drops below 2 mm doing it — everywhere except along the finger
grooves, where the scoop has already spent the budget and the roll is simply
gone (the edge there is broken by the groove relief `groove_round` instead, and
the rim pays for it — the RIM echo).

`edge_r_back = 0`: the frame face is NOT rolled, deliberately twice over. It
mates flat against the marker, so no edge on it is ever touched; and a 1.0 mm
roll there would take the rail between the cutout's opening and groove 2's valley
from 1.11 mm to 0.11 mm — re-creating exactly the unprintable rail that
`cutout_trim_near` was added to fix. The RAIL echo reports what a roll there would
cost.

### bead() — why a stack of eroded profiles

`bead()` is the roll, as a stack of profiles each eroded by `offset(delta=)`.

- **Not `minkowski(prism, sphere)`** — the usual reach. The sphere rounds the
  *vertical* edges too, and the top block's corners must stay sharp in plan.
  `offset(delta=)` miters instead, so every plan corner comes through untouched
  and only the face edge is broken.
- **Not `hull()` between consecutive slices** — the other usual reach. The
  profile is a hook, and the hull of any two of its slices fills the back arc
  and both grooves solid.

Each step is extruded at the inset of its *top*, putting the staircase just
outside the true torus — the roll can leave a whisker of material, never take
extra. `edge_steps = 16` holds the worst normal deviation to ~0.05 mm, against a
part held to ~1 mm.

### roll_keepout() — where the roll must not run

Under the cutout the budget is zero: `cutout_floor` *is* `min_wall_cutout`, so there
is nothing to roll away. That bites in exactly one place — the strip where the
cutout's floor exits the panel's top edge. The lip there is 1 mm of stock and
nothing else, and a 1 mm roll does not thin it, it ends it (15 mm of top edge
tapering to zero thickness). So the roll lifts over it and that lip stays square,
which is what the tool would have to do anyway.

The keepout is bounded by the roll's own band, not by hand: it is (the band the
roll eats) ∩ (the footprint out to where the ceiling can afford a roll,
`cutout_shadow_out`). That intersection is empty everywhere but the top edge,
because the cutout comes within `edge_r` of no other perimeter — nearest is
groove 2, and the footprint stops 2.11 mm off its wall against the band's
1.0 mm.

## Finger scoops

Each scoop is ONE cylinder laid on its side ALONG the finger and cut into the palm
face as a smooth channel, then TILTED nose-down at the front. It is a capsule (the
`hull()` of two spheres), so the cut has smooth side walls and smooth ends — no
flat faces anywhere. The front sphere sits at the groove valley, sunk so its crest
leaves `scoop_front_leave[i]` of panel there; the axis then descends rearward at
`scoop_angle[i]`, so the cut ramps up out of the face and the rear carries no
scallop. The crest meets the palm face (cut ends) about
`(panel_thickness - scoop_front_leave[i]) / tan(scoop_angle[i])` behind the valley.

Knobs (all reported live in the SCOOP echo):
- `scoop_r` — cylinder radius = the cross-finger cradle (shared). Bigger = wider.
- `scoop_angle = [g1, g2]` — the tilt per finger, the main ramp knob. Lower = a
  longer, gentler scallop; higher = a shorter one that fades out closer to the
  front. The two are deliberately different.
- `scoop_front_leave = [g1, g2]` — panel left at each valley (the thin spot).
- `scoop_len` — capsule length along the tilted axis; just needs to be long enough
  to cover the ramp (the rear sphere ends up sunk below the face, cutting nothing).
- `scoop_aim[i]` — in-plane splay per finger; 0 = straight rearward (−X).

### Groove 2 and the sear cutout — g2 shallowed to hold the web over the deeper pocket

Groove 2 runs straight over the sear-solenoid pocket. The pocket is a fixed shape
referenced to the *back* face (`cutout_pocket = 3.75`), so at `panel_thickness = 5.5` its
floor sits `cutout_floor = 1.75` mm above the palm face. Unlike g1 (a full 2 mm dish over
solid stock), **g2 is shallowed** — `scoop_front_leave[1] = 3.97` gives a ~1.53 mm dish — so
its near-wall crest reaches only ~1.35 mm down and clears the 1.75 mm floor by ~0.4 mm.
`scoop_cutout_gap(1)` computes it (cutout floor minus the scoop crest at the pocket's nearest
edge) and the SCOOP echo prints it against `scoop_gap = 0.4`.

The history: at 3 mm the pocket floor sat 1 mm under the palm and groove 2 breached by
~0.8 mm; the fix then was a shallow (~0.8 mm) g2 dimple. At 4.0→4.5 the added stock landed
beneath the fixed pocket and the full 2 mm dish *cleared* — by ~0.19 mm at 4.5. Deepening the
pocket the requested 0.75 mm (0.25 off the floor, 0.5 from the +0.5 panel) spent that ~0.19 mm
of web and 0.065 mm more, so the full 2 mm dish would have grazed 0.065 mm *through*; g2 was
then shallowed 3.0→3.27, and later raised to 3.97 to open the gap to ~0.4 mm (more wall over the
solenoid). The lever is ~1:1 — raising `scoop_front_leave[1]` by δ lifts the g2 gap ~δ, and it lifts
the WHOLE dish uniformly, so the scallop tail barely moves and the thumb→index merge survives.
`scoop_angle[1]` *also* opens the gap now (the pocket's nearest edge sits on the tilted cylinder body,
~3 mm behind the valley, not on the front sphere), but it pivots about the valley and swings the tail
up: reaching 0.4 mm needs ~12°, which shortens the scallop ~25→8 mm and breaks the thumb merge. So
`scoop_front_leave[1]`, not the angle, is the lever for this gap.

Cost of the fix: g2's dish is now ~0.47 mm shallower than g1's (1.53 vs 2.0 mm) — barely
perceptible, and the documented trade when the pocket moves toward the palm. Other levers if the
pocket deepens again: narrow g2 (`scoop_r` per groove) or add panel thickness. The gap is
reported (SCOOP echo) rather than asserted — the flag only fires if it goes back under target.

### What this replaced

The earlier scoop was a single giant-radius cylinder (R ≈ 162 mm) laid CROSSWISE
and grazing the face — smooth rearward fade but flat end-caps for side walls, and
the two scoops met at an abrupt step. That became a straight (untilted) along-the-
finger capsule, then this tilted per-groove version. Gone with those: `scoop_run` /
`scoop_R()` (the crosswise fade radius) and `scoop_depth` (the flat graze depth),
replaced by `scoop_front_leave` + `scoop_angle`.

## Thumb scoop — a web relief built like a finger scoop, plus a swept rim round

`thumb_scoop()` is a wide, deep relief for the thumb at the web of the hand (top-back), built EXACTLY
like a finger scoop (`finger_scoop`): a capsule (`hull` of two spheres) laid on its side and tilted
nose-down, deepest at `thumb_at` (the web edge) and ramping up out of the palm face toward the front, so
the far end carries no scallop. It is just a bigger cradle (`thumb_r = 16` vs the fingers' `scoop_r = 12`)
and, at 3 mm, deeper than the 2 mm finger dishes. It sits over solid panel (not the sear pocket), so the
depth is capped only by the wall budget: `thumb_leave >= min_wall` (asserted). The THUMB echo reports
width / depth / taper.

- `thumb_at = [64, 85]` is the deep end, set right at the back (web) edge (~x63.5 here) so the full-depth
  end lands on the edge and bites the corner. Its 3 mm depth matches the perimeter roll's 3 mm depth
  there, so the two rounded surfaces meet at a similar depth and the deep end blends into the edge.
- `thumb_aim = 0` runs the channel straight forward (+x, parallel to the level top edge), along the top
  of the grip from the web toward the front — i.e. straight at the index finger's scoop.

### The rim round (the "chamfer") — swept, because the thumb has no groove axis

A sphere cut into the flat palm face can never be tangent to it, so the thumb dish's rim is a hard lip —
~36° at the deep end. The FINGER scoops hide their front lip with `groove_reliefs()`, a cove revolved
about the groove cylinder; the thumb sits in the open face with no such axis, so its lip is rounded a
different way. `thumb_relief()` SWEEPS the same quarter-round, but SKINNED (lofted) between the cove's cross-sections
rather than stacked as flat extruded slices, so the swept surface comes out smooth — no offset-stack
terracing. Controlled by `thumb_round` (radius), `thumb_relief_fn` (rings along the quarter-round) and
`thumb_fn` (points per ring); cut after the scoop just as `groove_reliefs` is.

`thumb_footprint_path(z)` is the thumb capsule's cross-section OUTLINE at height z, built from the same
`thumb_at` / `thumb_aim` / `thumb_angle` as the cutter so the two can't drift. A capsule is convex, so the
convex hull (`hull2d_path`) of disks sampled along its axis (each disk = the capsule's radius where the
axis pierces height z) IS that outline. Walking a = 270° down to 180°, the outline at depth z(a) =
rr·(1+sin a) is offset outward by s(a) = rr·(1+cos a): a concave quarter-round tangent to the palm face at
its mouth (a = 270°) and reaching depth rr at the scoop wall (a = 180°). `skin()` lofts those rings — each
`resample_path`'d to a common point count so `method="direct"` corresponds them — into ONE smooth solid;
the mouth ring is repeated EPS below the face so the cut leaves no coincident face there. Near the web edge
the round runs off the panel into the perimeter roll, which is what blends the deep end into the edge.

The lofted surface is smooth in the CAD model itself, not merely below print resolution — unlike `bead()`
and the perimeter roll (genuine offset stacks that do show fine ~0.05 mm contour steps in the render).
`thumb_relief_fn` sets how many rings sample the quarter-round; the footprint/skin is cheap, so raise it
freely. (An earlier version stacked flat `linear_extrude` slices and terraced; `skin()` replaced it.)

### The thumb-to-index transition

The thumb channel and groove 2's (index) scoop are nearly collinear (both along ±x at y ≈ 84), so with the
thumb's old `thumb_angle = 8` the two tapered to points and met tip-to-tip, leaving a thin full-height land
— a sharp bowtie pinch — between them. Lowering `thumb_angle` to 6 lengthens the thumb's taper ~7 mm so
its fade-out OVERLAPS the index scoop's instead: the web relief now flows into the index cradle as one
continuous valley. Only the thumb is lengthened; every finger scoop is left exactly as tuned. The
THUMB→INDEX echo reports the overlap (thumb fade x vs the index scoop's back-reach x); > 0 means merged,
≤ 0 means they pinch. A gentle saddle remains at the watershed between the two dishes — unavoidable with
two separate scoops at slightly different depths, and anatomically natural.

## Sear solenoid cutout

`sear_solenoid_cutout()` is a chamfered pocket floored at `cutout_floor`. Only the long
walls flare, so the footprint at wall offset `out` (`cutout_rect()`) moves only in
x — 0 is the floor, `cutout_chamfer` is the opening.

- `cutout_tilt = 0` — the pocket runs vertical, so it is perpendicular to the level
  top edge and its long walls are parallel to the (vertical) top-block sides. It was
  1.23° off +Y as traced; squaring the top squared this too.
- `cutout_w_asbuilt` (width) is measured off the source mesh. `cutout_at` (the
  bottom-wall corner) is NOT the raw mesh value: the mesh had the pocket running too
  far down, so the bottom was raised until the scallop reads 24.6 mm from where it
  opens at the top edge. `cutout_len = 28.26` is bottom-wall to poke-out top; ~3.7 mm
  of that is the poke past the edge that keeps the opening clean. The CUTOUT echo
  reports the measured scallop length (`cutout_scallop_len`, top-edge crossing to
  bottom wall) so it can be retuned by eye.
- `cutout_trim_near = 1.0` (+X) / `cutout_trim_far = 3.0` (−X) pull the *floor*
  walls inward. The +X trim matters: it sets how close the near wall runs to
  groove 2 (the RAIL echo).
- `cutout_floor = panel_thickness - cutout_pocket` — DERIVED, not a knob. The pocket
  is a fixed physical shape sized for the solenoid (`cutout_pocket = 3.75` mm deep from
  the back face), so the floor is referenced to the back face: thickening the panel
  leaves more stock beneath the pocket, deepening the pocket eats into that stock. At
  `panel_thickness = 5.5` the floor stock is `1.75` mm. The most recent 0.5 mm of pocket
  depth (3.25→3.75) came entirely from the +0.5 panel, so the floor held at 1.75; the prior
  0.75 mm step split 0.25 mm off the floor (2.0→1.75) and 0.5 mm from panel, and that floor
  drop is what forced groove 2's dish to be shallowed to keep its web (see the scoop section).
  H2's bore ends at this floor, so it is 1.75 mm deep — 0.25 mm less thread engagement than at
  the 2.0 floor.
- `cutout_open_w = 18.25` is the opening width (top of the cut, the widest spot);
  `cutout_chamfer = (cutout_open_w - cutout_w)/2` is then derived so each long wall
  flares symmetrically from the floor (`cutout_w = 13.14`) out to that opening. The
  CUTOUT echo reports the opening width. **Caveat:** the flare is symmetric, so
  widening the opening moved the near wall toward groove 2 and the RAIL dropped from
  1.22 to 0.60 mm — thin; then raising groove 2 by 2.8 mm (finger-groove section)
  dropped it further to **0.515 mm**, because g2's valley now sits alongside the
  opening rather than just below it. If that rail needs protecting, flare only the far
  (−X) wall instead of both (an asymmetric `cutout_rect`), or pull `cutout_trim_near`
  in further. (Groove 2's dish is shallowed to clear the deeper pocket floor by ~0.2 mm — SCOOP echo.)

## Holes

`hole_d = 4.5`, all three drilled through; the cutout shortens H2's bore to
`cutout_floor` (the cutout has already cleared everything above it). H1/H2 are now
exactly collinear in X (`H1.y = H2[1]`), so moves along the H1–H2 line are pure X.
−X is "backward" (the finger grooves at x 105–109 are the front).

- **H2** `[97.79, 102.44]` — CONFIRMED correct on the marker. Datum; do not
  move. Both other holes are dimensioned off it — including the level top edge,
  which is `grip_top_y = H2[1] + 4.5`.
- **H1** `[62.65, H2[1]]` — x as before (spacing H1–H2 = 35.14 mm), but y is now
  pinned level with H2, so both top holes sit exactly 4.5 mm below the level top
  edge. Was y 102.50 (0.06 mm above H2); that split is what showed the top edge
  was tilted.
- **H3** `[65.51, 4.36]` — as-found `[64.31, 3.86]`. Latest move: +2 mm in +X (toward
  the finger-cut front edge) and −1 mm in Y (down, away from the logo) from the prior
  `[63.51, 5.36]`. The down move buys +1 mm of logo clearance (LOGO echo now 8.26 mm).
  Unverified — awaiting the next print.

## Countersink

`countersinks()` sinks an angled (conical) countersink into the **palm face** (z = 0, the outer /
grip face) at each hole, so a flat-head screw seats *below* flush and never proud of the
surface the hand rides on. It is the last cut in `panel()`, after `holes()`.

- **Geometry.** A cone, wide at the palm face and narrowing to the bore. Depth is capped to leave
  `cs_floor` of palm-side stock: `depth = min(full, stock − cs_floor)`, where the full seat is
  `(cs_head_d − hole_d)/2 / tan(cs_angle/2) + cs_sink` (2.54 mm at the #8 defaults) and the mouth radius
  is `hole_d/2 + depth·tan(cs_angle/2)`. It runs a further 0.6 mm past the bore so the two cuts never
  share a coincident face for the boolean. The CSINK echo reports the H1/H3 (full) and H2 (capped)
  mouths and depths.
- **Defaults** are a #8 flat head (82° included, ~8.4 mm head) — the 4.5 mm hole is its clearance hole.
  `cs_head_d` / `cs_angle` are knobs; set them to the real screw (82° for #-series imperial, 90° metric).
  `cs_sink = 0.3` mm is the below-flush amount.
- **H2 is capped** (`cs_floor`). H2 sits over the sear cutout, so it has only `cutout_floor` (1.75 mm) of
  palm-side stock; the full #8 seat is 2.54 mm and would breach the pocket. Capping to leave `cs_floor`
  (0.5 mm) shortens H2 to a ~1.25 mm-deep, ~Ø6.7 cone — narrower than the Ø8.4 head, so **its head sits
  proud** (flagged by the CSINK echo). The deeper pocket (floor 2.0→1.75) took another 0.25 mm off this
  cone, so H2 seats a little less than before. H1/H3 have the full `panel_thickness` and seat fully. To close
  the gap on H2: lower `cs_floor` (thins the web over the solenoid) or fit a smaller head there.

## Logo engrave

`logo_cut()` recesses the Snapshot "S" mark into the palm (finger-scoop) face,
`logo_depth = 0.2` mm deep, in the flat area between the lower finger scoop and the bottom
screw (H3). It is the last cut in `panel()`'s `difference()`.

- **Artwork** is the `favicon-no-border.svg` S mark, imported directly (`import()`), no
  tracing — its filled path is the recess. The real art is `logo.svg`, but `logo_file`
  **defaults to `logo.placeholder.svg`** (see *Trademark / distribution* below). Swap
  `logo_file` for any 2-tone SVG; set `logo_svg` to the new art's viewBox size so `logo_2d()`
  stays centred, and `logo_width` to taste (height follows the art's aspect — the S is ~1.9×
  taller than wide, so a 13 mm width is ~24.7 mm tall).
- **Trademark / distribution.** The S mark is a trademark and is not distributed: `logo.svg`
  is gitignored. The repo ships `logo.placeholder.svg` instead — a valid but empty SVG (no
  drawable path) — and `logo_file` defaults to it, so a clone imports a real file: the engrave
  cuts nothing, the console stays clean (no `Can't open file` error), and the panel renders
  unbranded. There is no `show_logo` toggle; the presence of the art is the only switch. A
  branded build overrides to the real art:
  `openscad -D 'logo_file="logo.svg"' -o stl/grip.stl openscad/grip.scad`. Both files carry the
  same `logo_svg` viewBox, so centering is identical either way.
- **Placement** `logo_center = [73, 33]`, sized so ~12–13 mm of clear panel is left to both
  H3 (below) and the lower scoop (above); the LOGO echo prints both gaps so a move can be
  checked by eye. `logo_rotate` spins it in plane.
- **Depth** `logo_depth = 0.2` mm — shallow and adjustable by design; it cuts from the palm
  face (z = 0) down, nowhere near the 2 mm floor.
- **The logo is mirrored to read right on the outer face.** The palm (scoop) face is the
  visible outer face, and you view it from *behind* the cut plane — so a logo placed to read
  normally in the XY sketch comes out backwards there. `logo_cut(flip)` mirrors it in X to fix
  that: the right panel applies the mirror itself (`logo_flip = true`), and the left panel
  already gets an X-mirror from `grip("left")`'s `mirror([1,0,0])`, so it must *not* flip again
  (`logo_flip = false`) — otherwise it double-mirrors back to backwards. Net: exactly one
  X-mirror per hand, and the S reads right on both.
- **Curve tessellation** is set on the import relative to the art's own units
  (`$fs = logo_svg[0]/300`), so it stays smooth whether the source SVG is in mm (this one,
  viewBox ~19) or px.

## Thickness history

`panel_thickness = 5.5`. History: 3.0 first validation print, 4.75 overshot, 4.0, back
to 3.0, 4.0 again to clear the sear pocket, 4.5 when the pocket deepened 2.0→2.5, 5.0 for
a further 0.5 mm of pocket depth (0.25 of that off the floor, `cutout_floor` 2.0→1.75), now
5.5 for 0.5 mm MORE pocket depth — this time entirely from the added thickness: pocket
3.25→3.75 with `cutout_floor` held at 1.75, so no floor was thinned. At 3.0 the finger dish
over groove 2 breached the pocket: the dish wants a full 2 mm from the palm, but only 1 mm of
stock sat under the (then 2 mm-deep) pocket. The pocket is fixed to the back face
(`cutout_pocket`), so each added panel millimetre lands as stock beneath it — at 4.5 the dish
cleared by ~0.19 mm. Deepening the pocket to 3.25 (`cutout_floor` 2.0→1.75) spent that web and
0.065 mm more, so g2 alone was shallowed (`scoop_front_leave[1]` 3.0→3.27, a ~1.73 mm dish) to
lift its crest back off the floor and restore a ~0.2 mm web (SCOOP echo — see the scoop section).

The g2 gap is set by `scoop_front_leave[1] − cutout_pocket` and is **independent of
`panel_thickness`** — both the pocket floor and the g2 crest are back-face-referenced, so a panel
change shifts them together. That is why the 5.0→5.5 step, applied as +0.5 to BOTH `panel_thickness`
and `cutout_pocket`, preserved the g2 gap exactly (0.205 mm at the time; later opened to ~0.4 mm by
raising `scoop_front_leave[1]` — see the scoop section). Every palm-side depth is likewise held by
growing its leave +0.5 in step (`scoop_front_leave` [3.0, 3.27]→[3.5, 3.77], `thumb_leave` 2.0→2.5)
and the palm roll deepened with the panel (2.5 round → 3.0- → 3.5-deep × 5.0-reach ellipse), so all
dish depths and the 2 mm `min_wall` edge band are unchanged — only the back face moved out. `min_wall`
still floors the rest of the part at 2 mm. Girth cost: +2.5 mm per panel versus the 3 mm build (~5 mm
across both hands); the part is thicker but reads no thicker at the edge (the visible band holds at
`min_wall`).

## Plate / clearance

`plate_gap = 6` is the true edge-to-edge clearance between the two panels, not a
bounding-box figure. The left panel is the right one mirrored in X, landing on
x = `[-panel_max_x, -panel_min_x]`; shifting it by `2*panel_max_x` brings the
two just touching, so `plate_gap` is exactly the gap. Mirroring makes the plate
symmetric about x = `panel_max_x + plate_gap/2`, so both panels present the same
feature (cusp3, at y = 89.01) to that plane and nothing else comes nearer —
which is why the closest approach is the true one. `panel_max_x` is taken from
the contour rather than hard-coded, because the finished part is always inside
its contour (every op only removes material), so it can never come out short;
the cusp fillet trims ~0.001 mm off it, which is why the gap lands a hair over
`plate_gap`.
