# 9. UI and controls

## Decided

- **Phone, landscape.** Left: virtual joystick. Right: **A** (attack), **B** (item), **X**
  (interact), **DOG** (Evey's orders), and a small pause button. Keyboard and gamepad also work.
- **HUD.** Health doubles, money (TT$) and the clock top-left; small keys in temples; an 8-slot
  hotbar along the bottom.
- **Dialogue.** A box with typewriter text; text lives in `data/dialogue.json`.
- **Dog duel screen.** Turn-based battle with Evey's moves.
- **Pause.** A pause overlay.

## Known issues

- On 20:9 phones the controls overlap about 30 px of the playfield.
- No title screen, settings, or credits screen yet.

## Your input

1. Do the buttons feel right? Anything you keep pressing by accident?
2. What should the title screen show?
3. Settings you want: volume, button size and position, left-handed layout, text speed?

## To do

- [ ] Title screen and main menu
- [ ] Settings (volume, button layout, text speed)
- [ ] Credits screen (needed for the LPC art credits)
- [ ] Restyle the HUD to match the art style
- [ ] Fix the control overlap on wide phones
- [ ] Test on a real low-end phone
