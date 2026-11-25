# Chad and the Legendary Lamb Gyro (Godot 4.7, GDScript)

The hero is Chad.

The folder is still called `pixel-game`. **On the `pixel-2d` branch the game is pure pixel-art 2D**
(the 2.5D view, painted sheets and illustrated look were removed there; they live on the main
work branch). The plan for open-world systems is `docs/18-open-world-systems.md`.

- 1280x704 base resolution, `canvas_items` stretch. One tile is
  64 px and rooms are 20x11 tiles; distances and speeds in code are in these pixels.
- Node origins are at the character's feet (or the base of a tree/wall): depth sorting uses
  them, so sprites are offset upward. Keep that convention for new art and scenes.
- Pixel art on a 2x grid (a 64 px tile is 32 art pixels), nearest filtering, pixel snap.
  Characters with a sheet in `data/looks.json` get an animated `PixelSprite` (added by
  `PixelCast`) under their plain 2D sprite. Pixel sheets come from `tools/lpc_build.py` (LPC
  parts, CC-BY-SA: keep `assets/characters/CREDITS.md` up to date by re-running it) and
  `tools/pixel_animals.py`. After regenerating placeholder art, run `tools/pixelate.py` to put
  it on the pixel grid.
- Systems are rules on data, not special cases: the chemistry grid (`RoomChemistry`,
  `data/materials.json`) lives per room. Evey is peaceful (no fighting); her remarks are in
  `data/evey_quips.json` (drafts). She speaks plain English, never Trinidad dialect.
- Placeholder art comes from `tools/gen_art.py` (Pillow + numpy, run with
  `uv run --with pillow --with numpy python -I tools/gen_art.py`). Real art replaces the PNGs
  at the same size and anchor.
- Style: `make lint` runs `gdformat --check` and `gdlint`; fix with `gdformat scripts tests`.
- Tests: `tests/*_test.gd` are headless `SceneTree` scripts extending `tests/test_base.gd`; add a
  new `<name>_test.gd` per system and run `make test`. The world data is validated there.
- World maps live in `data/rooms/`, temples in `data/dungeons/<map>/` (legend and temple
  rules in README.md); the export presets include `data/*`.
- Conversations, characters and props are data (`data/dialogue.json`, `characters.json`,
  `props.json`). Every dialogue line is a draft until someone from Trinidad reviews it; keep
  the `_note` saying so.
- After adding assets, run `godot --headless --path projects/pixel-game --import` so the
  `.import` files are generated, and commit them. Never commit `.godot/` or `build/`.
- APK: `tools/build_apk.sh` builds `build/chad-gyro-demo.apk` (debug-signed). It needs the
  Android SDK, which is not preinstalled in cloud sessions: install it with `sdkmanager` into
  `~/Android/Sdk` (dl.google.com must be allowed) and make a debug keystore first. Use the Web
  export for quick visual checks. Never commit keystores or `build/`.
- Effects from free packs live in `assets/vfx/` and `shaders/vfx/` (CC BY 4.0): keep
  `assets/vfx/CREDITS.md` and the licence files with them, and credit any new pack there.
- The game is an action RPG: keep controls tight (buffered input, cancellable swings, readable
  enemy tells). The wharf demo (`scripts/wharf_demo.gd`) is the slice everything builds from.
- Planning lives in `docs/` (one file per area). What the owner writes under "Your input" is
  their direction: read the relevant file before working on that area, and tick its "To do"
  items and update "Decided" when work lands.
- Design lives in `DESIGN.md` (Zelda/Link's Awakening-style parody about the Legendary
  Lamb Gyro, set in San Fernando, Trinidad). Follow its tone pillars and milestones; update it when decisions change.
- Keep local references respectful and accurate; dialogue text belongs in data files for
  review by someone from Trinidad. Use invented shop and character names, not real brands.
- Never use Nintendo names, sprites or music (see the Legal section of `DESIGN.md`).
