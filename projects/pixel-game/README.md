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

- `scenes/` – `main.tscn` (game loop), `player.tscn`, `coin.tscn`
- `scripts/` – GDScript for each scene
- `assets/sprites/` – art. Commit the `.import` files next to each asset; `.godot/` is ignored.
- `tests/smoke_test.gd` – headless test that boots the game and collects a coin
- `export_presets.cfg` – Android and Web export presets

## Commands (from the repo root)

```sh
make test   # headless smoke test (runs alongside the other repo tests)
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
