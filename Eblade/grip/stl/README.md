# Eblade grip — STL

The `.stl` for this part is **not committed**. Unlike the other models in this
repository, the Eblade grip engraves the **Snapshot PB "S" mark** into the panel —
a trademark that is not distributed here (see the NOTICE at the top of
[`LICENSE`](../../../LICENSE)). Both the logo source (`../openscad/logo.svg`) and
the exported mesh (which embeds the engraved geometry) are gitignored.

## Generating the mesh

From the grip directory (`Eblade/grip/`):

```sh
# Unbranded (the default — logo_file points at logo.placeholder.svg):
openscad -o stl/grip.stl openscad/grip.scad                       # both hands, as a plate

# Branded (needs the local trademark art openscad/logo.svg present):
openscad -D 'logo_file="logo.svg"' -o stl/grip.stl openscad/grip.scad
```

Requirements:

- **BOSL2** in your OpenSCAD library path — used for the palm-face edge roll
  (an asymmetric bullnose) via `offset_sweep`. See [`../openscad/DESIGN.md`](../openscad/DESIGN.md).
- **The logo is optional and defaults to unbranded.** `logo_file` points at the committed
  `openscad/logo.placeholder.svg` (a valid but empty SVG), so a clone **without** the trademark
  art renders cleanly and unbranded — no console errors. To brand a build, override `logo_file`
  to the real (gitignored) art with `-D 'logo_file="logo.svg"'`, as shown above. Either way the
  STL is a valid manifold.
