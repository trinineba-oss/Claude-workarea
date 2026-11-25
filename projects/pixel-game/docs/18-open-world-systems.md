# 18. Open-world systems (pixel-2d branch)

The goal for the `pixel-2d` branch: a pixel-art top-down game that plays like a modern
open-air adventure. Systems interact by rules instead of scripted special cases: fire spreads,
water douses, metal conducts, wind carries, things fall and float. The owner's technical
blueprint is in [18a-systems-blueprint.md](18a-systems-blueprint.md); this file adapts it to
this game (Godot 4, GDScript, the room grid, Trinidad) and tracks progress.

**Legal reminder:** the *mechanics* are fair game; names are not. Abilities, items and places
get our own Trini-flavoured names (see the table below), never Nintendo's.

## Decided

- **Pure pixel 2D.** The 2.5D view is gone on this branch. Characters are animated pixel sheets
  (`PixelSprite`), drawn on a 2x pixel grid (64 px tiles = 32 art pixels); the ground shader
  and `tools/pixelate.py` put the rest of the art on the same grid with one palette.
- **Evey is peaceful.** She never fights; she grumbles sarcastic remarks instead
  (`data/evey_quips.json`), in plain English, never Trinidad dialect. Top dogs are won over,
  not beaten.
- **Rooms are the chunks.** The blueprint's 32x32 chunks map onto our 20x11 rooms: only the
  rooms around Chad are loaded (`Game._loaded`), each with its own simulation, and changes
  are kept as deltas (the world map remembers a burnt-away bush; temple progress is saved).
- **GDScript, not C#.** The grids are small (220 tiles a room, ticking 10 times a second), so
  GDScript is plenty; move a hot loop to C++ (GDExtension) only if a profile says so.

- **Breakable world.** Bushes, crates and fences break under the right kind of hit (blades
  cut, blunt things smash; fences need blunt), shatter into pieces and may drop coins, snacks,
  a branch or a plank. Trees shake loose branches. Rock waits for explosions. Nothing on a
  room's outer edge breaks (it is the edge of the world). Rules live in `data/materials.json`.
- **Open-world combat.** Weapons from `data/weapons.json`, each with its own combo, reach and
  weight: cutlass, branch, old plank, cricket bat, fishing spear, and bare fists (a boxing
  combo: jab, jab, cross, hook, uppercut, on Chad's LPC thrust and halfslash animations,
  with a guard stance when trouble is near). Weapons wear out and break; Chad carries five
  (Q / WPN swaps) and can throw the one in hand (R / TOSS) for big damage, then pick it up.
  Holding attack charges a spin (fists: a haymaker). A last-moment dodge freezes enemies for a
  burst of quick hits ("Perfect dodge!").

## How the blueprint maps onto this game

| Blueprint | Here | Status |
| --- | --- | --- |
| Chemistry matrix (materials, temperature, wetness) | `RoomChemistry` + `data/materials.json`: per-tile material and state | **Phase 1 in** (fire, water, ash) |
| Fire spreading on flammable tiles | grass, bushes, crates, fences, trees; sand and stone are firebreaks | **In** |
| Water extinguishing fire | shores are wet and won't catch; `douse()` puts fires out | **In** (no rain or water-throwing yet) |
| Conductivity / electricity | `conductive` flag on water and metal (bollards) | Data only |
| Updrafts from heat | for the kite (gliding) | Planned |
| Ice melting to water | needs the snow-cone ability (below) | Planned |
| Pseudo-Z height (climbing, falling, gliding) | cliffs and ledges as height levels in the room maps | Planned (phase 2) |
| Stamina | a stamina wheel for sprinting, climbing, gliding, swimming | Planned (phase 2) |
| Magnesis | **Lodestone glove**: pick up and swing metal things | Planned (phase 3) |
| Stasis | **Limin' charm**: makes a thing "lime" (stand still) and store up hits, then fly off | Planned (phase 3) |
| Cryonis | **Snow-cone maker**: raises an ice block out of water | Planned (phase 3) |
| Remote bombs | **Bamboo bursts** (the Christmas bamboo cannon): blast and set fires | Planned (phase 3) |
| Paraglider | **Easter kite** (a mad bull kite): glide off ledges, ride fire updrafts | Planned (phase 2) |
| Cooking | the gyro's whole story: combine ingredients at a pot for meals with effects | Planned |
| Chunk streaming | rooms load around Chad already; add a "dormant" state for far rooms | Partly there |
| Delta saves | the world remembers changed tiles; save them in the save file | Planned |
| Enemy AI (patrol, alert, flee fire) | enemies run from burning tiles | Planned (phase 4) |
| Touch + gamepad input | Godot actions already abstract both; add a rune wheel | Partly there |

## Phase plan

1. **Chemistry grid** *(done: phase 1)*. Fire, water, ash, firebreaks, burning bushes open the
   way, fire hurts, the flambeau lights it. Next in this phase: rain (weather) douses fires
   and wets the ground; burning enemies flee; electricity along metal and water.
2. **Movement and height.** Stamina wheel; sprint; climbable cliff tiles; ledges with real
   drops (fall damage); the Easter kite to glide; heat updrafts lift the kite.
3. **Abilities.** Lodestone glove, limin' charm, snow-cone maker, bamboo bursts, each written
   as rules on the grid and physics bodies (Godot `RigidBody2D` with zero gravity for
   top-down), so they combine (burst a crate on fire; float a metal box across a snow-cone).
4. **World and AI.** Bigger open map built from rooms, delta saves, enemy states (patrol, alert,
   flee from fire, fetch a weapon), weather and temperature zones.
5. **Mobile polish.** Ability wheel on touch, haptics, keeping 60 fps on mid-range phones.

## Your input

1. Which phase 2 piece matters most to you first: climbing, the kite, or stamina and sprint?
2. Are the ability names right (lodestone glove, limin' charm, snow-cone maker, bamboo
   bursts, Easter kite)? Better Trini ideas welcome.
3. Cooking: should it be central (the gyro quest) or a side system?
4. How harsh should fire be? Right now it spreads fast and burns Chad if he stands in it.

## To do

- [x] Pixel 2D look on the branch (characters, ground, sprites)
- [x] Peaceful Evey with grumbles
- [x] Chemistry grid: fire, water, ash, firebreaks, burning away bushes
- [x] Breakable bushes, crates and fences; trees shake; drops
- [x] Weapons with durability, swapping, throwing; boxing; charged spin; perfect-dodge burst
- [ ] A shield (a pot cover?) with a parry
- [ ] Bows or slingshots (ranged)
- [ ] Rain and wet ground; enemies flee fire
- [ ] Stamina, sprint, climbing, ledges
- [ ] Easter kite and updrafts
- [ ] The four abilities
- [ ] Delta saves of changed tiles
- [ ] Real pixel art to replace the pixelated placeholders
