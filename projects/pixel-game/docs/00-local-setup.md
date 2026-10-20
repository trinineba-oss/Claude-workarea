# 0. Local setup: running the project on your PC

The game is a [Godot](https://godotengine.org) project (GDScript). Nothing else is needed to play
and edit it; Python is only for the tests' lint step and the art tools.

## 1. Get the code

Install [Git](https://git-scm.com/downloads), then in a terminal:

```sh
git clone https://github.com/trinineba-oss/Claude-workarea.git
cd Claude-workarea
git checkout ccr-8da01cc0-6n08a3   # the branch with the latest work, until it is merged
```

The game is in `projects/pixel-game/`.

## 2. Install Godot 4.7.2

Download **Godot 4.7.2 (standard, not .NET)** from <https://godotengine.org/download/archive/>
for your system. It is a single program; no installer. Use exactly 4.7.x: the project is saved
in that version's format.

- **Windows:** unzip, and keep `Godot_v4.7.2-stable_win64.exe` somewhere like `C:\Godot\`.
- **Mac:** unzip and move `Godot.app` to Applications.
- **Linux:** unzip and make the file executable.

## 3. Open and play

1. Start Godot. In the Project Manager choose **Import**, pick
   `projects/pixel-game/project.godot`, and open it. The first import takes a minute.
2. Press **F5** (or the ▶ button, top right) to play.
   - Keys: arrows or WASD to move, **Z** attack, **X** use item, **C** talk/interact,
     **V** Evey's orders, **Esc** pause. Change them in
     *Project → Project Settings → Input Map*.
3. The touch buttons show on screen too; click them with the mouse.

Handy while testing: the Web build reads start options from its address
(`index.html?room=2_0&at=8_6&time=19.5` starts on Lady Hailes Avenue at dusk), and in the editor
you can untick `Use 3d` on the Game node to see the plain 2D drawing.

## 4. Run the tests (optional but useful)

The tests make sure a change hasn't broken anything (saving, combat, temples, Evey...).

**Any system, with Python 3.10+ installed:**

```sh
python projects/pixel-game/tools/run_tests.py
```

It finds Godot on your PATH, or set `GODOT` to the program's path first:

- Windows (PowerShell): `$env:GODOT = "C:\Godot\Godot_v4.7.2-stable_win64.exe"`
- Mac: `export GODOT=/Applications/Godot.app/Contents/MacOS/Godot`

**Mac/Linux with `make`:** from the repo root, `make test` and `make lint` (the same checks the
cloud sessions run). Lint needs `pip install gdtoolkit` (or `uv tool install gdtoolkit`).

## 5. Using Claude on your PC

Install Claude Code (<https://claude.com/claude-code>), open a terminal in the repo folder and
run `claude`. It reads `CLAUDE.md` and `projects/pixel-game/CLAUDE.md` for the project rules,
and these docs for what you want. Cloud sessions (claude.ai/code) keep working on the same repo
too; just pull before you start and push when you're done, on either side.

## Saving your work

```sh
git pull                      # get the latest first
git add -A
git commit -m "What you changed"
git push
```

Keep private things out of the repo (it is public): personal photos, the Evey photo, Street View
footage, keystores, API keys. Put reference images in a folder outside the repo, or in
`scratch/` (git-ignored).

## Building for Android

Needs the Android SDK and JDK 17 on your PC (which cloud sessions can't download). Steps are in
the main README under *Building the Android APK*. Your PC is the right place to do it.
