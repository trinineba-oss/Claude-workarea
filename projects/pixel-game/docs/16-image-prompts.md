# Image prompts: Chad and Evey

Copy-paste prompts for generating Chad and Evey's sprite sheets in a painted style with real
volume (light, shadow, rim light), laid out so `tools/painted_sheets.py` can cut them straight
into the game. Each prompt below is complete: copy the whole block.

## How to use them

1. **Make the model sheet first** for each character. Pick the best result.
2. For every other sheet, **attach that model sheet as the image reference** (the
   "character reference" or "image prompt" option of your image tool). This keeps the
   character the same from sheet to sheet.
3. One sheet = one animation. Side views always face **right** (the game mirrors them).
4. Save each result in `art_src/painted/` with the file name given under its prompt, and ask
   Claude to add it to the game.

## Check every result

- [ ] Same outfit, colours and proportions as the model sheet
- [ ] The right number of frames, in one row, not touching
- [ ] Feet on one line, same size in every frame
- [ ] Light from the upper left in every frame
- [ ] Plain grey background: no floor shadow, motion lines, arrows or numbers
- [ ] Side views face right; the loop runs back into its first frame

## If a result is off, add one of these

| Problem | Add to the prompt |
| --- | --- |
| Looks flat | `strong chiaroscuro, deep form shadows, sculpted like a 3D figurine` |
| Looks plasticky / too 3D | `visible painterly brushwork, hand-painted texture` |
| Lighting changes between frames | `identical lighting in every frame, light always from the upper left` (already included; repeat it at the start) |
| Frames touch or overlap | `wide even gaps between frames` |
| Floor shadow appears | `isolated on a plain grey background, no ground, no shadow` |

---

## Chad

### 1. Model sheet (make first) (5 frames)

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Character model sheet: five views in one row: front, three-quarter front facing right, side facing right, three-quarter back, back. Standing relaxed, arms at the sides.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: one horizontal row of 5 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, clear space between frames, nothing overlapping. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/chad_model_v5.png`

### 2. Walk, side view (8 frames)

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Walk cycle, side view facing right, 8-frame loop: contact, down, passing, up, then the same with the other leg; arms swing opposite the legs; the backpack bounces slightly.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: one horizontal row of 8 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, clear space between frames, nothing overlapping. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/chad_walk_side_v5.png`

### 3. Walk toward the viewer (8 frames)

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Walk cycle, front view, walking toward the viewer, 8-frame loop: contact, down, passing, up, then the other leg; arms swing opposite the legs.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: one horizontal row of 8 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, clear space between frames, nothing overlapping. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/chad_walk_down_v5.png`

### 4. Walk away from the viewer (8 frames)

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Walk cycle, back view, walking away from the viewer, 8-frame loop: contact, down, passing, up, then the other leg; the backpack is visible and bounces slightly.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: one horizontal row of 8 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, clear space between frames, nothing overlapping. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/chad_walk_up_v5.png`

### 5. Idle (4 frames)

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Idle loop, front view, 4 frames: standing relaxed, breathing, shoulders rising and falling, a small shift of weight.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: one horizontal row of 4 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, clear space between frames, nothing overlapping. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/chad_idle_v5.png`

### 6. Cutlass combo (6 frames)

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Cutlass combo, side view facing right, holding a short curved machete-like cutlass in the right hand, 6 frames: wind-up, fast horizontal slash, return slash the other way, big overhead finisher, impact, recover. Cartoon action, no blood.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: one horizontal row of 6 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, clear space between frames, nothing overlapping. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/chad_combo_side_v5.png`

### 7. Dodge roll (6 frames)

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Dodge roll, side view facing right, 6 frames: quick crouch, tuck, roll forward over the shoulder, come up on one knee, rise, recover into a ready stance.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: one horizontal row of 6 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, clear space between frames, nothing overlapping. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/chad_roll_side_v5.png`

### 8. Hurt (3 frames)

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Hurt reaction, side view facing right, 3 frames: flinch back from a hit with eyes squeezed shut, stagger, recover.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: one horizontal row of 3 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, clear space between frames, nothing overlapping. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/chad_hurt_side_v5.png`


---

## Evey

### 1. Model sheet (make first) (5 frames)

