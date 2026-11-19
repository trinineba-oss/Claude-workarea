# Image prompts: the remaining animations

The v5 sheets you made from [Image prompts](16-image-prompts.md) are in the game (see
[Character art prompts](15-character-art-prompts.md#status)). These are the sheets still
missing, as complete copy-paste prompts in the same style. Use them the same way:

1. **Attach the model sheet** (`art_src/painted/v5_chad_model.jpg` or `v5_evey_model.jpg`) as
   the image or character reference, so the character matches.
2. Paste one whole block. One sheet = one animation. Side views face **right**.
3. Send the result to Claude to add to the game; the name under each prompt is the file it
   goes in.

## What tripped up the last batch

The new prompts already ask for these; if a result still has one, regenerate rather than fix:

- **A second row** (the back walk came with a blurry row of heads under it): every prompt now
  says *exactly one row, nothing above or below*. If the image tool insists on two rows, ask
  for two rows of 4 with *wide gaps between the rows*. That cut fine for the walk and trot.
- **Things joining frames** (the fishing line ran through every figure): props must stay
  inside their own frame. Cutlass prompts say so.
- **Painted floor shadows**: the tool can soften them, but a clean sheet cuts better.
- **Dust, swooshes, dirt**: the game draws its own effects, so leave them out.

## Done so far

- Chad: cutlass combo away from the viewer (§3), idle back (§9). A second model sheet with a
  blink gives him front and side idles for now.
- Evey: trot away from the viewer (§2), idle side and front (§5, §6).

## Most needed first

1. Chad's **cutlass combo**, side, then toward and away. The swing is the last old-style art you
   see in every fight.
2. Chad's **walk toward the viewer**, and Evey's **trot toward and away**.
3. Evey's **lunge bite** and **sniff and dig**.
4. The **idle** loops.
5. Chad's **runs** toward and away, then the optional sheets.

---

## Chad

### 1. Cutlass combo, side view (8 frames)

Used for: the slash animation (left and right).

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Three-hit cutlass combo, side view facing right, holding a short curved machete-like cutlass in the right hand, 8 frames: ready stance with the blade low; first swing wind-up, blade drawn back; first swing, a fast horizontal slash forward with the arm fully extended; second swing wind-up, blade crossed in front of the chest; second swing, a rising backhand slash; finisher wind-up, cutlass raised overhead in both hands, up on the toes; finisher impact, blade driven down in front, knees bent low; recover to the ready stance. The whole blade stays inside its own frame. Cartoon action, no blood.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: exactly one horizontal row of 8 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, wide clear gaps between frames, nothing overlapping or touching, nothing above or below the row. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no dust, no effects, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/v5_chad_combo_side.jpg`

### 2. Cutlass combo, toward the viewer (8 frames)

Used for: the slash animation (facing down).

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Three-hit cutlass combo, front view, facing and attacking toward the viewer, holding a short curved machete-like cutlass in the right hand, 8 frames: ready stance; first swing wind-up, blade back over the right shoulder; first swing, a fast diagonal slash across the body toward the viewer; second swing wind-up, blade across the left hip; second swing, a rising backhand slash; finisher wind-up, cutlass raised overhead in both hands; finisher impact, blade driven down toward the viewer, knees bent low; recover. The whole blade stays inside its own frame. Cartoon action, no blood.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: exactly one horizontal row of 8 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, wide clear gaps between frames, nothing overlapping or touching, nothing above or below the row. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no dust, no effects, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/v5_chad_combo_down.jpg`

### 3. Cutlass combo, away from the viewer (8 frames)

Used for: the slash animation (facing up).

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Three-hit cutlass combo, back view, facing and attacking away from the viewer (we see his back and backpack), holding a short curved machete-like cutlass in the right hand, 8 frames: ready stance; first swing wind-up, blade out to the right; first swing, a fast horizontal slash to the left; second swing wind-up; second swing, a backhand slash to the right; finisher wind-up, cutlass raised overhead in both hands; finisher impact, blade driven down ahead of him, knees bent low; recover. The whole blade stays inside its own frame. Cartoon action, no blood.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: exactly one horizontal row of 8 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, wide clear gaps between frames, nothing overlapping or touching, nothing above or below the row. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no dust, no effects, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/v5_chad_combo_up.jpg`

### 4. Walk toward the viewer (8 frames)

Used for: the walk when moving down (today the 3/4 walk stands in).

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Walk cycle, front view, walking toward the viewer, 8-frame loop: contact, down, passing, up, then the same with the other leg; arms swing opposite the legs; the backpack straps move slightly.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: exactly one horizontal row of 8 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, wide clear gaps between frames, nothing overlapping or touching, nothing above or below the row. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no dust, no effects, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/v5_chad_walk_down.jpg`

### 5. Run toward the viewer (8 frames)

Used for: the run when moving down.

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Run cycle, front view, running toward the viewer, 8-frame loop: contact, down, passing, up (both feet off the ground), then the same with the other leg; fists pumping, leaning slightly forward, determined look.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: exactly one horizontal row of 8 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, wide clear gaps between frames, nothing overlapping or touching, nothing above or below the row. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no dust, no effects, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/v5_chad_run_down.jpg`

### 6. Run away from the viewer (8 frames)

Used for: the run when moving up.

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Run cycle, back view, running away from the viewer (we see his back and backpack), 8-frame loop: contact, down, passing, up (both feet off the ground), then the same with the other leg; elbows pumping, the backpack bouncing.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: exactly one horizontal row of 8 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, wide clear gaps between frames, nothing overlapping or touching, nothing above or below the row. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no dust, no effects, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/v5_chad_run_up.jpg`

### 7. Idle, front (4 frames)

Used for: standing still, facing down.

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Idle breathing loop, front view facing the viewer, 4 frames: relaxed stance; chest and shoulders rise slightly; a slow blink; a small glance to the side. The feet never move.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: exactly one horizontal row of 4 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, wide clear gaps between frames, nothing overlapping or touching, nothing above or below the row. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no dust, no effects, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/v5_chad_idle_down.jpg`

### 8. Idle, side (4 frames)

Used for: standing still, facing left or right.

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Idle breathing loop, side view facing right, 4 frames: relaxed stance; chest and shoulders rise slightly; a slow blink; a small shift of weight. The feet never move.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: exactly one horizontal row of 4 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, wide clear gaps between frames, nothing overlapping or touching, nothing above or below the row. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no dust, no effects, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/v5_chad_idle_side.jpg`

### 9. Idle, back (4 frames)

Used for: standing still, facing up.

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Idle breathing loop, back view (we see his back and backpack), 4 frames: relaxed stance; shoulders rise slightly; head turns a little to the left; back to centre. The feet never move.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: exactly one horizontal row of 4 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, wide clear gaps between frames, nothing overlapping or touching, nothing above or below the row. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no dust, no effects, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/v5_chad_idle_up.jpg`

### 10. Dodge roll toward the viewer (optional) (6 frames)

Used for: the roll when dodging down (today the side roll stands in).

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Dodge roll, front view, rolling toward the viewer, 6 frames: quick crouch, tuck with the head down, tumbling forward over the shoulder, come up on one knee, rise, recover into a ready stance.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: exactly one horizontal row of 6 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, wide clear gaps between frames, nothing overlapping or touching, nothing above or below the row. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no dust, no effects, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/v5_chad_roll_down.jpg`

### 11. Dodge roll away from the viewer (optional) (6 frames)

Used for: the roll when dodging up.

```text
Chad: a young Trinidadian man, brown skin, short dark buzz cut, thick eyebrows, calm deadpan expression. Olive-green padded jacket with two chest pockets, open over a black t-shirt; black cargo trousers with side pockets; black lace-up boots; brown canvas backpack with two straps. Slightly stylised heroic proportions, head a little large for the body.

Dodge roll, back view, rolling away from the viewer (we see his backpack), 6 frames: quick crouch, tuck, tumbling forward over the shoulder, come up on one knee, rise, recover into a ready stance.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: exactly one horizontal row of 6 frames of the same character, evenly spaced, left to right in animation order, each figure complete from head to feet, wide clear gaps between frames, nothing overlapping or touching, nothing above or below the row. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no dust, no effects, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/v5_chad_roll_up.jpg`

---

## Evey

### 1. Trot toward the viewer (6 frames)

Used for: the walk when moving down (today a bobbing still).

```text
Evey: a small, friendly tricolour beagle. Cream-and-tan face, white muzzle and a thin white blaze between the eyes, long floppy tan ears, a dark grey-brown saddle over her back, tan sides, white chest, white legs and paws, a tail that is dark with a white tip. No collar. Soft rounded body, expressive eyes.

Trot cycle, front view, trotting toward the viewer, 6-frame loop: diagonal legs move together, ears bouncing, head up and happy, tail wagging behind her.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: exactly one horizontal row of 6 frames of the same character, evenly spaced, left to right in animation order, each figure complete from ears to paws, tail included, wide clear gaps between frames, nothing overlapping or touching, nothing above or below the row. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no dust, no effects, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/v5_evey_trot_down.jpg`

### 2. Trot away from the viewer (6 frames)

Used for: the walk when moving up (today a bobbing still).

```text
Evey: a small, friendly tricolour beagle. Cream-and-tan face, white muzzle and a thin white blaze between the eyes, long floppy tan ears, a dark grey-brown saddle over her back, tan sides, white chest, white legs and paws, a tail that is dark with a white tip. No collar. Soft rounded body, expressive eyes.

Trot cycle, back view, trotting away from the viewer (we see her back, rump and white-tipped tail held up), 6-frame loop: diagonal legs move together, ears bouncing, tail swaying.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: exactly one horizontal row of 6 frames of the same character, evenly spaced, left to right in animation order, each figure complete from ears to paws, tail included, wide clear gaps between frames, nothing overlapping or touching, nothing above or below the row. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no dust, no effects, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/v5_evey_trot_up.jpg`

### 3. Sniff and dig, side view (6 frames)

Used for: sniffing out and digging up buried things.

```text
Evey: a small, friendly tricolour beagle. Cream-and-tan face, white muzzle and a thin white blaze between the eyes, long floppy tan ears, a dark grey-brown saddle over her back, tan sides, white chest, white legs and paws, a tail that is dark with a white tip. No collar. Soft rounded body, expressive eyes.

Sniff and dig, side view facing right, 6 frames: nose down to the ground sniffing; nose down, tail up and wagging; front paws digging, left paw down; right paw down; left paw down; looking up proudly. No dirt, no hole: the game adds those.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: exactly one horizontal row of 6 frames of the same character, evenly spaced, left to right in animation order, each figure complete from ears to paws, tail included, wide clear gaps between frames, nothing overlapping or touching, nothing above or below the row. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no dust, no effects, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/v5_evey_dig.jpg`

### 4. Lunge bite, side view (4 frames)

Used for: her attack when sicced on an enemy.

```text
Evey: a small, friendly tricolour beagle. Cream-and-tan face, white muzzle and a thin white blaze between the eyes, long floppy tan ears, a dark grey-brown saddle over her back, tan sides, white chest, white legs and paws, a tail that is dark with a white tip. No collar. Soft rounded body, expressive eyes.

Lunge bite, side view facing right, 4 frames: crouch low ready to spring, ears back; spring forward, body stretched, front paws off the ground; snap with jaws open; land and shake her head. Playful cartoon, not vicious, no blood.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: exactly one horizontal row of 4 frames of the same character, evenly spaced, left to right in animation order, each figure complete from ears to paws, tail included, wide clear gaps between frames, nothing overlapping or touching, nothing above or below the row. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no dust, no effects, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/v5_evey_bite.jpg`

### 5. Idle, side (4 frames)

Used for: standing still, facing left or right.

```text
Evey: a small, friendly tricolour beagle. Cream-and-tan face, white muzzle and a thin white blaze between the eyes, long floppy tan ears, a dark grey-brown saddle over her back, tan sides, white chest, white legs and paws, a tail that is dark with a white tip. No collar. Soft rounded body, expressive eyes.

Idle loop, side view facing right, standing on all four paws, 4 frames: relaxed; breathing in; tail wag to one side; ear twitch. The paws never move.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: exactly one horizontal row of 4 frames of the same character, evenly spaced, left to right in animation order, each figure complete from ears to paws, tail included, wide clear gaps between frames, nothing overlapping or touching, nothing above or below the row. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no dust, no effects, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/v5_evey_idle_side.jpg`

### 6. Idle, front (4 frames)

Used for: standing still, facing down.

```text
Evey: a small, friendly tricolour beagle. Cream-and-tan face, white muzzle and a thin white blaze between the eyes, long floppy tan ears, a dark grey-brown saddle over her back, tan sides, white chest, white legs and paws, a tail that is dark with a white tip. No collar. Soft rounded body, expressive eyes.

Idle loop, front view facing the viewer, standing on all four paws, 4 frames: relaxed; head tilt to one side; back to centre with a slow blink; a small pant with the tongue out. The paws never move.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: exactly one horizontal row of 4 frames of the same character, evenly spaced, left to right in animation order, each figure complete from ears to paws, tail included, wide clear gaps between frames, nothing overlapping or touching, nothing above or below the row. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no dust, no effects, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/v5_evey_idle_down.jpg`

### 7. Gallop toward and away (optional) (10 frames)

Used for: her run when moving up or down.

```text
Evey: a small, friendly tricolour beagle. Cream-and-tan face, white muzzle and a thin white blaze between the eyes, long floppy tan ears, a dark grey-brown saddle over her back, tan sides, white chest, white legs and paws, a tail that is dark with a white tip. No collar. Soft rounded body, expressive eyes.

Gallop cycles: the first 5 frames a gallop toward the viewer (front view, ears flying, front paws reaching), the last 5 frames a gallop away from the viewer (back view, white-tipped tail streaming). Two separate 5-frame loops in one row.

Stylized hand-painted 3D look, like a modern indie action RPG (Hades, Cult of the Lamb, Sea of Stars): clear sculpted volume, strong warm key light from the upper left, soft cool bounce light on the shadow side, a thin bright rim light along the right edges, painted form shadows under the chin, under the arms and body, and between the legs, ambient occlusion in the folds. Clean dark brown outline. Saturated but natural colours. Seen from slightly above, about 30 degrees, like a top-down game camera.

Game sprite sheet: exactly one horizontal row of 10 frames of the same character, evenly spaced, left to right in animation order, each figure complete from ears to paws, tail included, wide clear gaps between frames, nothing overlapping or touching, nothing above or below the row. Same scale in every frame, feet on the same baseline. Identical lighting in every frame, light always from the upper left. Plain flat mid-grey background (#464A4B). No floor, no cast shadow on the ground, no motion lines, no dust, no effects, no arrows, no numbers, no text, no labels, no border. Exactly the same character design, colours and proportions in every frame.
```

Save as `art_src/painted/v5_evey_run_updown.jpg`

---

## Optional extras

- Chad **hurt from behind** (3 frames, back view) so a hit from below doesn't turn him to face
  the camera.
- Evey **bark toward the viewer** and **away** (2 frames each).
- Chad **talking** (4 frames, front: mouth open and closed, a shrug, a hand gesture) for
  conversations.

Check that the image tool's terms allow use in a published game, and note which tool made
which sheet.
