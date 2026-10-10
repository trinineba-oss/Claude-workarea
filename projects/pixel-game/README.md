# Pixel Game

A starter 2D pixel-art game for Android, built with [Godot](https://godotengine.org) 4.7
(GL Compatibility renderer). You control a character with the arrow keys, or by
touching the screen, and collect coins.

## Pixel-art settings (already configured)

| Setting | Value | Why |
| --- | --- | --- |
| Viewport | 320×180 | Low base resolution; scales up to any screen |
| Stretch mode / scale | `viewport` / `integer` | Crisp pixels, no blurry fractional scaling |
| Default texture filter | Nearest | No smoothing on sprites |
| Snap 2D transforms and vertices | On | No sub-pixel shimmer |
| Renderer | `gl_compatibility` (desktop and mobile) | Lightest renderer; runs on low-end phones |
| Orientation | Landscape | |

## Layout

- `scenes/` – `game.tscn` (main scene), `player.tscn`, `touch_controls.tscn`
- `scripts/` – GDScript: `game.gd` (rooms, transitions, autosave, pause), `world_map.gd`
  and `room.gd` (map loading and tiles), `tiles.gd` (tile legend and shared TileSet),
  `player.gd`, `save_game.gd`, and the touch widgets (`touch_*.gd`)
- `data/rooms/<x>_<y>.txt` – the world: one 20x11 ASCII map per screen (see below)
- `assets/` – placeholder art (`tools/gen_art.py` regenerates it). Commit the `.import`
  files next to each asset; `.godot/` is ignored.
- `tests/*_test.gd` – headless tests (world data, save file, touch controls, the game)
- `export_presets.cfg` – Android and Web export presets
- `DESIGN.md` – the game design and milestone plan

## Controls

| Action | Keyboard | Touch |
| --- | --- | --- |
| Move | Arrow keys or WASD | Joystick (bottom left) |
| Attack | Z | A |
| Item | X | B |
| Interact | C | X |
| Pause (also saves) | Esc | II (top right) |

Touch controls show on touch devices and in the browser; on desktop the mouse acts as a
finger. Attack, item and interact are wired to input actions but do nothing yet (milestone 2).

## Building the world

Each file in `data/rooms/` is one screen, named by its grid position (`1_1.txt` is column 1,
row 1). Walking off an open edge scrolls to the neighbouring room, and the game saves.

| Char | Tile | Solid |
| --- | --- | --- |
| `.` | grass | no |
| `,` | flowers | no |
| `s` | sand | no |
| `p` | path | no |
| `=` | stone floor | no |
| `@` | player start (sand); exactly one in the world | no |
| `~` | water | yes |
| `#` | rock wall | yes |
| `b` | bush | yes |
| `T` | tree | yes |

Rules (checked by `make test`): every file has 11 rows of 20 characters; openings on shared
edges must line up exactly with the neighbour; an edge with no neighbour must be solid.

## Saving

`user://save.json` holds the room and position. It is written on every room change, on pause,
and when the app goes to the background or closes. A missing, corrupt or different-version
file starts a new game.

## Commands (from the repo root)

```sh
make test   # headless tests (alongside the other repo tests)
make lint   # gdformat + gdlint
godot --path projects/pixel-game              # open the game (needs a display)
godot --path projects/pixel-game --editor     # open the editor (needs a display)
godot --headless --path projects/pixel-game --export-release Web build/web/index.html
```

The session-start hook installs Godot 4.7.2 and its export templates from the Nix
binary cache (Godot's own download hosts are blocked in cloud sessions) and
`gdtoolkit` for formatting and linting.

## Building the Android APK

The Android preset is configured (arm64, package `com.example.pixelgame`) and the
export templates are installed, but the **Android SDK is not**: its download host
(`dl.google.com`) is not reachable from cloud sessions, so an APK has not been built
here. The Web export does work in a cloud session. To build the APK:

1. On a machine with network access (or after allowing `dl.google.com` in the
   environment's network policy), install JDK 17 and the Android SDK
   (`platform-tools`, `build-tools`, `platforms;android-35`, `cmdline-tools`).
2. Create a debug keystore: `keytool -genkeypair -v -keystore debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"`
3. In the Godot editor, set the SDK path, JDK path and debug keystore under
   Editor → Editor Settings → Export → Android.
4. Export: `godot --headless --path projects/pixel-game --export-debug Android build/pixel-game.apk`

Change `package/unique_name` in `export_presets.cfg` before publishing, and keep
release keystores out of git (`*.keystore` and `*.jks` are ignored).

## Next steps

Replace `assets/sprites/player.png` with your own art, add tilemaps and levels, and add
touch controls (a virtual joystick) if you want movement without tapping a target point.
