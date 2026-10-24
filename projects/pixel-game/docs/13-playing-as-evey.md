# 13. Playing as Evey (proposal, not decided)

## The idea

Let the player **take control of Evey**, Chad's beagle, as well as Chad. Today she is a
companion with a mind of her own (she follows, bites, fetches, digs, sits and duels top dogs)
and the player only gives her orders from the DOG menu.

Playing as her fits the game's heart: she is based on the owner's dog who passed away, and in
the dream she can do anything. It also gives the game a second way to see San Fernando: low to
the ground, nose first.

## How it could work

| Option | What it is | Effort |
| --- | --- | --- |
| **A. Swap any time** | A button switches between Chad and Evey. The one you're not playing follows (Evey) or waits where he is (Chad) | Medium |
| **B. Evey chapters** | Set moments where you play only Evey: Chad is asleep, stuck, or somewhere dogs can't go | Medium (per chapter) |
| **C. Evey-only places** | Small areas only she can reach: under fences, through drains, into the strays' hideout | Small to medium |
| **D. A and C together** | Swap freely; some puzzles need her | Larger |

**Suggestion:** start with **B as one short chapter** (it works with option C's places too),
because it needs no new swap rules and makes her moment special. Swapping any time (A) can come
later if it's fun. One natural first chapter: at the
[Orange Castle](12-side-quest-orange-castle.md), "No dogs allowed!", so Chad goes in and you
play Evey outside, or Evey sneaks in.

## What Evey could do (her moves)

- **Sniff:** shows scent trails to buried things, lost items, or a person to follow. Turns the
  ground into a trail of glowing marks for a few seconds.
- **Dig:** digs up dig spots (already in the game) and digs under fences into new areas.
- **Squeeze:** fits through gaps, drains and under trucks where Chad can't.
- **Bite:** her attack (already in the game). Fast, short range.
- **Bark:** scares corbeaux off, startles bandits into dropping their loot, wakes sleeping
  people (and the ibis).
- **Run:** faster than Chad, can't swim far or climb.
- **Fetch / carry:** picks up one small thing at a time in her mouth (a key, a slipper, a
  coin) and drops it where it's needed, e.g. on the other side of a fence for Chad.
- **Talk to animals:** only as Evey can you "talk" with the strays, the ibis, the corbeaux.
  People just hear barking ("Wuh dat dog want?"). A whole layer of the town's gossip that only
  dogs know.
- **Duels** with top dogs stay as they are (turn-based).

What she can't do: use Chad's items (cutlass, boomerang, fishing rod), open doors, talk to
people, carry more than one thing.

## Things to decide carefully

- **Can she get hurt?** Today she never does. If she's playable she needs health. A gentle
  choice: when her health runs out she **gets tired and lies down**, and the chapter restarts
  or Chad comes to get her. Never a sad "death".
- **Tone.** Her chapters should feel playful and warm. The ending (she stays in the dream) is
  bittersweet already; playing as her should make that feel loving, not heavier.
- **Controls on a phone.** A: bite. B: bark. X: sniff / dig / pick up. DOG button becomes the
  swap button (option A).

## What it needs (tech)

- A **player-controlled Evey** that uses the same input as Chad, while Chad gets simple
  follow/wait behaviour. The 2.5D view already draws her; the camera follows whoever you play.
- **Evey's health and fainting**, her HUD, and saving which character you're playing.
- **Scent trails** (a small effect), **dog-sized gaps** in the room maps (a new map letter), and
  **animal dialogue** in `data/dialogue.json`.
- **Art:** extra Evey poses: sniffing (nose down), digging, barking, running, carrying
  something, lying down tired. Her painted sheet already has walk, sit and bark/bow.
- Tests for swapping, her moves, health and saving.

## Your input

1. **Which option:** A, B, C or D? Or "B first".
2. **Where should her first chapter be?** The Orange Castle, the strays' hideout, finding Chad
   after he gets lost, something from the real Evey's life?
3. **What did the real Evey love doing?** Habits, favourite spots, things she always sniffed
   out or chased. These could become her moves and jokes.
4. **Does she get her own story moment** before the dream ends? (Gentle, your call.)
5. **Hurt and tired:** is the "lies down tired" rule right?
6. **Animal voices:** should the strays and the ibis talk differently to Evey than to Chad?

## To do

- [ ] Choose the option
- [ ] Pick her first chapter and write its beats
- [ ] Prototype player-controlled Evey and the camera switch
- [ ] Sniff, bark and squeeze moves
- [ ] Extra Evey poses (sniff, dig, bark, run, carry, tired)
- [ ] Animal dialogue
