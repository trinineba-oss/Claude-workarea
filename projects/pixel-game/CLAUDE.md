# Pixel Game (Godot 4.7, GDScript)

- Keep the pixel-art project settings in `project.godot` (nearest filtering, integer
  viewport scaling, pixel snapping). Import new sprites with the default (no mipmaps,
  no filter) settings.
- Style: `make lint` runs `gdformat --check` and `gdlint`; fix with `gdformat scripts tests`.
- Tests: `tests/*_test.gd` are headless `SceneTree` scripts extending `tests/test_base.gd`; add a
  new `<name>_test.gd` per system and run `make test`. The world data is validated there.
- World maps live in `data/rooms/` (legend in README.md); the export presets include `data/*`.
- After adding assets, run `godot --headless --path projects/pixel-game --import` so the
  `.import` files are generated, and commit them. Never commit `.godot/` or `build/`.
- The Android SDK can't be installed in cloud sessions; use the Web export to check builds here.
- Design lives in `DESIGN.md` (Zelda/Link's Awakening-style parody about the Legendary
  Lamb Gyro). Follow its tone pillars and milestones; update it when decisions change.
- Never use Nintendo names, sprites or music (see the Legal section of `DESIGN.md`).
