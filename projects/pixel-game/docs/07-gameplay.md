# 7. Gameplay

## The demo (wharf)

The game is now an **action RPG**, and the first playable slice is the **wharf demo**: after the
opening, five waves of crabs, pothounds and corbeaux come at Chad on the wharf, ending with the
pack leader (a big pothound). Clearing it ends the demo ("demo_done"); if Chad faints, the wave
starts again. `scripts/wharf_demo.gd` holds the waves.

**Combat** (`scripts/player.gd`, `cutlass.gd`, `juice.gd`):

- **Combo:** three cutlass hits; the third is a wide, heavy finisher. Each swing lunges Chad
  forward, in eight directions.
- **Roll:** a quick dodge that can't be hurt for most of its length, and cancels a swing.
- **Buffered input:** a press slightly early still counts, so combos and dodges never drop.
- **Feel:** hit-stop and screen shake on every hit, damage numbers, harder knockback on finishers.
- **Readable enemies:** pothounds crouch and flash before they lunge, then have to recover.
- **RPG layer:** enemies give XP; levels (shown top left) heal Chad and add cutlass damage.

Keys: arrows/WASD move, **Z** attack, **Space** roll, X item, C talk, V Evey's orders. On a
phone: joystick, **A** attack, **ROLL**, B item, X talk, DOG.

## Built

- **Combat.** Cutlass swing, health as **doubles** (hearts), knockback, fainting and respawn.
- **Enemies.** Pothounds, corbeaux, crabs, night bandits, soucouyant fireballs, callaloo blobs.
- **Items and foraging.** A 12-slot bag with an 8-slot hotbar; eat food to heal. Mango trees,
  coconut palms, chadon beni and pepper bushes grow back after a few game days.
- **Fishing.** The fisherman's rod; cast at water; a hold-to-lift catch minigame. Snapper,
  carite, kingfish, cavalli, flying fish and the odd slipper, by time of day.
- **Day and night.** A 12-minute day. At night bandits snatch money or your best catch (hit
  them once to get it back); they won't step into lamplight.
- **Digging.** Evey digs up buried money and items at dig spots.
- **Evey's orders.** Sic 'em, Stay/Come, Fetch, Dig. Stay also holds down pressure plates.
- **Dog duels.** Turn-based fights against top dogs (bite, growl, treats). Evey levels up.
- **Temple tools.** Keys, locked doors, gates, push blocks, plates, crystal switches, the
  coconut boomerang.
- **Saving.** Automatic on room change, pause and when the app goes to the background.

## Planned

| Idea | Notes |
| --- | --- |
| Tawa shield | The roti griddle |
| Charged cutlass spin | Hold attack |
| More temple items | Wiri-wiri pepper bombs, flambeau lantern, bamboo grapple |
| Cooking | Recipes from foraged and caught food |
| Friendships | Daily chats and gifts; friends give recipes and secrets |
| Vendor schedules | Fishing or liming by day, at their trucks after dark |
| Trading quest | Ice → sno-cone → lost slipper → ... ending in a useful reward |
| Maxi taxis | Fast travel between hubs |
| Selling | Fish and forage can't be sold yet |
| Chad's own food truck | On hold, by request |
| Side-view platforming | For the [Orange Castle](12-side-quest-orange-castle.md) side quest (proposal) |
| Playing as Evey | Swap to Evey or play Evey chapters: sniff, dig, squeeze, bark, talk to animals ([proposal](13-playing-as-evey.md)) |

## Your input

1. Which planned features matter most to you?
2. How hard should combat be? Should fainting cost anything?
3. Should fish and fruit sell for money? What is money for?
4. Ideas for new temple items or minigames?

## To do

- [ ] Rank the planned features
- [ ] Tune difficulty (damage, speeds, drop rates are first guesses)
- [ ] Design temple 2's item
