# 10. Tech

Godot 4.7, GDScript, GL Compatibility renderer (runs on low-end phones and the web).

## How it fits together

- **The game runs in 2D.** Rooms, collisions, characters and every system are 2D nodes. Distances
  are in pixels; a tile is 64 px; rooms are 20×11 tiles.
- **It is drawn in 2.5D** by `scripts/view/`: `View3D` hides the 2D world and mirrors it into 3D
  every frame. One tile = one 3D unit. The view only reads the game; game logic stays in 2D.
- **Content is data**, so it can be edited without code:

| What | File |
| --- | --- |
| Overworld rooms | `data/rooms/<x>_<y>.txt` |
| Temples | `data/dungeons/<map>/<x>_<y>.txt` |
| Dialogue | `data/dialogue.json` |
| People | `data/characters.json` |
| Top dogs | `data/dogs.json` |
| Props | `data/props.json` |
| Items | `data/items.json` |
| Plants | `data/forage.json` |
| Which picture draws whom | `data/looks.json` + `assets/characters/sheets.json` |

## Folders

```
projects/pixel-game/
  scenes/      main scene and a few prefabs
  scripts/     game code; scripts/view/ is the 3D drawing
  shaders/     ground, tilt-shift, vignette
  data/        rooms, temples, dialogue, characters, items...
  assets/      sprites, textures, item icons, character sheets
  tools/       art generators and the test runner (Python)
  tests/       headless tests, one per system
  docs/        these planning docs
```

## Tests

Each system has a `tests/<name>_test.gd`. A test fails on a failed check, a timeout or any
script error. Run them with `make test` or `python tools/run_tests.py` (see
[Local setup](00-local-setup.md)). Add or update a test with every change.

## Builds

- **Web:** `godot --headless --path projects/pixel-game --export-release Web build/web/index.html`
- **Android:** needs the Android SDK on your PC; see the main README.
- **Desktop:** add a Windows/Mac/Linux export preset in the editor (*Project → Export*) and
  download the export templates (*Editor → Manage Export Templates*).

## Low-end phones

The illustrated look itself is cheap: painted characters and props are single flat pictures
(one quad each), and painted ground is one texture lookup per material. What costs the most on
a weak phone is the lighting and screen effects around it:

| Feature | Cost | Low-end setting |
| --- | --- | --- |
| Real-time sun shadows | High (the scene is drawn twice) | Off; use soft blob shadows under characters |
| Tilt-shift blur | Medium (a full-screen pass) | Off |
| Glow | Medium | Off |
| Ink outlines on 3D props | Each outlined mesh drawn twice | Keep (few meshes), or off |
| Painted textures | Memory | Import as compressed (ETC2/ASTC); 128 px frames are fine |
| Resolution | Scales everything | Render at 75% and scale up |

The GL Compatibility renderer is already the right choice for low-end Android. Plan: a
**graphics quality setting** (Low / High) that switches the rows above, picked automatically on
first launch. None of this has been measured on a real phone yet: test on the cheapest phone
available before the look is final.

## Your input

1. Do you want a desktop build too, or just Android?
2. Store plans: Google Play? itch.io? (Change `package/unique_name` in `export_presets.cfg`
   before publishing.)

## To do

- [ ] Desktop export preset
- [ ] Test on a real Android phone
- [ ] Performance check on a low-end phone (3D view, shadows)
- [ ] Graphics quality setting (Low: no shadows, glow or tilt-shift; 75% resolution)
- [ ] Settings save (volume, controls)
