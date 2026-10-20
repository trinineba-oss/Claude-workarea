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
- **Chad and Evey (example done, not committed yet).** Painted, outlined, 3/4-view characters
  (green jacket, backpack, cargo pants; Evey the tricolour beagle). They worked well in-game.

## The big open choice: one style for the whole cast

Right now the townspeople, dogs and enemies are **pixel art** (LPC and hand-made), and the new
Chad and Evey are **painted**. They look like they come from different games. Pick one:

| Option | Looks like | Work |
| --- | --- | --- |
| **A. Painted cast** | Your Chad/Evey sheets: smooth, outlined, detailed | Every character needs a painted pose sheet |
| **B. Pixel cast** | The current townspeople | Chad and Evey get redrawn as pixel art |
| **C. Mix on purpose** | Painted heroes, pixel "dream people" | Cheapest; risky, may look accidental |

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
