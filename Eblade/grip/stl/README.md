# Eblade grip — STL

The committed `grip.stl` is **unbranded**. It is rendered with the committed
`../openscad/logo.placeholder.svg`, an empty SVG, so the mesh holds no logo geometry.
The Eblade grip can engrave the **Snapshot PB "S" mark** into the panel. That mark is a
trademark, and it is not distributed here (see the NOTICE at the top of
[`LICENSE`](../../../LICENSE)). The logo source (`../openscad/logo.svg`) and a branded
mesh (`grip-branded.stl`) are gitignored. Do not commit a branded mesh as `grip.stl`.

## Generating the mesh

From the grip directory (`Eblade/grip/`):

```sh
# Unbranded (the default — logo_file points at logo.placeholder.svg). This is the
# committed mesh: both hands, as a plate.
openscad -o stl/grip.stl openscad/grip.scad

# Branded, for a print (needs the local trademark art openscad/logo.svg). It writes
# a separate, gitignored file, so the committed grip.stl stays unbranded.
openscad -D 'logo_file="logo.svg"' -o stl/grip-branded.stl openscad/grip.scad
```

Requirements:

- **BOSL2** in your OpenSCAD library path — used for the palm-face edge roll
  (an asymmetric bullnose) via `offset_sweep`. See [`../openscad/DESIGN.md`](../openscad/DESIGN.md).
- **The logo is optional and defaults to unbranded.** `logo_file` points at the committed
  `openscad/logo.placeholder.svg` (a valid but empty SVG), so a clone **without** the trademark
  art renders cleanly and unbranded — no console errors. To brand a build, override `logo_file`
  to the real (gitignored) art with `-D 'logo_file="logo.svg"'`, as shown above. Either way the
  STL is a valid manifold.
