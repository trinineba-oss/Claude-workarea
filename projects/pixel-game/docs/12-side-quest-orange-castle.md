# 12. Side quest: the Orange Castle (proposal, not decided)

## The idea

The owner works near Cross Crossing as a phlebotomist, in a hospital that looks like an **orange
castle**. In Chad's dream it *is* a castle, and it becomes a side quest, possibly played as a
**side-view platformer** or a small **metroidvania**.

It fits the parody well: *Link's Awakening* itself drops into short **side-view platforming
passages** inside its dungeons. A side-view castle would be this game's version of that.

Ground rules (from [Theme and tone](02-theme-and-tone.md)):
- The building gets an **invented name** (e.g. "the Orange Castle"), not the real hospital's.
- The jokes are about **situations** (the take-a-number queue, paperwork, the lift that never
  comes, the vending machine, the waiting room where everybody has an opinion). Never patients'
  illness or suffering, never real colleagues.
- Only workplace details the owner is comfortable sharing.

## Format options

| Option | What it is | Effort | Notes |
| --- | --- | --- | --- |
| **A. Side-view stage** | One self-contained side-scrolling level: run, jump, climb, a boss at the top | Medium | Like *Link's Awakening*'s side-view passages. Needs a new side-view mode (below) |
| **B. Metroidvania wing** | Several connected floors; a new ability opens areas you saw earlier | Large | Builds on A. Worth it only if A is fun |
| **C. Top-down temple** | Built like Callaloo Cave, just themed as a castle | Small | Uses what exists; loses the platformer feel |

**Suggestion:** build **A as a small test first**: one floor, jumping, a few enemies, one
gimmick. Play it, then decide whether it grows into B or stays a one-off.

## What a side-view mode needs (A or B)

- **Movement:** gravity, jump (variable height), ladders or stairs, maybe wall-hang. Coyote time
  and jump buffering so it feels fair on a touchscreen.
- **Camera:** a side-on view instead of the 50° top-down tilt. The 3D view makes this easy: same
  lighting and art, the camera just turns.
- **Art:** characters need **side poses** (walk, jump, fall, climb). The painted sheets have a
  3/4 view and walk steps that could stretch to this.
- **Touch controls:** a jump button (A becomes jump; attack moves to B?).
- **Level format:** side-view rooms as text maps, like the overworld (`data/castle/...`).
- **Evey:** "No dogs allowed!" She waits at the entrance, or sneaks in as a gag, or the castle
  has a bit only she can reach. Your call.

## Story and gameplay ideas (pick, change or throw out)

- **Why go in:** Chad's shift. In the dream his own workplace is a castle and he's late. Or the
  lab has lost a box of sample tubes, scattered across the floors, and only Chad can find them.
- **Enemies:** mosquitoes (Aedes, dengue jokes) that swoop in sine waves; rolling IV stands;
  runaway wheelchairs; stacks of forms that topple.
- **Gimmicks:** lifts that arrive at random; ladder-like drip stands; laundry chutes as shortcuts;
  automatic doors; slippery mopped floors (with a wet-floor sign warning).
- **Boss:** **Queen Aedes**, a giant mosquito in the top tower.
- **Item reward:** the **tourniquet**, a stretchy grapple/swing (the planned "bamboo grapple"
  in a new form), useful back in the overworld. Or one of the four sacred seasonings, or a heart.
- **Gags:** take a number (yours is 247, they're serving 12); the castle guard who needs a form
  stamped by a guard who needs a form stamped; the snack machine that eats coins.
- **Cameo:** a phlebotomist character based on the owner, who gives the quest. Or Chad *is* the
  phlebotomist (Chad is already based on the owner).

## Your input

1. **Option A, B or C?** Or "A first, then see".
2. **Is Chad the phlebotomist** (his own job in the dream), or does he meet one?
3. **What's the castle called** in the game?
4. **Comfort check:** which details of the real place or job are okay to use, and anything to
   keep out?
5. **What's the reward?** Tourniquet grapple, a seasoning, a heart, something else?
6. **Where does the entrance sit** on the map? Near Cross Crossing makes sense.
7. **When:** before temples 2–4, or after?

## To do

- [ ] Decide the format (A, B or C)
- [ ] Answer the story questions above
- [ ] If A or B: prototype the side-view movement and camera on one test floor
- [ ] Side poses for Chad (jump, fall, climb)
- [ ] Castle exterior on the overworld map
- [ ] Level layouts, enemies, boss
