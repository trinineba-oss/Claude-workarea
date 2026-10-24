# 15. Character art prompts (Chad and Evey)

Prompts for generating every animation and angle Chad and Evey need, in the painted style of the
owner's mockup and sheets (`art_src/painted/`), laid out so `tools/painted_sheets.py` can cut them
into smooth in-game animation.

## Status

**In the game:** Chad from `art_src/painted/sheet_v2.jpg` (turnaround, 7-frame side walk,
4-frame cutlass swing). Evey from `sheet_v3.jpg` (turnaround, 4-frame side walk, crouch and
leap, a biting lunge, sniff, a happy standing pose). Evey's look is now the v3 one: **no
collar, white tail tip** (update her description below to match before generating more).

**Still needed, in order:**

1. Walking **toward** and **away from** the camera (Chad 8 frames each, Evey 8 each). Today
   those directions slide the standing pose with a small bob.
2. **Idle** loops (4 frames, all three directions) for both.
3. Evey **sit** (2 frames, front and side); she uses her standing pose for now. A longer
   **walk** for her (8 frames; the sheet has 4).
4. Chad's swing **facing down and up** as full sequences (the sheet has one frame per angle).
5. Then priorities 2 and 3 in the tables below.

## How the game uses the art

- **Four directions:** facing the camera (down), back to the camera (up), and side (right).
  Left is the side view mirrored, so **draw three directions**: front, back, side-facing-right.
- **Camera:** the game looks down at about 40–50°, like the mockup. Draw the characters as
  seen **from slightly above** (about 30°), not flat side-on from ground level.
- **Smoothness comes from frame count and consistency:** 8 frames for walking and running,
  4–6 for most actions, every frame the same size, on the same baseline, in the same style.

## Workflow (do it in this order)

1. **Make the reference turnaround first** (prompt A below) for each character. Pick the best
   result. That image is the "model sheet".
2. **Feed the model sheet as an image reference** for every other sheet (most image tools have
   a "character reference" or "image prompt" option). This is what keeps Chad looking like Chad
   from sheet to sheet.
3. **One sheet = one animation in one direction**, frames in a single row, left to right.
   Generators lose consistency with more than ~8 figures per image.
4. Check each sheet against the rules below. Regenerate the ones that break them (a missing
   backpack, a different jacket, a frame out of order).
5. Save as `art_src/painted/<character>_<animation>_<direction>.png`, e.g.
   `chad_walk_side.png`, and ask Claude to add them to the game.

## Rules for every sheet (paste these into every prompt)

```
Game sprite sheet, a single horizontal row of [N] animation frames of the same character,
evenly spaced, left to right in animation order, each figure complete from head to feet with
clear space between frames, no overlapping. All frames the same scale with the feet on the
same baseline. Seen from slightly above, about 30 degrees. Flat plain mid-grey background
(#464A4B), no floor, no cast shadow, no motion lines, no arrows, no numbers, no text, no
labels, no border. Consistent lighting from the upper left. Hand-painted cosy cartoon
illustration style with clean dark brown outlines and soft cel shading, like a modern indie
adventure game. Exactly the same character design, colours and proportions in every frame.
```

The flat grey background and **no floor shadows, motion lines or numbers** matter most: the
cutting tool removes the grey, and anything else on the background ends up stuck to the
character. The game draws its own shadows.

## Character descriptions (paste the right one into every prompt)

**Chad**

```
Chad: a young Trinidadian man with brown skin, a short dark buzz cut, thick eyebrows and a
calm, deadpan expression. He wears an olive-green padded jacket with two chest pockets, open
over a black t-shirt, black cargo trousers with side pockets, and black lace-up boots. He
carries a brown canvas backpack with two shoulder straps. Slightly stylised, friendly
proportions (head a little large for the body).
```

**Evey** (based on the owner's beagle; check the details against her photo)

```
Evey: a small, friendly tricolour beagle. Cream-and-tan face with a white muzzle and a thin
white blaze between the eyes, long floppy tan ears, a grey-brown saddle over her back, tan
sides, white chest, white legs and paws, and a tail that is dark with a [dark / white] tip.
[No collar. / A thin red collar.] Soft, rounded, cute proportions.
```

Decide two things before generating: **Evey's tail tip** (the owner remembered it dark, the
generated sheets drew it white) and **collar or no collar** (the sheets disagree).

## A. Reference turnarounds (make these first)

```
Character model sheet of [CHARACTER DESCRIPTION]. Five views in one row: front view facing
the viewer, three-quarter front view facing right, side view facing right, three-quarter
back view, back view. Standing relaxed, arms at the sides (paws flat on the ground for Evey).
[RULES]
```

## B. The animations

Directions: **F** = facing the viewer, **B** = back to the viewer, **S** = side view facing
right. Each line is one sheet per direction listed. Fill the template:

```
[CHARACTER DESCRIPTION] — [ANIMATION], [DIRECTION], [N]-frame loop: [MOTION].
[RULES]
```

### Chad

