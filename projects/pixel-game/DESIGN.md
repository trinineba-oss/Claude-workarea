# Game Design (draft v1)

Working title: **Gyro's Awakening** (a parody of *Link's Awakening*; easy to change).

## Pitch

A hero washes up on a strange island and must wake the sleeping **Gyro God** to claim the
**Legendary Lamb Gyro**, the prize at the top of the island's mountain. It is a top-down
adventure in the spirit of *Link's Awakening*: a small, dreamy island full of odd
villagers, secrets behind every bush, and a faintly melancholy mood, played completely
straight while the premise is ridiculous.

## Tone pillars

1. **Parody with a straight face.** Everyone treats the sandwich quest as sacred. The
   humor comes from epic seriousness applied to food, not from winking constantly.
2. **Link's Awakening whimsy.** Quirky townsfolk, talking animals, a dreamlike island,
   short punchy dialogue, small sad-sweet moments between the jokes.
3. **Affectionate, not mean.** We borrow structure and beats, never Nintendo's names,
   characters, art, or music (see *Legal*).
4. **Respect the player's time.** Short rooms, generous saves, no padding.

## Story beats

1. **Washed ashore.** The hero wakes on a beach beside a wrecked delivery boat, with a
   rumbling stomach. A seagull ("Gull-ible", the owl-style guide) explains the island.
2. **The legend.** The Legendary Lamb Gyro rests on the mountain, sealed by the Gyro
   God, who sleeps inside a giant pita. Four **sacred spices** wake it.
3. **Four temples**, one spice each, each with a new item and a boss.
4. **The rival.** A smug kebab lord ("Doner Dread") is hunting the same prize and shows
   up at each temple one step ahead, gloating.
5. **The mountain.** With all four spices the hero wakes the Gyro God and reaches the gyro.
6. **The twist.** The island is the hero's dream at a diner while waiting for an order.
   The final gag: the waiter arrives with the (ordinary, delicious) gyro and the
   credits roll over the empty island. Bittersweet, then funny.

## World

| Area | Role | Notes |
| --- | --- | --- |
| Beach | Tutorial | Movement, bushes, first pickup, the gull's lessons |
| Pita Village | Hub | Shop, house, NPCs, save point, trading quest start |
| Meadow and Olive Grove | Overworld 1 | First enemies, secret caves |
| Temple 1: Taverna | Dungeon 1 | Oregano. Teaches keys, doors and basic combat. |
| Temples 2-4 | Dungeons | Feta Cave, Olive Grove Tower, Rotisserie Tower (after slice) |
| Gyro Mountain | Finale | Opens after four spices |

Overworld is a grid of screen-sized rooms (like the original), scrolling room to room.

## Link's-Awakening-style set pieces, reimagined

- **Shopkeeper rule:** the shop is cheerfully safe until you try to steal; the gag is the
  punishment, not violence.
- **Chain-chomp ally:** a goat on a long chain who guards a path.
- **Trading quest:** a chain of absurd swaps (napkin, then a lemon, then a lost sandal ...)
  ending in a useful reward.
- **Claw-machine minigame:** grab prizes (souvlaki skewers) from a crane machine.
- **Telephone-booth hints:** a wandering villager who gives clues and terrible puns.
- **Sleeping god:** the final boss sequence is waking the Gyro God, not killing it.

## Items and combat

| Role | Item |
| --- | --- |
| Sword | Skewer (starter; hold to charge a spin) |
| Shield | Spatula or pan lid |
| Health | Pita slices (hearts); tzatziki and fries heal |
| Dungeon items | Olive boomerang, lemon bombs, feta hookshot, oregano-dust lantern |
| Currency | Drachmas (coins) |

Enemies: seagulls (swooping), pigeon mobs, angry onions (tear-gas), sentient meatballs
(roll), kebab guards. Bosses are themed on the temple (e.g., a giant feta block that splits).

## Controls and UI (phone, landscape)

- Left: **virtual joystick**. Right: **Attack** (A), **Item** (B), **Interact/Shield** (X),
  small **Pause**.
- Base resolution stays 320x180. The game extends the visible area on wider phones and
  the controls sit in that extra space so they do not cover the action.
- Buttons are at least 48 dp, semi-transparent, repositionable in settings.
- Keyboard and gamepad also work, for testing and the Web build.
- Health shown top-left as pita slices; current item icons top-right.

## Progression and length

- A full game is about 4 to 6 hours; the first **vertical slice is about 30 minutes**:
  beach, village, a small overworld, Temple 1, its boss, and the first spice.
- Saving: automatic on room change plus manual save points, stored in `user://`.
- Gating is by items and spices (as in the original), never by grinding.

## Art and audio direction

- 16x16 tiles and sprites, a small fixed palette (about 24 colors) with a warm
  Mediterranean look: whitewash, terracotta, sea blue, olive green.
- Original chiptune-style music, with a dreamy, slightly detuned feel for the overworld.
- Placeholder art in early milestones; real art replaces it later.

## Technical plan (Godot 4.7)

- `TileMapLayer` for rooms; a room-based camera that scrolls between screens.
- Player and enemies as `CharacterBody2D` with simple state machines.
- Dialogue: data-driven (JSON or Godot resources) with a typewriter text box.
- Virtual controls: custom `TouchScreenButton` and joystick scene, wired to the input map.
- Save system: a single JSON file (`user://save.json`) with a version number.
- Tests: extend the headless smoke test per system (movement, combat, save and load).
- Watch memory: keep sprite sheets in few atlases; stream long music.

## Milestones (each ends in a playable build and a passing `make test`)

1. **Foundation (done):** tile rooms, scrolling room-to-room camera, collisions, virtual
   controls, input map, save and load. Known gap: on 20:9 phones the controls overlap
   about 30 px of the playfield edges; revisit the layout in the polish milestone.
2. **Combat:** skewer attack, health and damage, knockback, two enemy types, pickups.
3. **World and dialogue:** beach, Pita Village, NPCs, text box, signs, the gull guide.
4. **Temple 1:** keys, locked doors, a push-block puzzle, a mini-boss, a new item.
5. **Boss and slice ending:** Temple 1 boss, first spice, hint of the rival.
6. **Polish:** sound effects, music, hit effects, menus, settings, low-end phone testing.

After the slice: Temples 2-4, the trading quest, minigames, the finale and the twist ending.

## Open questions

1. Hero: name, look, and whether they speak (Link's Awakening hero is silent).
2. Final title.
3. Art source: your own, a free pack you upload, or my placeholders for now.
4. Music: do you have any, or should we plan on simple original tracks?

## Legal

This is a parody that borrows structure, not content. Do not use the names Zelda, Link,
Hyrule, Koholint, or Nintendo's sprites, music, or logos in the game or its store listing.
Keep the title and characters distinct enough that nobody mistakes it for an official game.
