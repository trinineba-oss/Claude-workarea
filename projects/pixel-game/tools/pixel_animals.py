"""Pixel-art animals in the LPC style (64x64 frames, 4 directions), drawn from code.

Usage (from projects/pixel-game):
    uv run --with pillow --with numpy python -I tools/pixel_animals.py

Writes assets/characters/<name>.png and adds their layouts to assets/characters/sheets.json.
Dogs (Evey, Brownie, the strays and the top dogs) get walk, idle, sit and bite animations in
four directions (up, left, down, right); the corbeau and the soucouyant fly, the crab
scuttles and the ibis bobs. Shapes are drawn without anti-aliasing, then every colour region
is shaded (a light top edge, a dark bottom edge) and the whole figure gets a dark outline.
Evey is the owner's beagle: cream face and legs, a grey-brown saddle, tan floppy ears, white
paws and chest, and a dark tip on her tail.
"""

import json
import math
import os

import numpy as np
from PIL import Image, ImageDraw

OUT = "assets/characters"
F = 64
GROUND = 60
DIRS = ["up", "left", "down", "right"]


class Frame:
    """One 64x64 frame built from flat colour shapes, shaded and outlined on save."""

    def __init__(self):
        self.img = Image.new("RGBA", (F, F), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    def ellipse(self, cx, cy, rx, ry, colour):
        self.d.ellipse([round(cx - rx), round(cy - ry), round(cx + rx), round(cy + ry)], fill=colour)

    def rect(self, x0, y0, x1, y1, colour):
        self.d.rectangle([round(x0), round(y0), round(x1), round(y1)], fill=colour)

    def poly(self, pts, colour):
        self.d.polygon([(round(x), round(y)) for x, y in pts], fill=colour)

    def line(self, pts, colour, width=1):
        self.d.line([(round(x), round(y)) for x, y in pts], fill=colour, width=width)

    def dot(self, x, y, colour):
        self.d.point((round(x), round(y)), fill=colour)

    def finish(self, flip=False):
        a = np.asarray(self.img).astype(np.int16)
        rgb, alpha = a[..., :3], a[..., 3] > 0
        out = rgb.copy()
        same = lambda dy, dx: np.all(np.roll(rgb, (dy, dx), (0, 1)) == rgb, axis=-1) & np.roll(alpha, (dy, dx), (0, 1))
        top_edge = alpha & ~same(1, 0)  # the pixel above is a different colour
        bottom_edge = alpha & ~same(-1, 0)
        out[top_edge] = np.clip(rgb[top_edge] * 1.18 + 12, 0, 255)
        out[bottom_edge & ~top_edge] = np.clip(rgb[bottom_edge & ~top_edge] * 0.72, 0, 255)
        grown = alpha.copy()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            grown |= np.roll(alpha, (dy, dx), (0, 1))
        outline = grown & ~alpha
        result = np.zeros((F, F, 4), np.uint8)
        result[..., :3] = out.astype(np.uint8)
        result[..., 3] = np.where(alpha, 255, 0)
        result[outline] = (34, 24, 30, 255)
        img = Image.fromarray(result, "RGBA")
        return img.transpose(Image.FLIP_LEFT_RIGHT) if flip else img


def shade(c, f):
    return tuple(int(max(0, min(255, v * f))) for v in c[:3]) + (255,)


# --- dogs ------------------------------------------------------------------------------------
class Dog:
    def __init__(self, coat, belly, ears, nose=(30, 22, 24, 255), saddle=None, tail_tip=None,
                 paws=None, muzzle=None, ear_style="floppy", size=1.0, fluffy=False, bow=None,
                 collar=None, patches=None, mask=None):
        self.coat, self.belly, self.ears, self.nose = coat, belly, ears, nose
        self.saddle, self.tail_tip, self.paws, self.muzzle = saddle, tail_tip, paws, muzzle
        self.ear_style, self.k, self.fluffy, self.bow = ear_style, size, fluffy, bow
        self.collar, self.patches, self.mask = collar, patches, mask


def dog_side(dog, f: Frame, phase, pose="walk"):
    """A dog facing right. phase in [0, 1) drives the legs; pose: walk, idle, sit, bite."""
    k = dog.k
    cx, by = 30, GROUND - 13 * k  # body centre
    sit = pose == "sit"
    bob = 0 if pose in ("sit", "idle") else round(math.sin(phase * 2 * math.pi * 2) * 0.6)
    by += bob
    # Tail (behind everything): up and wagging.
    wag = math.sin(phase * 2 * math.pi * (3 if pose == "idle" else 2)) * 2.5
    tail_base = (cx - 12 * k, by - 4 * k)
    tail_end = (cx - 15 * k + wag * 0.4, by - 13 * k + abs(wag) * 0.3)
    f.line([tail_base, ((tail_base[0] + tail_end[0]) / 2 - 2, (tail_base[1] + tail_end[1]) / 2), tail_end], dog.coat, width=max(2, round(3 * k)))
    if dog.tail_tip:
        f.ellipse(tail_end[0], tail_end[1], 1.5 * k, 1.5 * k, dog.tail_tip)
    # Legs: far pair first (darker), then body, then near pair.
    legs = []
    for i, (lx, lphase) in enumerate(((cx + 8 * k, 0.0), (cx + 10 * k, 0.5), (cx - 9 * k, 0.5), (cx - 7 * k, 0.0))):
        swing = 0 if pose in ("idle", "sit", "bite") else math.sin((phase + lphase) * 2 * math.pi) * 2.6 * k
        lift = 0 if pose in ("idle", "sit", "bite") else max(0, math.cos((phase + lphase) * 2 * math.pi)) * 1.5
        far = i in (1, 2)
        legs.append((lx, swing, lift, far))
    def leg(lx, swing, lift, far, hind=False):
        colour = shade(dog.coat, 0.82) if far else dog.coat
        top = by + 3 * k
        if sit and hind:
            f.ellipse(lx + 1, GROUND - 4 * k, 4 * k, 3 * k, colour)
            return
        f.rect(lx - 1.2 * k + swing * 0.5, top, lx + 1.2 * k + swing * 0.5, GROUND - 1 - lift, colour)
        paw = dog.paws or colour
        f.rect(lx - 1.4 * k + swing, GROUND - 2 * k - lift, lx + 1.8 * k + swing, GROUND - lift, paw)
    for lx, swing, lift, far in legs:
        if far:
            leg(lx, swing, lift, True, hind=lx < cx)
    # Body (tilted back when sitting).
    if sit:
        f.ellipse(cx - 2, by + 1, 11 * k, 8 * k, dog.coat)
        f.ellipse(cx + 6 * k, by - 4 * k, 7 * k, 7 * k, dog.coat)
    else:
        f.ellipse(cx, by, 13 * k, 6.5 * k, dog.coat)
    if dog.fluffy:
        for dx in (-8, -2, 4):
            f.ellipse(cx + dx * k, by - 3 * k, 5 * k, 4 * k, shade(dog.coat, 1.06))
    if dog.belly:
        f.ellipse(cx + 2 * k, by + 4 * k, 9 * k, 2.5 * k, dog.belly)
    if dog.saddle:
        f.ellipse(cx - 2 * k, by - 3.5 * k, 9.5 * k, 3.5 * k, dog.saddle)
    if dog.patches:
        f.ellipse(cx - 5 * k, by - 1 * k, 3.5 * k, 2.5 * k, dog.patches)
    for lx, swing, lift, far in legs:
        if not far:
            leg(lx, swing, lift, False, hind=lx < cx)
    # Head and neck.
    hx, hy = cx + 14 * k, by - 7 * k
    if pose == "bite":
        hx += 3
        hy += 1
    if sit:
        hx, hy = cx + 10 * k, by - 12 * k
    f.ellipse(hx - 3 * k, hy + 4 * k, 4 * k, 5 * k, dog.coat)  # neck
    if dog.collar:
        f.rect(hx - 6 * k, hy + 4 * k, hx - 1 * k, hy + 5.5 * k, dog.collar)
    f.ellipse(hx, hy, 5.5 * k, 5 * k, dog.coat)
    snout = dog.muzzle or dog.coat
    open_jaw = pose == "bite" and phase > 0.3
    f.rect(hx + 3 * k, hy - 0.5 * k, hx + 8.5 * k, hy + 3 * k, snout)
    if open_jaw:
        f.rect(hx + 3 * k, hy + 3.5 * k, hx + 8 * k, hy + 5 * k, snout)
    f.dot(hx + 8.5 * k, hy, dog.nose)
    f.dot(hx + 8.5 * k, hy + 1, dog.nose)
    if dog.mask:
        f.ellipse(hx + 1, hy - 1, 3 * k, 2.5 * k, dog.mask)
    f.dot(hx + 2 * k, hy - 1.5 * k, (20, 16, 18, 255))  # eye
    # Ears.
    if dog.ear_style == "floppy":
        f.poly([(hx - 2 * k, hy - 4 * k), (hx + 1.5 * k, hy - 4.5 * k), (hx + 0.5 * k, hy + 5 * k), (hx - 3 * k, hy + 4 * k)], dog.ears)
    else:
        f.poly([(hx - 3 * k, hy - 3 * k), (hx - 1.5 * k, hy - 10 * k), (hx + 1 * k, hy - 3.5 * k)], dog.ears)
    if dog.bow:
        f.ellipse(hx - 2 * k, hy - 6 * k, 2 * k, 1.5 * k, dog.bow)
        f.ellipse(hx + 1.5 * k, hy - 6 * k, 2 * k, 1.5 * k, dog.bow)


def dog_front(dog, f: Frame, phase, pose="walk", back=False):
    """A dog seen from the front (down) or from behind (up)."""
    k = dog.k
    cx = 32
    step = 0 if pose in ("idle", "sit", "bite") else math.sin(phase * 2 * math.pi)
    by = GROUND - 12 * k - (0 if pose != "sit" else -2)
    # Legs.
    for side, ph in ((-1, 0), (1, math.pi)):
        lift = max(0, math.sin(phase * 2 * math.pi + ph)) * 1.5 if pose == "walk" else 0
        lx = cx + side * 4 * k
        f.rect(lx - 1.4 * k, by + 4 * k, lx + 1.4 * k, GROUND - lift, dog.coat)
        f.rect(lx - 1.6 * k, GROUND - 2 * k - lift, lx + 1.6 * k, GROUND - lift, dog.paws or dog.coat)
    # Body.
    f.ellipse(cx, by + 2 * k, 7.5 * k, 7 * k, dog.coat)
    if back:
        if dog.saddle:
            f.ellipse(cx, by, 6 * k, 5 * k, dog.saddle)
        wag = math.sin(phase * 2 * math.pi * 3) * 2
        f.line([(cx, by - 2 * k), (cx + wag, by - 10 * k)], dog.coat, width=max(2, round(2.5 * k)))
        if dog.tail_tip:
            f.ellipse(cx + wag, by - 10 * k, 1.5 * k, 1.5 * k, dog.tail_tip)
    elif dog.belly:
        f.ellipse(cx, by + 3 * k, 4 * k, 4.5 * k, dog.belly)
    if dog.collar and not back:
        f.rect(cx - 4 * k, by - 3 * k, cx + 4 * k, by - 2 * k, dog.collar)
    # Head.
    hy = by - 7 * k + (0.5 * step if pose == "walk" else 0)
    f.ellipse(cx, hy, 6 * k, 5.5 * k, dog.coat)
    if dog.ear_style == "floppy":
        for side in (-1, 1):
            f.poly([(cx + side * 4 * k, hy - 4 * k), (cx + side * 7.5 * k, hy - 2 * k), (cx + side * 7 * k, hy + 5 * k), (cx + side * 4.5 * k, hy + 4 * k)], dog.ears)
    else:
        for side in (-1, 1):
            f.poly([(cx + side * 2.5 * k, hy - 4 * k), (cx + side * 6 * k, hy - 11 * k), (cx + side * 6 * k, hy - 3 * k)], dog.ears)
    if dog.bow:
        f.ellipse(cx - 3 * k, hy - 6 * k, 2 * k, 1.5 * k, dog.bow)
        f.ellipse(cx + 3 * k, hy - 6 * k, 2 * k, 1.5 * k, dog.bow)
    if not back:
        f.ellipse(cx, hy + 2.5 * k, 3 * k, 2.5 * k, dog.muzzle or dog.coat)
        f.dot(cx, hy + 1.5 * k, dog.nose)
        f.dot(cx - 1, hy + 1.5 * k, dog.nose)
        for side in (-1, 1):
            f.dot(cx + side * 2.5 * k, hy - 1.5 * k, (20, 16, 18, 255))
        if dog.mask:
            f.ellipse(cx - 2.5 * k, hy - 1.5 * k, 1.5 * k, 1.5 * k, dog.mask)
        if pose == "bite" and phase > 0.3:
            f.rect(cx - 2 * k, hy + 4 * k, cx + 2 * k, hy + 5 * k, (150, 50, 60, 255))


DOG_ANIMS = {"walk": 6, "idle": 2, "sit": 1, "bite": 3}


def dog_sheet(dog):
    rows = []
    for anim, frames in DOG_ANIMS.items():
        for direction in DIRS:
            row = []
            for i in range(frames):
                phase = i / frames
                f = Frame()
                if direction in ("left", "right"):
                    dog_side(dog, f, phase, anim)
                    row.append(f.finish(flip=direction == "left"))
                else:
                    dog_front(dog, f, phase, anim, back=direction == "up")
                    row.append(f.finish())
            rows.append(row)
    return rows, {a: n for a, n in DOG_ANIMS.items()}


# --- birds, fire and crabs -------------------------------------------------------------------
def corbeau_frame(f: Frame, phase):
    body = (46, 42, 54, 255)
    wing = (60, 56, 70, 255)
    head = (214, 120, 120, 255)
    flap = math.sin(phase * 2 * math.pi)
    cy = 30
    f.ellipse(32, cy + 2, 7, 6, body)
    for side in (-1, 1):
        tip_y = cy - 8 * flap
        f.poly([(32 + side * 4, cy), (32 + side * 22, tip_y), (32 + side * 18, tip_y + 6), (32 + side * 6, cy + 5)], wing)
    f.ellipse(32, cy - 6, 3.5, 3.5, head)
    f.poly([(30, cy - 5), (34, cy - 5), (32, cy - 1)], (236, 196, 80, 255))
    f.dot(31, cy - 7, (20, 16, 18, 255))
    f.dot(33, cy - 7, (20, 16, 18, 255))


def soucouyant_frame(f: Frame, phase):
    flick = math.sin(phase * 2 * math.pi)
    f.poly([(32, 14 - 3 * flick), (40, 26), (44, 20 + 2 * flick), (44, 34), (32, 44), (20, 34), (20, 20 - 2 * flick), (24, 26)], (226, 70, 34, 255))
    f.ellipse(32, 34, 10, 10, (246, 130, 40, 255))
    f.ellipse(32, 36, 6, 6, (252, 196, 70, 255))
    f.dot(29, 33, (40, 20, 20, 255))
    f.dot(35, 33, (40, 20, 20, 255))
    f.line([(27, 30), (30, 31)], (60, 24, 20, 255))
    f.line([(37, 30), (34, 31)], (60, 24, 20, 255))


def crab_frame(f: Frame, phase):
    shell = (70, 120, 200, 255)
    dark = (46, 84, 150, 255)
    step = math.sin(phase * 2 * math.pi)
    for side in (-1, 1):
        for i in range(3):
            x = 32 + side * (7 + i * 3)
            f.line([(32 + side * 5, 50), (x, 54 + (step if (i + (side > 0)) % 2 else -step))], dark)
        f.ellipse(32 + side * 14, 44 - abs(step), 3.5, 3, shell)
    f.ellipse(32, 50, 9, 5, shell)
    f.ellipse(32, 48, 6, 2, (120, 170, 236, 255))
    for side in (-1, 1):
        f.line([(32 + side * 3, 46), (32 + side * 3, 42)], dark)
        f.dot(32 + side * 3, 41, (20, 16, 18, 255))


def ibis_frame(f: Frame, phase, facing_right=True):
    red = (226, 52, 44, 255)
    dark = (176, 30, 34, 255)
    bob = round(math.sin(phase * 2 * math.pi))
    f.line([(30, 50), (30, 60)], (60, 40, 40, 255))
    f.line([(34, 50), (34, 60)], (60, 40, 40, 255))
    f.ellipse(32, 44, 9, 6, red)
    f.poly([(24, 43), (16, 47), (24, 48)], dark)
    f.rect(36, 30 + bob, 39, 44, red)
    f.ellipse(39, 29 + bob, 4, 3.5, red)
    f.line([(42, 29 + bob), (47, 32 + bob), (49, 36 + bob)], (60, 40, 40, 255), width=2)
    f.dot(40, 28 + bob, (20, 16, 18, 255))


def simple_sheet(draw, frames, directional=True):
    rows = []
    for direction in DIRS if directional else ["down"]:
        row = []
        for i in range(frames):
            f = Frame()
            draw(f, i / frames)
            row.append(f.finish(flip=direction == "left"))
        rows.append(row)
    return rows


def save(name, rows, layout_anims):
    width = max(len(r) for r in rows) * F
    sheet = Image.new("RGBA", (width, len(rows) * F), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, frame in enumerate(row):
            sheet.alpha_composite(frame, (x * F, y * F))
    os.makedirs(OUT, exist_ok=True)
    sheet.save(f"{OUT}/{name}.png")
    return layout_anims


def main():
    cream = (226, 196, 150, 255)
    tan = (176, 116, 68, 255)
    white = (246, 240, 228, 255)
    dogs = {
        "evey": Dog(cream, white, tan, saddle=(118, 106, 98, 255), tail_tip=(48, 40, 38, 255), paws=white, muzzle=white, collar=(200, 60, 70, 255)),
        "brownie": Dog((128, 84, 50, 255), (176, 128, 86, 255), (88, 56, 34, 255), collar=(220, 50, 50, 255), ear_style="pointy"),
        "stray": Dog((178, 120, 70, 255), (218, 172, 120, 255), (120, 76, 44, 255), ear_style="pointy"),
        "scraps": Dog((150, 150, 158, 255), (196, 196, 204, 255), (110, 110, 118, 255), patches=(96, 96, 104, 255), ear_style="pointy"),
        "duchess": Dog((238, 236, 240, 255), (255, 255, 255, 255), (220, 214, 224, 255), fluffy=True, bow=(240, 110, 170, 255)),
        "tiger": Dog((40, 36, 40, 255), (196, 128, 60, 255), (30, 26, 30, 255), mask=(196, 128, 60, 255), collar=(150, 150, 160, 255), ear_style="pointy", size=1.25),
    }
    sheets_path = f"{OUT}/sheets.json"
    sheets = json.load(open(sheets_path)) if os.path.exists(sheets_path) else {"frame": F, "anims": {}, "characters": {}}
    for name, dog in dogs.items():
        rows, counts = dog_sheet(dog)
        layout, r = {}, 0
        for anim, frames in counts.items():
            layout[anim] = {"row": r, "frames": frames, "rows": 4}
            r += 4
        sheets["characters"][name] = save(name, rows, layout)
    for name, draw, frames in (("corbeau", corbeau_frame, 4), ("soucouyant", soucouyant_frame, 4), ("crab", crab_frame, 4)):
        rows = simple_sheet(draw, frames)
        sheets["characters"][name] = save(name, rows, {"walk": {"row": 0, "frames": frames, "rows": 4}, "idle": {"row": 0, "frames": frames, "rows": 4}})
    rows = simple_sheet(lambda f, p: ibis_frame(f, p), 2)
    sheets["characters"]["ibis"] = save("ibis", rows, {"idle": {"row": 0, "frames": 2, "rows": 4}, "walk": {"row": 0, "frames": 2, "rows": 4}})
    for anim, frames in DOG_ANIMS.items():
        sheets["anims"].setdefault(anim, {"frames": frames, "directional": True})
    with open(sheets_path, "w") as f:
        json.dump(sheets, f, indent=2)
        f.write("\n")
    print("animals:", ", ".join(dogs) + ", corbeau, soucouyant, crab, ibis")


if __name__ == "__main__":
    main()
