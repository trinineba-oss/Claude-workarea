# Gyro's Awakening game (Godot 4.7, GDScript)

The folder is still called `pixel-game`, but the game is HD 2D now (it started as pixel art).

- HD 2D: 1280x704 base resolution, `canvas_items` stretch, linear filtering. One tile is
  64 px and rooms are 20x11 tiles; distances and speeds in code are in these pixels.
- Node origins are at the character's feet (or the base of a tree/wall): depth sorting uses
  them, so sprites are offset upward. Keep that convention for new art and scenes.
- Placeholder art comes from `tools/gen_art.py` (Pillow + numpy, run with
  `uv run --with pillow --with numpy python -I tools/gen_art.py`). Real art replaces the PNGs
  at the same size and anchor.
- Style: `make lint` runs `gdformat --check` and `gdlint`; fix with `gdformat scripts tests`.
- Tests: `tests/*_test.gd` are headless `SceneTree` scripts extending `tests/test_base.gd`; add a
  new `<name>_test.gd` per system and run `make test`. The world data is validated there.
- World maps live in `data/rooms/` (legend in README.md); the export presets include `data/*`.
- After adding assets, run `godot --headless --path projects/pixel-game --import` so the
  `.import` files are generated, and commit them. Never commit `.godot/` or `build/`.
- The Android SDK can't be installed in cloud sessions; use the Web export to check builds here.
- Design lives in `DESIGN.md` (Zelda/Link's Awakening-style parody about the Legendary
  Lamb Gyro, set in San Fernando, Trinidad). Follow its tone pillars and milestones; update it when decisions change.
- Keep local references respectful and accurate; dialogue text belongs in data files for
  review by someone from Trinidad. Use invented shop and character names, not real brands.
- Never use Nintendo names, sprites or music (see the Legal section of `DESIGN.md`).
