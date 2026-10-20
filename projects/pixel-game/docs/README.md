# Project docs: work on the game in parts

*Chad and the Legendary Lamb Gyro* is split into sections here, so each part of the game can be
worked on separately. Each file has the same shape:

- **Decided**: what is settled and already in the game.
- **Your input**: questions only you can answer. Write your answers straight into the file.
- **To do**: a checklist. Tick items (`- [x]`) as they get done.

| # | Section | What it covers |
| --- | --- | --- |
| 0 | [Local setup](00-local-setup.md) | Getting the project running on your own PC |
| 1 | [Storyline](01-storyline.md) | The plot, chapters, the dream twist, the ending |
| 2 | [Theme and tone](02-theme-and-tone.md) | What the game feels like, humour rules, dialect, respect |
| 3 | [Art style](03-art-style.md) | The look: 2.5D, painted vs pixel, palette, lighting |
| 4 | [Assets](04-assets.md) | Every piece of art still needed, with sizes and pose lists |
| 5 | [Characters](05-characters.md) | Chad, Evey, the townspeople, dogs, enemies, bosses |
| 6 | [World and levels](06-world-and-levels.md) | San Fernando's areas, the room grid, temples |
| 7 | [Gameplay](07-gameplay.md) | Combat, items, foraging, fishing, night, Evey's orders, duels |
| 8 | [Audio](08-audio.md) | Music and sound effects (none yet) |
| 9 | [UI and controls](09-ui-and-controls.md) | Touch controls, HUD, menus, title screen |
| 10 | [Tech](10-tech.md) | How the code is laid out, data files, tests, builds |
| 11 | [Roadmap](11-roadmap.md) | Milestones: done, next, later |
| 12 | [Side quest: the Orange Castle](12-side-quest-orange-castle.md) | Proposal: the orange-castle hospital as a side-view platformer or metroidvania stage |

`../DESIGN.md` keeps the short pitch, the tone pillars and the legal rules. When a decision in
one of these files changes, update the file. Claude reads these docs too.

## A good way to work

1. Pick one section, read it, and fill in **Your input**. A few lines is plenty.
2. Ask Claude (in Claude Code on your PC, or a cloud session) to work on it, for example:
   *"Read docs/05-characters.md and make the townspeople changes I wrote in"*.
3. Run the game, look, give feedback, repeat.
4. Commit when you're happy (see [Local setup](00-local-setup.md#saving-your-work)).