| Priority | Animation | Directions | Frames | Motion (paste as [MOTION]) |
| --- | --- | --- | --- | --- |
| 1 | Idle | F, B, S | 4, loop | standing relaxed, breathing gently, shoulders rise and fall slightly, backpack shifts a little |
| 1 | Walk | F, B, S | 8, loop | a brisk walk cycle: contact, down, passing, up, then the same with the other leg; arms swing opposite the legs |
| 2 | Run | F, B, S | 8, loop | a jogging run cycle: contact, compression, passing, push-off, then the other leg; body leans slightly forward, arms pump |
| 1 | Cutlass swing | F, B, S | 6 | holding a short curved cutlass (a machete-like blade) in the right hand: wind-up, swing across the body, follow-through, recover; cartoon, no blood |
| 2 | Hurt | F, S | 3 | flinches back from a hit, eyes squeezed shut, then recovers |
| 2 | Faint | F | 4 | gets dizzy, wobbles, sits down hard, lies on his back with swirly eyes (comic, not violent) |
| 2 | Throw | F, B, S | 4 | throws a coconut boomerang overarm: reach back, step forward, release, follow-through |
| 2 | Pick up / interact | F, S | 4 | bends down, reaches, picks something small up, stands back up |
| 3 | Item get | F | 2 | holds an item up above his head with both hands, proud, mouth open in delight |
| 3 | Eat | F | 4 | takes a bite of a doubles (a folded flatbread), chews happily |
| 3 | Fishing | S | 6 | casts a fishing rod: rod back, flick forward, line out, waits, a tug, reels in |
| 3 | Wake up | F | 4 | lying on his back asleep, stirs, sits up rubbing his eyes, looks around confused |
| 4 | Jump (Orange Castle) | S | 6 | anticipation crouch, launch, rising, peak, falling, landing crouch |
| 4 | Climb (Orange Castle) | B | 4, loop | climbing a ladder, hands and feet alternating |

### Evey

| Priority | Animation | Directions | Frames | Motion (paste as [MOTION]) |
| --- | --- | --- | --- | --- |
| 1 | Idle | F, B, S | 4, loop | standing, tail wagging side to side, ears twitching, breathing |
| 1 | Trot (walk) | F, B, S | 8, loop | a trotting cycle, diagonal legs moving together, head bobbing, ears flapping, tail up |
| 2 | Gallop (run) | S, F, B | 6, loop | a full gallop: front legs reach forward, back legs push, all four paws briefly off the ground, ears streaming back |
| 1 | Sit | F, S | 2, loop | sitting upright, tail sweeping the ground, looking up attentively |
| 1 | Bite / lunge | F, B, S | 4 | crouches, lunges forward with mouth open, snaps, pulls back |
| 2 | Bark | F, S | 3 | plants her front paws, barks with mouth open and ears up, then closes |
| 2 | Dig | S, B | 4, loop | front paws digging fast, dirt flying behind her, tail up |
| 2 | Sniff | S, F | 6, loop | walking slowly with nose to the ground, tail wagging |
| 3 | Lie down / tired | F, S | 3 | lies down, rests her head on her paws, a slow blink |
| 3 | Carry | S, F | 8, loop | the trot cycle while carrying a small object (a coin or a slipper) in her mouth |
| 3 | Swim | S | 4, loop | paddling, only head and top of back above the water line, ears floating |
| 3 | Nudge | S | 3 | pushes her nose against someone, tail wagging (for waking Chad on the wharf) |
| 3 | Duel poses | S | 6 | one frame each: ready stance, growl with hackles up, bite, flinch, happy win (tail wag, tongue out), sad lose (ears down) |

**Priority 1** is what the game needs now (standing, moving, attacking in every direction).
That's 9 sheets for Chad and 11 for Evey, plus a turnaround each; the rest can come later.

## Example: one complete prompt

```
Chad: a young Trinidadian man with brown skin, a short dark buzz cut, thick eyebrows and a
calm, deadpan expression. He wears an olive-green padded jacket with two chest pockets, open
over a black t-shirt, black cargo trousers with side pockets, and black lace-up boots. He
carries a brown canvas backpack with two shoulder straps. Slightly stylised, friendly
proportions (head a little large for the body). — Walk, side view facing right, 8-frame
loop: a brisk walk cycle: contact, down, passing, up, then the same with the other leg; arms
swing opposite the legs.
Game sprite sheet, a single horizontal row of 8 animation frames of the same character,
evenly spaced, left to right in animation order, each figure complete from head to feet with
clear space between frames, no overlapping. All frames the same scale with the feet on the
same baseline. Seen from slightly above, about 30 degrees. Flat plain mid-grey background
(#464A4B), no floor, no cast shadow, no motion lines, no arrows, no numbers, no text, no
labels, no border. Consistent lighting from the upper left. Hand-painted cosy cartoon
illustration style with clean dark brown outlines and soft cel shading, like a modern indie
adventure game. Exactly the same character design, colours and proportions in every frame.
```

Attach Chad's model sheet as the image reference.

## Checklist for each result

- [ ] Same outfit, colours and proportions as the model sheet (backpack present, jacket olive)
- [ ] Right number of frames, in order, in one row, not touching
- [ ] Feet on one baseline, same size in every frame
- [ ] Plain grey background: no floor, shadows, lines, arrows or numbers
- [ ] The loop works: the last frame leads back into the first
- [ ] Right direction (side sheets face right)

## Licence

Check that the image tool's terms allow its output in a published, possibly paid, game, and
keep a note of which tool made which sheet.
