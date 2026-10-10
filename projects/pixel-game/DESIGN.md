# Game Design (draft v3)

Title: **Chad and the Legendary Lamb Gyro** (a parody of *Link's Awakening*). The hero is **Chad**.

## Pitch

Chad washes up at **San Fernando Wharf** and finds a strange, dreamlike
**San Fernando, Trinidad**. The **Legendary Lamb Gyro** waits at the top of San Fernando
Hill, and only the **Gyro God**, sleeping inside a giant roti, can release it. It is a top-down
adventure in the spirit of *Link's Awakening*: a small world full of odd locals, secrets behind
every bush, and a faintly melancholy mood, played completely straight while the premise
is ridiculous. The humor is local: food, liming, maxi taxis, and the way everyone has an
opinion about everything.

## Tone pillars

1. **Parody with a straight face.** Everyone treats the sandwich quest as sacred. The
   humor comes from epic seriousness applied to everyday life, not from winking constantly.
2. **Link's Awakening whimsy.** Quirky townsfolk, talking animals, a dreamlike world,
   short punchy dialogue, small sad-sweet moments between the jokes.
3. **Affectionate and local.** We celebrate Trinidad, we do not caricature it. Dialect is
   used lightly and written or reviewed by someone from there. Trinidad is a mix of many
   cultures; jokes punch at situations (traffic, gossip, queues, pepper), never at groups.
4. **Respect the player's time.** Short rooms, generous saves, no padding.
5. **Original, not borrowed.** We borrow structure and beats, never Nintendo's names,
   characters, art, or music, and never real brands or real people (see *Legal*).

## Story beats

1. **Washed up at the wharf.** Chad wakes on San Fernando Wharf beside a wrecked boat, hungry. A
   scarlet ibis ("Ibis", the owl-style guide, or a gloomy corbeau for a funnier tone) explains
   the world.
2. **The legend.** The Legendary Lamb Gyro rests atop San Fernando Hill, sealed by the
   Gyro God, who sleeps inside a giant roti. Four **sacred seasonings** wake it.
3. **Four temples**, one seasoning each, each with a new item and a boss.
4. **The rival.** A smug fast-food baron ("Doner Dread") is chasing the same prize and shows
   up at each temple one step ahead, gloating.
5. **The hill.** With all four seasonings the hero wakes the Gyro God and reaches the gyro.
6. **The twist.** The whole thing was a dream. Chad dozed off by the gyro truck on
   **Lady Hailes Avenue, by Cross Crossing**, while waiting for a gyro. The final scene: the street vendor shakes them awake ("Boss,
   yuh gyro ready!" — or "Chad! Yuh gyro ready!"), Chad collects an ordinary, delicious gyro, and the credits roll
   over the busy food stretch. Bittersweet, then funny. The vendor has been in the dream
   all along, in a different role (the shopkeeper, the riddle men's cook, or the Gyro God's
   voice; your call).

   *Optional prologue:* a 30-second scene at the gyro truck: Chad orders a
   gyro, is told "wait small", sits down and nods off, then wakes up on the wharf. It makes
   the ending land harder, and it is cheap to build.

## World (San Fernando, stylized)

Real places are inspiration; layouts are invented and squeezed into screen-sized rooms.
Cross Crossing and Lady Hailes Avenue are based on the owner's Street View footage
(reference only, not stored in the repo): a busy junction where **Cipero Street** meets the
road east, with a gas station, a tall yellow building and poles with overhead wires
everywhere; then **Lady Hailes Avenue**, a long avenue with grass verges, car parks and a
row of brightly painted **food trucks and trailers** (gyros, burgers, pork, seafood boil,
corn soup, hot dogs, doubles...). Trucks use generic food names, never the real businesses'.

| Area | Role | Ideas |
| --- | --- | --- |
| San Fernando Wharf | Tutorial, start | Wrecked boat, crabs, old cranes and crates, the ibis/corbeau guide |
| Cross Crossing (built) | Junction | Gas station, yellow building, poles and wires; busy traffic on Cipero Street that Chad has to cross |
| Lady Hailes Avenue (built) | Food-truck hub | Gyros, doubles and corn soup trucks and vendors; the gyro man; the ending happens here |
| Lady Hailes east (built) | Overworld | Pork and seafood trucks; a fenced lot with corbeaux after the food |
| Harris Promenade | Hub | Shops, benches, NPCs, save point, maxi taxi stop |
| High Street and market | Overworld | More vendors, the rum-shop riddle men |
| Skinner Park | Overworld / minigame | A cricket or football minigame |
| Temples 1-4 | Dungeons | Ideas: quarry caves, the market at night, the refinery tower, the old wharf |
| San Fernando Hill | Finale | Opens after four seasonings |

The overworld is a grid of screen-sized rooms (as built in milestone 1).

## Link's-Awakening-style set pieces, reimagined

- **Shopkeeper rule:** a Cross Crossing vendor is cheerful until you try to skip the line or steal;
  the gag is the punishment, not violence.
- **Maxi taxis:** colorful minibuses as fast travel between hubs (the ocarina/telephone idea).
- **Chain-chomp ally:** a pothound on a long rope who guards a path.
- **Trading quest:** a chain of absurd favors along the Cross Crossing stalls (a bag of ice, a
  sno-cone, a lost slipper ...) ending in a useful reward.
- **Rum-shop riddle men:** a group of "liming" locals who give clues and terrible advice.
- **Sleeping god:** the final boss sequence is waking the Gyro God, not killing it.

## Items and combat (ideas, your call)

| Role | Item |
| --- | --- |
| Sword | Cutlass (starter; hold to charge a spin) |
| Shield | Tawa (the roti griddle) |
| Health | "Doubles" as hearts; coconut water and pepper sauce heal |
| Dungeon items | Coconut boomerang, wiri-wiri pepper bombs, flambeau lantern, bamboo grapple |
| Currency | Dollars (TT$) |

Enemies: corbeaux (swoop), stray dogs, mosquitoes, nosy neighbours (the "maco": follows and
gossips), jumbies and soucouyant fireballs (comic, not scary), steups teens (a teeth-suck
shockwave). Bosses are themed on the temple.

## Controls and UI (phone, landscape)

- Left: **virtual joystick**. Right: **Attack** (A), **Item** (B), **Interact/Shield** (X),
  small **Pause**.
- Base resolution is 320x176 (rooms are 20x11 tiles). The game extends the visible area on
  wider phones; the controls currently overlap about 30 px of the playfield on 20:9 phones.
- Buttons are at least 48 dp, semi-transparent, repositionable in settings later.
- Keyboard and gamepad also work, for testing and the Web build.
- Health shown top-left; current item icons top-right.

## Progression and length

- A full game is about 4 to 6 hours; the first **vertical slice is about 30 minutes**:
  wharf, Promenade, a small overworld, Temple 1, its boss, and the first seasoning.
- Saving: automatic on room change, pause and app background, stored in `user://`.
- Gating is by items and seasonings (as in the original), never by grinding.

## Art and audio direction

- **HD 2D, smooth and lit** (switched from pixel art): clean cartoon shapes with soft
  shadows, organic blended ground (sand, grass, dirt and water melt into each other), animated
  water with shore foam, depth-sorted scenery, particles, a soft vignette. A hot, saturated
  Caribbean palette: flamboyant red and poui yellow blooms, mango green, concrete pastels,
  sea blue.
- **Day and night cycle (built):** a 12-minute day; dusk and night tint the world, and food
  trucks, the gas station, street lamps and headlights light up. Night can change what people
  say (the ibis sleeps; the food trucks come into their own after dark).
- 64 px tiles on a 1280x704 base resolution, scaled smoothly to any screen.
- Music: chiptune with **steelpan** timbres, soca and calypso rhythms for lively areas, a dreamy
  slightly detuned pan lullaby for the overworld; parang flavor for a festive area.
- Placeholder art in early milestones; real art replaces it later.

## Technical plan (Godot 4.7)

- Rooms from ASCII maps in `data/rooms/`: a ground shader blends materials, an invisible
  `TileMapLayer` gives solid tiles collision, scenery is y-sorted sprites (done).
- Player and enemies as `CharacterBody2D` with simple state machines.
- Dialogue: data-driven (JSON or Godot resources) with a typewriter text box; text kept in
  data files so a local reviewer can edit the dialect without touching code.
- Virtual controls and save system are built (milestone 1).
- Tests: extend the headless tests per system. Watch memory: few atlases, stream music.

## Milestones (each ends in a playable build and a passing `make test`)

1. **Foundation (done):** tile rooms, scrolling room-to-room camera, collisions, virtual
   controls, input map, save and load. Known gap: controls overlap the playfield edges on
   20:9 phones; revisit in the polish milestone.
2. **Combat (done):** cutlass attack, health as doubles, knockback, two enemy types (pothound,
   corbeau), pickups, fainting and respawn. Tuning (damage, speeds, drop rates) is a first guess.
3. **World and dialogue (first pass done):** San Fernando Wharf (start), the road up, and
   Cross Crossing with four food stalls and their vendors; a dialogue box with typewriter text;
   NPCs, signs and readable props from data files; story flags; the ibis's welcome. Still to
   do: real local detail (needs your input), Harris Promenade, proper buildings instead of rock
   walls, and reviewed dialogue.
4. **Temple 1:** keys, locked doors, a push-block puzzle, a mini-boss, a new item.
5. **Boss and slice ending:** Temple 1 boss, first seasoning, hint of the rival.
6. **Polish:** sound effects, music, hit effects, menus, settings, low-end phone testing.

After the slice: Temples 2-4, the trading quest, minigames, the finale and the twist ending.

## Open questions

1. **Local knowledge:** the landmarks, foods, slang and jokes you most want in the game,
   especially what you would find at Cross Crossing (which stalls, which foods, what the
   atmosphere is like) and what the wharf looks like.
2. **Dialect level:** light flavor, or heavy Trini English in dialogue (you would review it)?
3. ~~Chad's look~~ Decided: based on the owner (short dark hair, thick brows, five o'clock shadow,
   deadpan stare, grey tee, thin chain). Still open: does Chad speak (Link's Awakening's hero is silent)?
4. ~~Final title~~ Decided: *Chad and the Legendary Lamb Gyro*.
5. Art source: your own, a free pack you upload, or placeholders for now.
6. Music: do you have any, or should we plan simple original tracks?

## Legal

This is a parody that borrows structure, not content. Do not use the names Zelda, Link,
Hyrule, Koholint, or Nintendo's sprites, music, or logos in the game or its store listing.
Use invented names for shops and characters, never real brands or real people. Real public
places are fine as loose inspiration. Keep the title and characters distinct enough that
nobody mistakes it for an official game.