```text
Evey: a small, friendly tricolour beagle. Cream-and-tan face, white muzzle and a thin white blaze between the eyes, long floppy tan ears, a dark grey-brown saddle over her back, tan sides, white chest, white legs and paws, a tail that is dark with a white tip. No collar. Soft rounded body, expressive eyes.

Character model sheet: five views in one row: front, three-quarter front facing right, side facing right, three-quarter back, back. Standing on all four paws, tail up.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: one horizontal row of 5 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, clear space between frames, nothing overlapping. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/evey_model_v5.png`

### 2. Trot, side view (8 frames)

```text
Evey: a small, friendly tricolour beagle. Cream-and-tan face, white muzzle and a thin white blaze between the eyes, long floppy tan ears, a dark grey-brown saddle over her back, tan sides, white chest, white legs and paws, a tail that is dark with a white tip. No collar. Soft rounded body, expressive eyes.

Trot cycle, side view facing right, 8-frame loop: diagonal legs moving together, head bobbing, ears bouncing, tail up and wagging.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: one horizontal row of 8 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, clear space between frames, nothing overlapping. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/evey_trot_side_v5.png`

### 3. Trot toward the viewer (6 frames)

```text
Evey: a small, friendly tricolour beagle. Cream-and-tan face, white muzzle and a thin white blaze between the eyes, long floppy tan ears, a dark grey-brown saddle over her back, tan sides, white chest, white legs and paws, a tail that is dark with a white tip. No collar. Soft rounded body, expressive eyes.

Trot cycle, front view, trotting toward the viewer, 6-frame loop: legs alternating, ears bouncing, tongue out happily.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: one horizontal row of 6 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, clear space between frames, nothing overlapping. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/evey_trot_down_v5.png`

### 4. Trot away from the viewer (6 frames)

```text
Evey: a small, friendly tricolour beagle. Cream-and-tan face, white muzzle and a thin white blaze between the eyes, long floppy tan ears, a dark grey-brown saddle over her back, tan sides, white chest, white legs and paws, a tail that is dark with a white tip. No collar. Soft rounded body, expressive eyes.

Trot cycle, back view, trotting away from the viewer, 6-frame loop: legs alternating, tail up and wagging.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: one horizontal row of 6 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, clear space between frames, nothing overlapping. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/evey_trot_up_v5.png`

### 5. Idle and sit (4 frames)

```text
Evey: a small, friendly tricolour beagle. Cream-and-tan face, white muzzle and a thin white blaze between the eyes, long floppy tan ears, a dark grey-brown saddle over her back, tan sides, white chest, white legs and paws, a tail that is dark with a white tip. No collar. Soft rounded body, expressive eyes.

Four frames: standing idle front view with the tail wagging (2 frames), then sitting upright front view with the tail sweeping the ground (2 frames).

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: one horizontal row of 4 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, clear space between frames, nothing overlapping. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/evey_idle_sit_v5.png`

### 6. Lunge bite (4 frames)

```text
Evey: a small, friendly tricolour beagle. Cream-and-tan face, white muzzle and a thin white blaze between the eyes, long floppy tan ears, a dark grey-brown saddle over her back, tan sides, white chest, white legs and paws, a tail that is dark with a white tip. No collar. Soft rounded body, expressive eyes.

Lunge bite, side view facing right, 4 frames: low crouch, spring forward with mouth open, snap, land.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: one horizontal row of 4 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, clear space between frames, nothing overlapping. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/evey_bite_side_v5.png`

### 7. Sniff and dig (6 frames)

```text
Evey: a small, friendly tricolour beagle. Cream-and-tan face, white muzzle and a thin white blaze between the eyes, long floppy tan ears, a dark grey-brown saddle over her back, tan sides, white chest, white legs and paws, a tail that is dark with a white tip. No collar. Soft rounded body, expressive eyes.

Six frames, side view facing right: nose to the ground sniffing (2 frames), then digging fast with the front paws, dirt flying behind (4 frames).

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: one horizontal row of 6 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, clear space between frames, nothing overlapping. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/evey_sniff_dig_v5.png`


---

## Priority

Most needed first: Chad's **side walk**, then his **front and back walks**, then Evey's
**side trot**, then the rest.

Check that the image tool's terms allow use in a published game, and note which tool made
which sheet.
