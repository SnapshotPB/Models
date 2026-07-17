# Paintball Parts — 3D Models

A growing library of **parametric, 3D-printable models for paintball marker parts**.
Every part is authored as [OpenSCAD](https://openscad.org/) source (fully parametric,
units in mm) and, in most cases, committed alongside a ready-to-slice `.stl` export.
(A part that engraves trademarked artwork ships as source only — see its
`stl/README.md`.)

## Printing notes

These parts are tuned for FDM printing. Threaded parts expose a
`thread_clearance` parameter — a **radial shrink of the thread crest** for a
printable fit:

- `thread_clearance = 0` → exact nominal geometry (e.g. 3/4"-16 major = 19.05 mm).
- `~0.15 mm` is a sane starting point for an FDM male thread going into metal.

Dial it in for your printer and filament.

## Contributing a new part

Follow the existing convention so the tree stays predictable:

1. Create (or reuse) a top-level directory for the marker/platform.
2. Add a `<part>/openscad/` directory with the parametric `.scad` source.
3. Export the mesh into a sibling `<part>/stl/` directory.
4. Keep parts parametric and, where practical, self-contained.

## License

Released under the **Creative Commons Attribution 4.0 International (CC BY 4.0)**
license — commercial use permitted **with attribution**. See [`LICENSE`](LICENSE)
for the full text.

