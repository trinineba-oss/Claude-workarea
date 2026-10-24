# 14. Beach style test (the illustrated look)

A one-room trial of the illustrated look from the owner's mockup (hand-painted, outlined, cosy).
Only **the beach** (overworld room `1_1`, east of the wharf, with the Callaloo Cave mouth) uses
it; the rest of the game is unchanged. If the beach looks right, it becomes the style guide for
everything else ([Art style](03-art-style.md)).

## What's in place

- **Painted ground** with dark **ink lines** where sand, water and the path meet, and a soft
  painted shadow inside each border.
- **Toon shading and ink outlines** on the 3D shapes: rocks, bushes, palms, the sign, the cave
  mouth.
- **Painted-prop slots:** drop a painted picture in (see below) and it replaces the 3D shape.
- **Chad's run and Evey's trot** from the cycle sheet, for walking left and right (everywhere,
  not just the beach).

The ground textures are **stand-ins** made by `tools/illustrated_placeholders.py`, to be
replaced by real painted ones.

## See it

- **In the editor:** play (F5), walk east from the wharf to the beach.
- **Web build:** `index.html?room=1_1&at=10_6&time=15`; add `&illustrated=0` to compare with
  the old look; `&time=18.3` for dusk.
- **Turn it off:** `"enabled": false` in `data/illustrated.json`. Add rooms to its `"rooms"`
  list (`"overworld:2_0"`, ...) to try the look elsewhere.

## Art to make for the test

All transparent PNG unless noted. Keep the same light (from the upper left), the same dark
outline and the same painting style for every piece.

### Ground: `assets/illustrated/ground/`

Seamless tiles (the right edge continues into the left, the top into the bottom), **512×512**,
one square = 4×4 tiles in the game. No outlines inside; the game inks the borders.

| File | What |
| --- | --- |
| `sand.png` | Beach sand (the most important one) |
| `water.png` | Sea, seen from above |
| `dirt.png` | The beaten path |
| `grass.png` | Grass (for other rooms later) |

### Props: `assets/illustrated/props/`

Painted at **128 px per tile**, standing upright as seen by the camera, with the **base at the
bottom edge, centred**. Up to 9 variants each: `rock_1.png`, `rock_2.png`, ... (or just
`rock.png`). The game picks one per spot.

| File | Size guide | Notes |
| --- | --- | --- |
| `rock_*.png` | ~130–160 px wide | The cliff and boulders around the beach (one per tile) |
| `bush_*.png` | ~120 px wide | |
| `palm.png` | ~300–380 px tall | Coconut palm, with coconuts |
| `flowers_*.png` | ~60–90 px | Small clumps |
| `sign.png` | ~90×110 px | Wooden sign |
| `cave_mouth.png` | ~380×300 px | The Callaloo Cave entrance (3 tiles wide) |

### Characters

Already in: Chad's run and Evey's trot (side-on). Still needed in the same style:

- **Walking toward and away from the camera** for both (4 frames each). Right now those
  directions use the two-step poses.
- A **full 8-frame run** for Chad: the current sheet has a half cycle (frames 1–4) plus jump
  frames, so the same leg always leads.
- Pick **collar or no collar** for Evey (the trot sheet has one, the pose sheet doesn't).

Put new sheets in `art_src/painted/` and ask Claude to add them to `tools/painted_sheets.py`.

## Not in this test yet

- **Raised ground** (terraces, banks, the stream bed in the mockup): the world is flat today.
  It's the biggest engine change on the list; worth doing only if the look is chosen.
- **HUD restyle** (hearts, stamina bar, minimap).
- A **picked palm** picture (a painted palm stays full after its coconuts are picked).

## Your input

1. How does the beach feel compared with the mockup? What's most off?
2. Paint (or generate) `sand.png` and two `rock` variants first: those cover most of the screen.
3. Outline thickness and ink colour: thicker, thinner, browner? (`outline_width` and `ink` in
   `data/illustrated.json`.)

## To do

- [ ] Real painted ground textures (sand, water, dirt)
- [ ] Painted props (rocks, bushes, palm, flowers, sign, cave mouth)
- [ ] Toward/away cycles for Chad and Evey; a full run cycle for Chad
- [ ] Decide: adopt the look, adjust, or drop it
