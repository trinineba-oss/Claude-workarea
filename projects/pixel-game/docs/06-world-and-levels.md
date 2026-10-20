# 6. World and levels

Real places are loose inspiration; layouts are invented and squeezed into screen-sized rooms.
Cross Crossing and Lady Hailes Avenue are based on the owner's Street View footage (reference
only, never stored in the repo). Food trucks use generic names, never real businesses'.

## How rooms work

The world is a grid of rooms, each **20×11 tiles** (one tile = 64 px). Each room is a text file
in `data/rooms/<x>_<y>.txt`: a 20×11 map of letters, then one line per object
(`npc 11 4 rival`, `prop 3 4 truck_gyros`, `forage 8 2 coconut_palm`...). The legend is in the
main README under *Building the world*. Temples work the same way in
`data/dungeons/<map>/`. You can edit these files in any text editor.

## Built rooms

```
          x=0          x=1               x=2                  x=3
y=0   Road up       Cross Crossing    Lady Hailes Avenue   Lady Hailes east
      (poles,        (gas station,     (gyro, doubles,      (pork, seafood
       Brownie)       yellow bldg,      corn soup trucks)    trucks)
                      traffic)
y=1   Wharf (start)  Beach + Callaloo  East beach
                     Cave mouth
```

**Callaloo Cave (Temple 1):** 8 rooms: keys, locked doors, a push-block puzzle, a crystal switch
across water, the Big Blue Crab, the coconut boomerang, the Pepper Key and the Callaloo
Cauldron.

## Planned areas

| Area | Role | Ideas |
| --- | --- | --- |
| Harris Promenade | Hub | Shops, benches, save point, maxi taxi stop |
| High Street and market | Overworld | More vendors, the rum-shop riddle men |
| Skinner Park | Minigame | Cricket or football |
| Temples 2–4 | Dungeons | Quarry caves, market at night, refinery tower, old wharf |
| San Fernando Hill | Finale | Opens after four seasonings |

## Your input

1. What does the **wharf** really look like? What's at **Cross Crossing**?
2. Which real spots matter most to you to include (loosely)?
3. Order of areas: what should the player reach after the beach?
4. For each new temple: setting, the item found there, the boss, one signature puzzle.

## To do

- [ ] Harris Promenade (hub)
- [ ] High Street and market
- [ ] Temple 2 layout
- [ ] Replace rock walls with proper buildings in town
- [ ] Maxi taxi fast travel
- [ ] San Fernando Hill finale
