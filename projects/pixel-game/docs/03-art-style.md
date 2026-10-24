# 3. Art style

## Decided

- **2.5D.** The game plays in 2D but is drawn in 3D: a tilted camera (50° down) follows Chad over
  real lighting, shadows, fog and glow. Characters are upright pictures (billboards) standing in
  the 3D world; buildings, vehicles and props are solid 3D models.
- **Day and night.** A 12-minute day. Dusk and night bring out the food-truck lights, street
  lamps, the gas station and headlights. Temples are dim and torchlit.
- **Palette.** Hot and saturated Caribbean: flamboyant red and poui yellow blooms, mango green,
  concrete pastels, sea blue.
- **Tilt-shift.** A soft blur at the top and bottom of the screen makes the town feel like a
  model.
- **Chad and Evey: painted sheets (in the game now, subject to change).** Clean, outlined
  cartoon characters: Chad (olive jacket, backpack, cargo pants) from the owner's
  `art_src/painted/sheet_v2.jpg`, Evey (a tricolour beagle, no collar) from `sheet_v3.jpg`
  (earlier drafts are kept next to them). `tools/painted_sheets.py` cuts it into game sheets
  (`assets/characters/chad_painted.png`, `evey_painted.png`). To go back to the pixel versions,
  set `"player": "chad"` and `"companion": "evey"` in `data/looks.json`.

## The big open choice: one style for the whole cast

Right now the townspeople, dogs and enemies are **pixel art** (LPC and hand-made), and the new
Chad and Evey are **painted**. They look like they come from different games. Pick one:

| Option | Looks like | Work |
| --- | --- | --- |
| **A. Painted cast** | Your Chad/Evey sheets: smooth, outlined, detailed | Every character needs a painted pose sheet |
| **B. Pixel cast** | The current townspeople | Chad and Evey get redrawn as pixel art |
| **C. Mix on purpose** | Painted heroes, pixel "dream people" | Cheapest; risky, may look accidental |

**Candidate look for A: the illustrated world.** The owner's mockup (a hand-painted, outlined
world: a dirt path through grass terraces, rocks, bushes, flowers, a stream with a plank
bridge, Chad and Evey walking, hearts, a stamina bar and a round minimap) is doable in this
engine. What it takes:

- **Characters:** painted cycles like the 8-frame run and 6-frame trot sheets. Those are
  side-on only (fine for left and right); up and down need their own cycles. Frames must keep
  the same size and foot line, or they wobble.
- **Ground:** painted, tileable textures (path, grass, dirt, cliff edges, water) instead of the
  current ones.
- **Props:** a kit of painted pieces (trees, bushes, rocks, flowers, barrels, crates), drawn as
  upright painted pictures or as 3D models with painted textures.
- **Ink outlines:** an outline shader so 3D props get the same dark linework.
- **Raised ground:** the mockup's terraces and stream banks need height levels; today's world
  is flat (walls are blocks). Doable, but real engine work.
- **HUD:** hearts, a stamina bar (a new mechanic, e.g. for sprinting) and a minimap.
- The hard part is **volume and consistency**: every town piece (food trucks, shops, poles)
  painted in the same hand. A one-room test comes first: **set up on the beach**, see
  [Beach style test](14-beach-style-test.md).

The engine supports both (painted sheets use 128 px frames with smooth filtering; pixel sheets
use 64 px frames with crisp pixels). See [Assets](04-assets.md) for the sheet format.

## Your input

1. **Option A, B or C?**
2. **Chad's look.** The earlier plan was "based on the owner" (short dark hair, thick brows,
   five o'clock shadow, deadpan stare, grey tee, thin chain). The new sheet has a green jacket
   and backpack. Which is Chad? Is it okay to put a character based on you in a public repo?
3. **Reference games or pictures** for the feel (e.g. Cult of the Lamb, Stardew, Link's
   Awakening remake, Octopath). What do you like about each?
4. **Props and buildings.** Keep the simple code-built 3D models, or replace them with modelled
   ones (Blender, `.glb`)? Should they be more cartoony or more realistic?
5. **Ground.** More painterly textures, or stylised flat colour?
6. **Art source and licence.** Hand-drawn, commissioned, or AI-generated? Check the tool's terms
   allow use in a published game.

## To do

- [ ] Choose A, B or C
- [ ] Settle Chad's final look
- [ ] Make a one-page style sheet: palette swatches, outline thickness, light direction, 3–4
      reference images (kept out of the repo if they aren't yours)
- [ ] Restyle the ground textures to match
- [ ] Decide on props: code-built vs modelled
