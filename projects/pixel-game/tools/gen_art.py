"""Regenerates the placeholder HD art.

Usage (from projects/pixel-game):
    uv run --with pillow --with numpy python -I tools/gen_art.py

Everything here is a stand-in: replace any PNG in assets/ with real art of the same
size and anchor (described next to each sprite below) and the game picks it up.
Shapes are drawn at 4x and downsampled, so edges are anti-aliased.
"""

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SS = 4  # supersampling factor
OUT = "assets"
INK = (38, 30, 48, 255)  # outline colour shared by all characters


# ---- helpers -----------------------------------------------------------------------------
class Canvas:
    """Draws outlined cartoon parts. Outlines of every part are drawn before any fill, so
    a character reads as one silhouette with a single outer line."""

    def __init__(self, w, h):
        self.w, self.h = w, h
        self.parts = []  # (kind, args, fill, outline)
        self.details = []

    def ellipse(self, cx, cy, rx, ry, fill, outline=3.0):
        self.parts.append(("ellipse", (cx, cy, rx, ry), fill, outline))

    def rrect(self, x0, y0, x1, y1, r, fill, outline=3.0):
        self.parts.append(("rrect", (x0, y0, x1, y1, r), fill, outline))

    def poly(self, points, fill, outline=3.0):
        self.parts.append(("poly", (points,), fill, outline))

    # Details are painted straight onto the image (no blending), so use opaque colours.
    def detail_ellipse(self, cx, cy, rx, ry, fill):
        self.details.append(("ellipse", (cx, cy, rx, ry), fill))

    def detail_line(self, points, fill, width):
        self.details.append(("line", (points, width), fill))

    def _draw(self, d, kind, args, fill, grow):
        s = SS
        if kind == "ellipse":
            cx, cy, rx, ry = args
            d.ellipse([(cx - rx - grow) * s, (cy - ry - grow) * s, (cx + rx + grow) * s, (cy + ry + grow) * s], fill=fill)
        elif kind == "rrect":
            x0, y0, x1, y1, r = args
            d.rounded_rectangle([(x0 - grow) * s, (y0 - grow) * s, (x1 + grow) * s, (y1 + grow) * s], radius=(r + grow) * s, fill=fill)
        elif kind == "poly":
            (points,) = args
            pts = [(x * s, y * s) for x, y in points]
            if grow > 0:
                d.line(pts + [pts[0]], fill=fill, width=int(grow * 2 * s), joint="curve")
                for x, y in pts:
                    d.ellipse([x - grow * s, y - grow * s, x + grow * s, y + grow * s], fill=fill)
            d.polygon(pts, fill=fill)

    def save(self, path):
        img = Image.new("RGBA", (self.w * SS, self.h * SS), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        for kind, args, _fill, outline in self.parts:
            if outline > 0:
                self._draw(d, kind, args, INK, outline)
        for kind, args, fill, _outline in self.parts:
            self._draw(d, kind, args, fill, 0)
        for kind, args, fill in self.details:
            if kind == "ellipse":
                self._draw(d, "ellipse", args, fill, 0)
            else:
                points, width = args
                d.line([(x * SS, y * SS) for x, y in points], fill=fill, width=int(width * SS), joint="curve")
        img = img.resize((self.w, self.h), Image.LANCZOS)
        img.save(path)


def seamless_noise(size, cells, seed):
    """Tileable value noise in 0..1."""
    rng = np.random.default_rng(seed)
    grid = rng.random((cells, cells))
    tiled = np.tile(grid, (3, 3))
    img = Image.fromarray((tiled * 255).astype(np.uint8)).resize((size * 3, size * 3), Image.BICUBIC)
    return np.asarray(img, dtype=np.float32)[size : size * 2, size : size * 2] / 255.0


def fractal(size, seed, octaves=((4, 0.5), (8, 0.25), (16, 0.15), (32, 0.1))):
    total = sum(w for _, w in octaves)
    acc = sum(seamless_noise(size, c, seed + i) * w for i, (c, w) in enumerate(octaves))
    return acc / total


def material(path, dark, light, seed, grain=0.0, contrast=1.6):
    n = fractal(256, seed)
    n = np.clip((n - 0.5) * contrast + 0.5, 0, 1)
    if grain:
        n = np.clip(n + (np.random.default_rng(seed + 99).random((256, 256)) - 0.5) * grain, 0, 1)
    dark, light = np.array(dark, np.float32), np.array(light, np.float32)
    rgb = dark[None, None, :] * (1 - n[..., None]) + light[None, None, :] * n[..., None]
    Image.fromarray(rgb.astype(np.uint8), "RGB").save(path)


def blurred_ellipse(path, w, h, alpha):
    img = Image.new("L", (w * 2, h * 2), 0)
    ImageDraw.Draw(img).ellipse([w * 0.5, h * 0.5, w * 1.5, h * 1.5], fill=int(255 * alpha))
    img = img.filter(ImageFilter.GaussianBlur(h * 0.25)).crop((w // 2 - 4, h // 2 - 4, w * 3 // 2 + 4, h * 3 // 2 + 4))
    rgba = Image.new("RGBA", img.size, (20, 12, 30, 0))
    rgba.putalpha(img)
    rgba.save(path)


# ---- ground materials (256x256, tileable) -------------------------------------------------
material(f"{OUT}/textures/grass.png", (56, 128, 62), (118, 184, 84), 1, grain=0.25)
material(f"{OUT}/textures/sand.png", (214, 188, 134), (240, 222, 172), 2, grain=0.3, contrast=1.2)
material(f"{OUT}/textures/dirt.png", (146, 100, 64), (192, 146, 98), 3, grain=0.25)
material(f"{OUT}/textures/water.png", (30, 96, 176), (70, 160, 222), 4, contrast=2.0)
noise = (fractal(256, 7) * 255).astype(np.uint8)
Image.fromarray(noise, "L").save(f"{OUT}/textures/noise.png")

stone = Image.open(f"{OUT}/textures/dirt.png").convert("RGB")
stone = Image.blend(stone, Image.new("RGB", stone.size, (200, 194, 182)), 0.75)
sd = ImageDraw.Draw(stone)
for i in range(0, 256, 64):
    sd.line([(i, 0), (i, 256)], fill=(150, 142, 130), width=3)
    sd.line([(0, i), (256, i)], fill=(150, 142, 130), width=3)
stone.save(f"{OUT}/textures/stone.png")

# ---- soft effects -------------------------------------------------------------------------
blurred_ellipse(f"{OUT}/sprites/shadow.png", 64, 22, 0.45)
spark = Image.new("L", (32, 32), 0)
ImageDraw.Draw(spark).ellipse([8, 8, 24, 24], fill=255)
spark = spark.filter(ImageFilter.GaussianBlur(3))
s_rgba = Image.new("RGBA", (32, 32), (255, 255, 255, 0))
s_rgba.putalpha(spark)
s_rgba.save(f"{OUT}/sprites/spark.png")

# ---- Chad, the hero: 64x84, anchor = feet at bottom centre ------------------------------------
# Based on the owner's look: very short dark hair, thick straight brows, a
# five o'clock shadow, a deadpan heavy-lidded stare, grey crew-neck tee and a thin chain.
c = Canvas(64, 84)
SKIN, SHIRT, COLLAR = (186, 126, 88, 255), (104, 108, 116, 255), (58, 62, 74, 255)
JEANS, HAIR = (44, 60, 96, 255), (32, 26, 26, 255)
c.rrect(21, 66, 30, 81, 4, JEANS)
c.rrect(34, 66, 43, 81, 4, JEANS)
c.ellipse(15, 56, 6, 6, SKIN)
c.ellipse(49, 56, 6, 6, SKIN)
c.rrect(17, 42, 47, 72, 10, SHIRT)
c.ellipse(12.5, 30, 3.5, 5, SKIN)
c.ellipse(51.5, 30, 3.5, 5, SKIN)
c.ellipse(32, 28, 19, 20, SKIN)
c.poly([(14, 24), (15, 14), (22, 7), (32, 5), (42, 7), (49, 14), (50, 24), (46, 17), (39, 14), (32, 15), (25, 14), (18, 17)], HAIR, outline=2.5)
STUBBLE = (158, 110, 84, 255)  # five o'clock shadow: a faint grey-brown tint, no beard
c.detail_ellipse(32, 41, 15, 8.5, STUBBLE)  # jaw and chin
c.detail_ellipse(32, 35.5, 14.5, 4.5, SKIN)  # cheeks stay clear
c.detail_ellipse(32, 39, 4.5, 1.4, STUBBLE)  # upper lip
c.detail_line([(29, 43), (35, 43)], (60, 36, 32, 255), 1.6)  # flat, unimpressed mouth
c.detail_line([(20, 25), (29, 25.5)], HAIR, 3.2)  # thick straight brows
c.detail_line([(35, 25.5), (44, 25)], HAIR, 3.2)
for x in (25, 39):
    c.detail_ellipse(x, 31, 3.2, 2.6, (250, 246, 240, 255))
    c.detail_ellipse(x, 31.6, 1.9, 1.9, INK)
    c.detail_ellipse(x, 29.6, 3.6, 1.6, SKIN)  # heavy upper lid: the deadpan stare
    c.detail_line([(x - 3.6, 30.2), (x + 3.6, 30.2)], (90, 58, 44, 255), 1.1)
c.detail_line([(32, 31), (33, 36), (31, 37)], (150, 98, 68, 255), 1.4)  # nose
c.detail_line([(23, 45), (27, 48.5), (32, 49.5), (37, 48.5), (41, 45)], COLLAR, 3.5)  # crew neck
c.detail_line([(26, 49), (32, 54), (38, 49)], (226, 212, 160, 255), 1.0)  # thin chain
c.save(f"{OUT}/sprites/hero.png")

# ---- pothound: 76x58, facing right, anchor = feet at bottom centre --------------------------------
c = Canvas(76, 58)
FUR, FUR_L = (178, 120, 70, 255), (218, 172, 120, 255)
c.poly([(10, 26), (2, 14), (6, 12), (16, 22)], FUR)  # tail
for x in (16, 26, 44, 54):
    c.rrect(x, 36, x + 7, 55, 3, FUR)
c.ellipse(36, 32, 24, 13, FUR)
c.ellipse(58, 20, 12, 11, FUR)
c.ellipse(68, 25, 7, 5.5, FUR_L)
c.poly([(52, 12), (50, 2), (58, 9)], (120, 76, 44, 255))  # ear
c.detail_ellipse(36, 38, 15, 5, FUR_L)
c.detail_ellipse(61, 17, 2.2, 2.6, INK)
c.detail_ellipse(74, 23, 2.4, 2.0, INK)
c.save(f"{OUT}/sprites/dog.png")

# ---- corbeau: 92x64, anchor = feet at bottom centre (it flies; the game lifts it) --------------
c = Canvas(92, 64)
FEATHER, FEATHER_L, HEAD = (56, 52, 70, 255), (92, 88, 108, 255), (220, 136, 136, 255)
c.poly([(46, 30), (4, 18), (2, 30), (16, 36), (30, 42)], FEATHER)
c.poly([(46, 30), (88, 18), (90, 30), (76, 36), (62, 42)], FEATHER)
c.ellipse(46, 38, 15, 17, FEATHER)
c.rrect(39, 54, 43, 62, 2, (236, 196, 80, 255), outline=1.5)
c.rrect(49, 54, 53, 62, 2, (236, 196, 80, 255), outline=1.5)
c.ellipse(46, 17, 9, 9, HEAD)
c.poly([(52, 16), (62, 20), (52, 22)], (236, 196, 80, 255), outline=2)
c.detail_line([(12, 26), (30, 32)], FEATHER_L, 2)
c.detail_line([(80, 26), (62, 32)], FEATHER_L, 2)
c.detail_ellipse(49, 15, 2, 2.2, INK)
c.detail_ellipse(46, 40, 8, 10, FEATHER_L)
c.save(f"{OUT}/sprites/corbeau.png")

# ---- pickups --------------------------------------------------------------------------------------
c = Canvas(48, 34)  # a "double": two bara around curried channa
BARA, CHANNA = (240, 198, 112, 255), (226, 118, 34, 255)
c.ellipse(24, 23, 21, 8, BARA)
c.ellipse(24, 17, 20, 5, CHANNA, outline=2)
c.ellipse(24, 11, 19, 7.5, BARA)
c.detail_ellipse(17, 9, 6, 2, (252, 228, 170, 255))
for x in (14, 21, 28, 34):
    c.detail_ellipse(x, 17, 2, 1.5, (250, 200, 80, 255))
c.save(f"{OUT}/sprites/snack.png")

c = Canvas(36, 36)
c.ellipse(18, 18, 15, 15, (248, 204, 58, 255))
c.detail_ellipse(18, 18, 10, 10, (230, 170, 30, 255))
c.detail_ellipse(18, 18, 8, 8, (252, 214, 80, 255))
c.detail_ellipse(13, 12, 3.5, 2.5, (255, 248, 200, 255))
c.save(f"{OUT}/sprites/coin.png")

# ---- scenery ---------------------------------------------------------------------------------------
c = Canvas(128, 156)  # tree, anchor = trunk base at (64, 150)
LEAF, LEAF_D, LEAF_L = (52, 132, 72, 255), (36, 100, 58, 255), (98, 176, 92, 255)
c.rrect(54, 96, 74, 150, 6, (116, 78, 46, 255))
for cx, cy, r in ((40, 74, 30), (88, 74, 30), (64, 52, 38), (38, 46, 26), (92, 46, 26), (64, 86, 30)):
    c.ellipse(cx, cy, r, r * 0.92, LEAF)
for cx, cy, r in ((52, 40, 16), (82, 36, 12), (34, 62, 10)):
    c.detail_ellipse(cx, cy, r, r * 0.8, LEAF_L)
for cx, cy, r in ((76, 92, 16), (44, 90, 12)):
    c.detail_ellipse(cx, cy, r, r * 0.6, LEAF_D)
c.detail_line([(64, 132), (64, 148)], (90, 58, 34, 255), 3)
c.save(f"{OUT}/sprites/tree.png")

c = Canvas(80, 62)  # bush, anchor = base at (40, 58)
for cx, cy, r in ((24, 38, 18), (56, 38, 18), (40, 28, 20)):
    c.ellipse(cx, cy, r, r * 0.9, LEAF)
c.detail_ellipse(34, 22, 9, 6, LEAF_L)
c.detail_ellipse(50, 46, 12, 5, LEAF_D)
for x, y in ((26, 36), (54, 30), (44, 44)):
    c.detail_ellipse(x, y, 2.5, 2.5, (230, 70, 90, 255))
c.save(f"{OUT}/sprites/bush.png")

c = Canvas(66, 86)  # rock wall block, anchor = bottom centre (33, 84)
c.rrect(3, 26, 63, 84, 8, (128, 122, 122, 255))
c.rrect(3, 4, 63, 44, 10, (176, 170, 164, 255))
c.detail_line([(18, 56), (26, 66), (24, 76)], (98, 92, 94, 255), 2)
c.detail_line([(46, 18), (52, 26)], (148, 142, 138, 255), 2)
c.detail_ellipse(20, 14, 9, 4, (200, 196, 190, 255))
c.save(f"{OUT}/sprites/rock.png")

c = Canvas(28, 24)  # flower decal, anchor = centre
for (cx, cy), col in (((8, 9), (240, 110, 150, 255)), ((19, 7), (255, 255, 255, 255)), ((15, 16), (250, 214, 70, 255))):
    for dx, dy in ((-3, 0), (3, 0), (0, -3), (0, 3)):
        c.ellipse(cx + dx, cy + dy, 2.6, 2.6, col, outline=0)
    c.detail_ellipse(cx, cy, 1.6, 1.6, (250, 200, 60, 255))
c.save(f"{OUT}/sprites/flowers.png")

# ---- milestone 3: people, the guide, wharf and street props ----------------------------------
def person(path, skin, shirt, pants, head="hair", head_col=(40, 30, 30, 255), apron=None, extra=None):
    """A townsperson in the hero's proportions: 64x84, anchor = feet at bottom centre."""
    c = Canvas(64, 84)
    c.rrect(21, 66, 30, 81, 4, pants)
    c.rrect(34, 66, 43, 81, 4, pants)
    c.ellipse(16, 56, 6, 6, skin)
    c.ellipse(48, 56, 6, 6, skin)
    c.rrect(18, 42, 46, 72, 10, shirt)
    if head == "hair":
        c.ellipse(32, 26, 21, 19, head_col)
    c.ellipse(32, 30, 18, 17, skin)
    if head == "hair":
        c.poly([(14, 26), (18, 12), (32, 8), (46, 12), (50, 26), (44, 18), (32, 15), (20, 18)], head_col)
    elif head == "wrap":
        c.poly([(12, 28), (14, 12), (32, 4), (50, 12), (52, 28), (46, 20), (18, 20)], head_col)
        c.ellipse(46, 10, 7, 6, head_col)
    elif head == "bucket":
        c.rrect(8, 18, 56, 24, 3, head_col)
        c.rrect(17, 4, 47, 21, 7, head_col)
    elif head == "cap":
        c.poly([(13, 24), (16, 10), (32, 6), (48, 10), (51, 24)], head_col)
        c.rrect(30, 20, 60, 25, 3, head_col)
    if apron:
        c.rrect(22, 52, 42, 74, 5, apron, outline=1.5)
    c.detail_ellipse(25, 33, 2.4, 3.2, INK)
    c.detail_ellipse(39, 33, 2.4, 3.2, INK)
    c.detail_line([(28, 41), (32, 43), (36, 41)], INK, 1.5)
    if extra == "moustache":
        c.detail_line([(26, 39), (32, 38), (38, 39)], INK, 2.5)
    c.save(path)


SKINS = [(124, 78, 52, 255), (176, 118, 78, 255), (92, 58, 40, 255), (214, 164, 120, 255), (150, 96, 64, 255)]
person(f"{OUT}/sprites/npc_vendor.png", SKINS[1], (240, 240, 236, 255), (60, 60, 80, 255), "cap", (30, 130, 90, 255), apron=(250, 250, 250, 255), extra="moustache")
person(f"{OUT}/sprites/npc_auntie.png", SKINS[0], (232, 96, 140, 255), (120, 60, 120, 255), "wrap", (250, 200, 60, 255))
person(f"{OUT}/sprites/npc_fisherman.png", SKINS[2], (90, 150, 190, 255), (70, 70, 60, 255), "bucket", (200, 186, 140, 255), extra="moustache")
person(f"{OUT}/sprites/npc_limer.png", SKINS[3], (250, 250, 250, 255), (40, 70, 140, 255), "hair", (30, 24, 24, 255))
person(f"{OUT}/sprites/npc_cook.png", SKINS[4], (250, 170, 40, 255), (70, 50, 40, 255), "wrap", (220, 40, 40, 255), apron=(255, 240, 220, 255))

c = Canvas(72, 92)  # scarlet ibis, the guide: anchor = feet at bottom centre
IBIS, IBIS_D = (226, 52, 44, 255), (176, 30, 34, 255)
c.rrect(30, 62, 33, 90, 1.5, (60, 40, 40, 255), outline=1.2)
c.rrect(39, 62, 42, 90, 1.5, (60, 40, 40, 255), outline=1.2)
c.ellipse(36, 52, 20, 15, IBIS)
c.poly([(18, 50), (4, 58), (20, 60)], IBIS_D)
c.rrect(40, 22, 50, 50, 5, IBIS)
c.ellipse(47, 20, 10, 9, IBIS)
c.poly([(55, 18), (66, 24), (70, 34), (64, 26), (55, 23)], (60, 40, 40, 255), outline=1.5)
c.detail_ellipse(49, 17, 2, 2.2, INK)
c.detail_line([(24, 52), (40, 56)], IBIS_D, 2.5)
c.save(f"{OUT}/sprites/ibis.png")

c = Canvas(64, 76)  # sign: anchor = foot of the post at (32, 72)
WOOD, WOOD_D = (176, 124, 72, 255), (128, 86, 50, 255)
c.rrect(28, 38, 36, 72, 2, WOOD_D)
c.rrect(4, 6, 60, 42, 6, WOOD)
for y in (16, 24, 32):
    c.detail_line([(12, y), (52, y)], WOOD_D, 2)
c.save(f"{OUT}/sprites/sign.png")

c = Canvas(64, 74)  # crate: anchor = bottom centre (32, 72)
c.rrect(4, 26, 60, 72, 4, (168, 116, 66, 255))
c.rrect(4, 6, 60, 34, 6, (204, 152, 96, 255))
c.detail_line([(4, 48), (60, 48)], (122, 82, 46, 255), 2.5)
c.detail_line([(10, 30), (54, 70)], (122, 82, 46, 255), 2.5)
c.save(f"{OUT}/sprites/crate.png")

c = Canvas(48, 56)  # bollard: anchor = bottom centre (24, 54)
c.rrect(10, 18, 38, 54, 6, (70, 74, 86, 255))
c.ellipse(24, 16, 17, 9, (96, 100, 114, 255))
c.detail_ellipse(18, 14, 6, 3, (140, 144, 158, 255))
c.save(f"{OUT}/sprites/bollard.png")

c = Canvas(200, 130)  # wrecked boat (3x2 tiles footprint): anchor = bottom centre (100, 126)
HULL, HULL_D = (70, 120, 160, 255), (46, 84, 118, 255)
c.poly([(10, 60), (190, 52), (170, 120), (36, 124)], HULL)
c.poly([(16, 62), (186, 54), (180, 70), (22, 76)], (230, 230, 220, 255), outline=1.5)
c.rrect(96, 8, 104, 60, 3, (150, 104, 60, 255))
c.poly([(104, 12), (150, 40), (104, 52)], (236, 226, 200, 255), outline=2)
c.detail_line([(50, 90), (70, 100), (66, 112)], HULL_D, 3)
c.detail_line([(130, 84), (146, 98)], HULL_D, 3)
c.save(f"{OUT}/sprites/boat.png")


def stall(path, awning, awning_l):
    """Street food stall, 2x1 tile footprint: 136x150, anchor = bottom centre (68, 146)."""
    c = Canvas(136, 150)
    c.rrect(14, 70, 22, 146, 2, (120, 86, 56, 255))
    c.rrect(114, 70, 122, 146, 2, (120, 86, 56, 255))
    c.rrect(8, 96, 128, 146, 6, (196, 150, 98, 255))
    c.rrect(8, 92, 128, 104, 4, (226, 186, 130, 255))
    c.poly([(2, 70), (14, 22), (122, 22), (134, 70)], awning)
    for i in range(5):
        x0 = 14 + i * 22
        if i % 2 == 0:
            c.detail_line([(x0 + 11 - 6, 26), (x0 + 11 - 12, 66)], awning_l, 10)
    c.rrect(20, 4, 116, 30, 6, (250, 246, 232, 255))
    c.detail_ellipse(40, 90, 10, 5, (250, 210, 120, 255))
    c.detail_ellipse(68, 89, 12, 5, (226, 118, 34, 255))
    c.detail_ellipse(96, 90, 10, 5, (250, 210, 120, 255))
    c.save(path)


stall(f"{OUT}/sprites/stall_red.png", (214, 58, 58, 255), (250, 240, 236, 255))
stall(f"{OUT}/sprites/stall_yellow.png", (246, 196, 50, 255), (255, 244, 200, 255))
stall(f"{OUT}/sprites/stall_green.png", (40, 150, 90, 255), (220, 250, 230, 255))

# ground: dock planks and road
planks = Image.new("RGB", (256, 256))
pn = fractal(256, 11)
base = np.array((150, 104, 62), np.float32)
light = np.array((190, 140, 90), np.float32)
arr = base[None, None, :] * (1 - pn[..., None]) + light[None, None, :] * pn[..., None]
for y in range(0, 256, 32):
    arr[y : y + 3, :, :] = (96, 64, 38)
    offset = (y // 32) * 72 % 256
    for x in (offset, (offset + 128) % 256):
        arr[y : y + 32, x : x + 2, :] = (110, 74, 44)
Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB").save(f"{OUT}/textures/wood.png")
material(f"{OUT}/textures/road.png", (62, 64, 72), (92, 94, 104), 12, grain=0.35, contrast=1.1)

# ---- Cross Crossing and Lady Hailes Avenue (from the owner's street footage) -------------------
def car(path, body, roof):
    """Top-down car facing down (front at the bottom): 60x104, centred."""
    c = Canvas(60, 104)
    for x, y in ((6, 22), (54, 22), (6, 80), (54, 80)):
        c.rrect(x - 4, y - 9, x + 4, y + 9, 3, (30, 30, 36, 255), outline=1.5)
    c.rrect(6, 4, 54, 100, 16, body)
    c.rrect(12, 30, 48, 74, 8, roof)
    c.detail_line([(14, 74), (46, 74)], (60, 72, 96, 255), 7)  # windscreen
    c.detail_line([(15, 30), (45, 30)], (60, 72, 96, 255), 5)  # rear window
    c.detail_ellipse(15, 94, 5, 3, (255, 244, 190, 255))
    c.detail_ellipse(45, 94, 5, 3, (255, 244, 190, 255))
    c.detail_ellipse(15, 9, 5, 2.5, (220, 60, 60, 255))
    c.detail_ellipse(45, 9, 5, 2.5, (220, 60, 60, 255))
    c.save(path)


car(f"{OUT}/sprites/car_white.png", (236, 238, 240, 255), (250, 250, 252, 255))
car(f"{OUT}/sprites/car_red.png", (196, 46, 52, 255), (220, 70, 72, 255))
car(f"{OUT}/sprites/car_blue.png", (52, 92, 170, 255), (76, 116, 196, 255))
car(f"{OUT}/sprites/car_grey.png", (128, 132, 140, 255), (152, 156, 164, 255))


def food_truck(path, body, accent, trailer=False):
    """Food truck / trailer, side view: 208x156, anchor = wheels at bottom centre (104, 150)."""
    c = Canvas(208, 156)
    for x in ((40, 160) if not trailer else (70, 138)):
        c.ellipse(x, 140, 13, 13, (36, 36, 40, 255))
    if trailer:
        c.rrect(196, 116, 208, 122, 2, (90, 90, 96, 255), outline=1.5)
    else:
        c.rrect(150, 52, 204, 134, 12, body)  # cab
        c.rrect(168, 62, 198, 92, 6, (120, 160, 200, 255), outline=1.5)
    c.rrect(6, 30, 160 if not trailer else 198, 134, 10, body)
    c.rrect(30, 54, 128, 96, 5, (60, 50, 50, 255), outline=1.5)  # serving window
    c.poly([(24, 50), (134, 50), (142, 34), (16, 34)], accent, outline=2)  # awning
    c.rrect(30, 96, 128, 104, 2, (230, 220, 200, 255), outline=1.5)  # counter
    for i in range(4):
        c.detail_ellipse(44 + i * 26, 98, 7, 3, (240, 190, 90, 255))
    c.detail_line([(12, 120), (150 if not trailer else 190, 120)], accent, 6)  # stripe
    c.save(path)


food_truck(f"{OUT}/sprites/truck_red.png", (204, 50, 50, 255), (250, 210, 60, 255))
food_truck(f"{OUT}/sprites/truck_yellow.png", (246, 200, 54, 255), (214, 64, 48, 255), trailer=True)
food_truck(f"{OUT}/sprites/truck_orange.png", (240, 140, 40, 255), (60, 150, 210, 255), trailer=True)
food_truck(f"{OUT}/sprites/truck_teal.png", (40, 160, 160, 255), (250, 240, 220, 255))
food_truck(f"{OUT}/sprites/truck_purple.png", (128, 76, 170, 255), (250, 200, 70, 255))

c = Canvas(340, 250)  # gas station: canopy over a pump island; anchor = island base (170, 246)
c.rrect(40, 56, 56, 246, 4, (220, 220, 226, 255))
c.rrect(284, 56, 300, 246, 4, (220, 220, 226, 255))
c.rrect(90, 200, 250, 246, 8, (190, 190, 196, 255))  # island
for x in (120, 200):
    c.rrect(x, 150, x + 30, 214, 5, (210, 54, 54, 255))
    c.rrect(x + 5, 160, x + 25, 182, 3, (40, 46, 60, 255), outline=1.2)
c.rrect(4, 10, 336, 64, 10, (246, 246, 248, 255))  # canopy slab
c.detail_line([(10, 44), (330, 44)], (214, 50, 50, 255), 12)
c.detail_line([(10, 56), (330, 56)], (200, 200, 206, 255), 3)
c.save(f"{OUT}/sprites/gas_station.png")

c = Canvas(400, 330)  # tall yellow building with a green sign; anchor = bottom centre (200, 326)
YEL, YEL_D = (238, 200, 70, 255), (206, 164, 50, 255)
c.rrect(20, 20, 380, 326, 6, YEL)
c.rrect(14, 12, 386, 30, 4, (230, 230, 226, 255))
for floor in range(4):
    y = 44 + floor * 62
    for i in range(6):
        c.detail_line([(48 + i * 56, y), (48 + i * 56, y + 34)], (70, 90, 110, 255), 26)
    c.detail_line([(20, y + 48), (380, y + 48)], YEL_D, 3)
c.rrect(0, 60, 26, 300, 4, (40, 150, 90, 255))  # green vertical sign
c.rrect(140, 270, 260, 326, 4, (90, 96, 104, 255))  # entrance
c.save(f"{OUT}/sprites/yellow_building.png")


def shop(path, wall, trim):
    """Single-storey flat-roof shop with a roller shutter: 200x170, anchor = bottom centre (100, 166)."""
    c = Canvas(200, 170)
    c.rrect(6, 40, 194, 166, 4, wall)
    c.rrect(0, 32, 200, 46, 3, trim)
    c.rrect(30, 4, 170, 36, 5, (250, 248, 240, 255))  # signboard
    c.rrect(26, 70, 122, 166, 3, (150, 154, 160, 255))  # shutter
    for y in range(80, 160, 10):
        c.detail_line([(30, y), (118, y)], (120, 124, 130, 255), 2)
    c.rrect(136, 72, 178, 120, 3, (110, 150, 190, 255), outline=1.5)
    c.save(path)


shop(f"{OUT}/sprites/shop_blue.png", (120, 170, 214, 255), (60, 100, 150, 255))
shop(f"{OUT}/sprites/shop_pink.png", (234, 160, 170, 255), (190, 90, 110, 255))
shop(f"{OUT}/sprites/shop_cream.png", (238, 226, 196, 255), (170, 150, 110, 255))

c = Canvas(64, 250)  # utility pole: anchor = foot (32, 246); wires attach at the crossarm (y=26)
c.rrect(27, 14, 37, 246, 4, (120, 92, 66, 255))
c.rrect(4, 22, 60, 30, 3, (96, 74, 54, 255))
for x in (10, 32, 54):
    c.rrect(x - 3, 14, x + 3, 22, 2, (210, 220, 230, 255), outline=1.2)
c.save(f"{OUT}/sprites/pole.png")

c = Canvas(64, 80)  # chain-link fence segment: anchor = bottom centre (32, 78)
c.rrect(2, 10, 8, 78, 2, (150, 156, 164, 255), outline=1.5)
c.rrect(56, 10, 62, 78, 2, (150, 156, 164, 255), outline=1.5)
c.rrect(2, 10, 62, 15, 2, (150, 156, 164, 255), outline=1.5)
for i in range(-8, 9):
    c.detail_line([(8 + i * 6, 16), (8 + i * 6 + 58, 76)], (176, 182, 190, 255), 1.2)
    c.detail_line([(56 - i * 6, 16), (56 - i * 6 - 58, 76)], (176, 182, 190, 255), 1.2)
c.save(f"{OUT}/sprites/fence.png")

c = Canvas(66, 86)  # painted concrete wall block: anchor = bottom centre (33, 84)
c.rrect(3, 22, 63, 84, 4, (226, 218, 200, 255))
c.rrect(1, 12, 65, 26, 4, (196, 188, 170, 255))
c.detail_line([(3, 60), (63, 60)], (206, 198, 180, 255), 2)
c.save(f"{OUT}/sprites/wall.png")

# ---- sandbox: item icons (48x48, centred) and forage plants -----------------------------------
def icon(path, draw):
    c = Canvas(48, 48)
    draw(c)
    c.save(path)


def _mango(c):
    c.ellipse(24, 27, 15, 13, (246, 170, 46, 255))
    c.detail_ellipse(18, 24, 8, 7, (250, 210, 70, 255))
    c.detail_ellipse(31, 32, 6, 5, (226, 88, 50, 255))
    c.ellipse(29, 12, 7, 3.5, (60, 150, 70, 255), outline=1.5)


def _coconut(c):
    c.ellipse(24, 26, 16, 15, (120, 84, 52, 255))
    c.detail_ellipse(19, 21, 5, 4, (150, 110, 74, 255))
    for x, y in ((20, 26), (27, 25), (24, 31)):
        c.detail_ellipse(x, y, 1.8, 1.8, (70, 46, 30, 255))


def _chadon_beni(c):
    for ang, (dx, dy) in enumerate(((-9, -4), (9, -6), (0, -12), (-6, 6), (8, 5))):
        c.ellipse(24 + dx, 26 + dy, 6, 11, (66, 160, 72, 255), outline=1.8)
    c.detail_line([(24, 40), (24, 18)], (40, 110, 50, 255), 2)


def _pimento(c):
    c.poly([(16, 18), (34, 16), (36, 30), (26, 42), (14, 30)], (222, 52, 40, 255))
    c.detail_ellipse(21, 22, 4, 3, (250, 120, 100, 255))
    c.rrect(22, 8, 27, 18, 2, (60, 140, 60, 255), outline=1.5)


icon(f"{OUT}/items/mango.png", _mango)
icon(f"{OUT}/items/coconut.png", _coconut)
icon(f"{OUT}/items/chadon_beni.png", _chadon_beni)
icon(f"{OUT}/items/pimento.png", _pimento)


def fruit_tree(path, fruit):
    """Mango tree, 128x156 like the plain tree; fruit drawn when given. Anchor (64, 150)."""
    c = Canvas(128, 156)
    c.rrect(54, 96, 74, 150, 6, (116, 78, 46, 255))
    for cx, cy, r in ((40, 74, 30), (88, 74, 30), (64, 52, 38), (38, 46, 26), (92, 46, 26), (64, 86, 30)):
        c.ellipse(cx, cy, r, r * 0.92, (40, 118, 64, 255))
    for cx, cy, r in ((52, 40, 16), (82, 36, 12)):
        c.detail_ellipse(cx, cy, r, r * 0.8, (84, 160, 84, 255))
    if fruit:
        for x, y in ((40, 66), (62, 80), (84, 60), (72, 44), (48, 90), (94, 84), (30, 50)):
            c.detail_ellipse(x, y, 6, 5, (246, 170, 46, 255))
            c.detail_ellipse(x - 2, y - 1.5, 2.5, 2, (252, 214, 90, 255))
    c.save(path)


fruit_tree(f"{OUT}/sprites/mango_tree.png", True)
fruit_tree(f"{OUT}/sprites/mango_tree_picked.png", False)


def palm(path, nuts):
    """Coconut palm, 120x176. Anchor = trunk base (60, 172)."""
    c = Canvas(120, 176)
    c.poly([(56, 172), (66, 172), (70, 60), (62, 40), (54, 60)], (156, 116, 72, 255))
    for x0, y0, x1, y1 in ((60, 40, 6, 58), (60, 40, 114, 58), (60, 40, 20, 14), (60, 40, 100, 12), (60, 40, 60, 2)):
        c.poly([(x0, y0 - 6), (x1, y1), (x0, y0 + 6)], (52, 140, 70, 255), outline=2)
    if nuts:
        for x, y in ((52, 50), (66, 52), (59, 58)):
            c.ellipse(x, y, 7, 7, (120, 84, 52, 255), outline=2)
    c.save(path)


palm(f"{OUT}/sprites/palm.png", True)
palm(f"{OUT}/sprites/palm_picked.png", False)


def herb_patch(path, ready, leaf, extra=None):
    """Low plant patch, 72x48. Anchor = bottom centre (36, 46)."""
    c = Canvas(72, 48)
    for cx, cy in ((18, 34), (36, 28), (54, 34), (27, 38), (45, 38)):
        c.ellipse(cx, cy, 9 if ready else 6, 7 if ready else 4.5, leaf, outline=2)
    if ready and extra:
        for x, y in ((22, 26), (40, 22), (52, 28), (30, 34)):
            c.detail_ellipse(x, y, 3.5, 4.5, extra)
    c.save(path)


herb_patch(f"{OUT}/sprites/chadon_beni_patch.png", True, (66, 160, 72, 255))
herb_patch(f"{OUT}/sprites/chadon_beni_patch_picked.png", False, (66, 160, 72, 255))
herb_patch(f"{OUT}/sprites/pepper_bush.png", True, (48, 128, 60, 255), (222, 52, 40, 255))
herb_patch(f"{OUT}/sprites/pepper_bush_picked.png", False, (48, 128, 60, 255))

# ---- fishing: fish icons, rod, slipper, bobber ------------------------------------------------
def fish_icon(path, body, fin, stripe=None, long=False):
    c = Canvas(48, 48)
    rx = 18 if long else 15
    c.poly([(6, 16), (12, 24), (6, 32)], fin, outline=2)
    c.ellipse(26, 24, rx, 10, body)
    c.poly([(24, 14), (32, 8), (34, 16)], fin, outline=1.5)
    if stripe:
        c.detail_line([(14, 24), (40, 24)], stripe, 2.5)
    c.detail_ellipse(36, 22, 2.4, 2.4, INK)
    c.save(path)


fish_icon(f"{OUT}/items/red_snapper.png", (226, 76, 70, 255), (196, 50, 50, 255))
fish_icon(f"{OUT}/items/carite.png", (150, 170, 190, 255), (90, 110, 140, 255), (230, 200, 90, 255), long=True)
fish_icon(f"{OUT}/items/kingfish.png", (110, 130, 160, 255), (60, 76, 110, 255), (200, 210, 230, 255), long=True)
fish_icon(f"{OUT}/items/cavalli.png", (190, 196, 160, 255), (230, 200, 70, 255))
fish_icon(f"{OUT}/items/flying_fish.png", (80, 130, 200, 255), (160, 210, 240, 255))


def _rod(c):
    c.detail_line([(8, 42), (40, 8)], (120, 80, 46, 255), 4)
    c.detail_line([(40, 8), (42, 30)], (230, 230, 230, 255), 1.2)
    c.ellipse(14, 36, 5, 5, (60, 60, 70, 255), outline=1.5)
    c.ellipse(42, 32, 3, 3, (220, 60, 60, 255), outline=1)


def _slipper(c):
    c.rrect(10, 14, 38, 38, 12, (60, 140, 220, 255))
    c.detail_line([(16, 22), (24, 28), (32, 22)], (250, 210, 60, 255), 3)


icon(f"{OUT}/items/fishing_rod.png", _rod)
icon(f"{OUT}/items/slipper.png", _slipper)

c = Canvas(24, 24)  # bobber
c.ellipse(12, 12, 8, 8, (240, 240, 240, 255))
c.detail_line([(5, 12), (19, 12)], (220, 50, 50, 255), 6)
c.save(f"{OUT}/sprites/bobber.png")

# ---- night dangers -------------------------------------------------------------------------------
c = Canvas(64, 84)  # bandit: a cartoon sneak-thief (hood, eye mask, bandana), anchor = feet
HOOD, HOOD_L, BANDANA = (52, 50, 66, 255), (78, 76, 96, 255), (176, 40, 52, 255)
c.rrect(21, 66, 30, 81, 4, (34, 34, 44, 255))
c.rrect(34, 66, 43, 81, 4, (34, 34, 44, 255))
c.rrect(18, 78, 31, 83, 2.5, (230, 230, 236, 255), outline=1.5)  # sneakers
c.rrect(33, 78, 46, 83, 2.5, (230, 230, 236, 255), outline=1.5)
c.ellipse(15, 58, 6, 6, HOOD)
c.ellipse(49, 58, 6, 6, HOOD)
c.rrect(17, 42, 47, 72, 10, HOOD)
c.ellipse(32, 28, 21, 21, HOOD)  # hood
c.ellipse(32, 31, 15, 15, SKINS[1], outline=2)  # face in the hood
c.poly([(17, 34), (47, 34), (44, 46), (32, 50), (20, 46)], BANDANA, outline=2)  # bandana
c.detail_line([(16, 27), (48, 27)], INK, 7)  # eye mask
c.detail_ellipse(25, 27, 3, 2.2, (250, 246, 240, 255))
c.detail_ellipse(39, 27, 3, 2.2, (250, 246, 240, 255))
c.detail_ellipse(26, 27.3, 1.5, 1.5, INK)  # shifty side-eye
c.detail_ellipse(40, 27.3, 1.5, 1.5, INK)
c.detail_ellipse(24, 46, 5, 3, HOOD_L)  # hoodie pocket
c.detail_ellipse(40, 46, 5, 3, HOOD_L)
c.detail_line([(26, 52), (38, 52)], HOOD_L, 2.5)
c.detail_line([(28, 40), (31, 42), (35, 39)], (210, 90, 96, 255), 1.4)  # bandana fold
c.save(f"{OUT}/sprites/bandit.png")

c = Canvas(40, 40)  # loot bag carried over the bandit's head, anchor = centre
c.ellipse(20, 24, 14, 13, (176, 136, 84, 255))
c.poly([(13, 10), (27, 10), (24, 15), (16, 15)], (176, 136, 84, 255), outline=2)
c.detail_line([(15, 14), (25, 14)], (110, 80, 50, 255), 2)
c.detail_line([(20, 17), (20, 33)], (60, 120, 60, 255), 2)
c.detail_line([(24, 20), (17, 22), (23, 27), (16, 30)], (60, 120, 60, 255), 2.5)  # a "$"
c.save(f"{OUT}/sprites/loot_bag.png")

c = Canvas(64, 64)  # soucouyant fireball, anchor = bottom centre (the game lifts it)
c.poly([(32, 6), (44, 24), (52, 14), (54, 36), (32, 60), (10, 36), (12, 14), (20, 24)], (226, 70, 34, 255), outline=2)
c.ellipse(32, 40, 18, 18, (246, 130, 40, 255), outline=0)
c.detail_ellipse(32, 44, 12, 12, (252, 196, 70, 255))
c.detail_ellipse(32, 47, 7, 7, (255, 240, 170, 255))
c.detail_line([(24, 36), (29, 38)], INK, 2)  # cross little eyebrows
c.detail_line([(40, 36), (35, 38)], INK, 2)
c.detail_ellipse(27, 41, 2, 2.2, INK)
c.detail_ellipse(37, 41, 2, 2.2, INK)
c.save(f"{OUT}/sprites/soucouyant.png")

# ---- temple 1: Callaloo Cave ----------------------------------------------------------------------
WOOD, WOOD_D, IRON, IRON_L = (150, 98, 56, 255), (110, 70, 40, 255), (70, 70, 84, 255), (130, 134, 150, 255)
STONE, STONE_D = (128, 118, 112, 255), (92, 84, 82, 255)
BRASS = (236, 196, 80, 255)


def padlock(c, cx, cy):
    c.ellipse(cx, cy - 6, 7, 8, IRON, outline=2)
    c.detail_ellipse(cx, cy - 6, 3.5, 4.5, WOOD_D)
    c.rrect(cx - 10, cy - 2, cx + 10, cy + 14, 3, BRASS, outline=2)
    c.detail_ellipse(cx, cy + 5, 2, 2.5, INK)


c = Canvas(128, 112)  # locked door across a top/bottom wall: anchor = bottom centre
c.rrect(2, 6, 126, 110, 10, STONE)
c.rrect(14, 20, 114, 110, 6, WOOD)
for x in (38, 64, 90):
    c.detail_line([(x, 24), (x, 108)], WOOD_D, 2)
for y in (40, 88):
    c.detail_line([(16, y), (112, y)], IRON, 5)
padlock(c, 64, 60)
c.save(f"{OUT}/sprites/door_locked_h.png")

c = Canvas(64, 176)  # locked door in a side wall: anchor = bottom centre
c.rrect(4, 4, 60, 174, 8, STONE)
c.rrect(14, 16, 50, 172, 5, WOOD)
for y in (50, 130):
    c.detail_line([(16, y), (48, y)], IRON, 5)
c.detail_line([(32, 20), (32, 168)], WOOD_D, 2)
padlock(c, 32, 86)
c.save(f"{OUT}/sprites/door_locked_v.png")

c = Canvas(128, 112)  # iron gate across a top/bottom wall
c.rrect(2, 6, 126, 110, 10, STONE)
c.rrect(12, 18, 116, 110, 4, (34, 28, 40, 255), outline=1.5)
for x in range(20, 112, 16):
    c.rrect(x, 18, x + 6, 110, 3, IRON, outline=1.5)
c.detail_line([(14, 44), (114, 44)], IRON_L, 4)
c.detail_line([(14, 84), (114, 84)], IRON_L, 4)
c.save(f"{OUT}/sprites/gate_h.png")

c = Canvas(64, 176)  # iron gate in a side wall
c.rrect(4, 4, 60, 174, 8, STONE)
c.rrect(12, 14, 52, 172, 4, (34, 28, 40, 255), outline=1.5)
for y in range(22, 168, 18):
    c.rrect(12, y, 52, y + 6, 3, IRON, outline=1.5)
c.detail_line([(26, 16), (26, 170)], IRON_L, 3)
c.detail_line([(40, 16), (40, 170)], IRON_L, 3)
c.save(f"{OUT}/sprites/gate_v.png")


def chest(path, open_):
    """Treasure chest, 64x60, anchor = bottom centre (the game lifts it by 24 px)."""
    c = Canvas(64, 60)
    c.rrect(6, 26, 58, 58, 6, WOOD)
    if open_:
        c.rrect(8, 4, 56, 22, 6, WOOD_D)
        c.detail_ellipse(32, 28, 22, 4, (250, 230, 140, 255))
    else:
        c.rrect(6, 10, 58, 32, 10, WOOD)
        c.detail_line([(8, 30), (56, 30)], WOOD_D, 3)
    for x in (16, 48):
        c.detail_line([(x, 28 if open_ else 12), (x, 56)], BRASS, 4)
    if not open_:
        c.rrect(27, 26, 37, 38, 2, BRASS, outline=1.5)
    c.save(path)


chest(f"{OUT}/sprites/chest.png", False)
chest(f"{OUT}/sprites/chest_open.png", True)

c = Canvas(64, 82)  # push block: anchor = bottom centre (sits on its tile, top face showing)
c.rrect(2, 22, 62, 80, 6, STONE_D)
c.rrect(2, 2, 62, 50, 6, STONE)
c.detail_line([(12, 14), (52, 14)], (160, 150, 144, 255), 3)
c.detail_ellipse(32, 26, 9, 9, STONE_D)
c.detail_ellipse(32, 26, 5, 5, (110, 100, 98, 255))
c.save(f"{OUT}/sprites/block.png")


def plate(path, down):
    c = Canvas(60, 60)  # pressure plate decal, anchor = centre
    c.rrect(2, 2, 58, 58, 6, STONE_D, outline=2)
    c.rrect(8, 8 if not down else 12, 52, 52, 5, (196, 150, 70, 255) if not down else (120, 96, 60, 255), outline=1.5)
    c.detail_ellipse(30, 30 if not down else 33, 8, 8, (230, 190, 100, 255) if not down else (150, 120, 70, 255))
    c.save(path)


plate(f"{OUT}/sprites/plate.png", False)
plate(f"{OUT}/sprites/plate_down.png", True)


def orb(path, colour, light):
    c = Canvas(56, 80)  # crystal switch on a stand: anchor = bottom centre (lifted 24 px in game)
    c.rrect(14, 50, 42, 78, 4, STONE)
    c.rrect(8, 44, 48, 54, 4, STONE_D)
    c.ellipse(28, 26, 20, 20, colour)
    c.detail_ellipse(22, 19, 7, 5, light)
    c.save(path)


orb(f"{OUT}/sprites/switch_off.png", (220, 60, 70, 255), (255, 170, 170, 255))
orb(f"{OUT}/sprites/switch_on.png", (60, 130, 230, 255), (180, 220, 255, 255))

c = Canvas(56, 40)  # cave crab, anchor = feet at bottom centre
SHELL, SHELL_D = (70, 120, 200, 255), (46, 84, 150, 255)
for x in (8, 14, 42, 48):
    c.detail_line([(x + (6 if x < 28 else -6), 26), (x, 38)], SHELL_D, 3)
c.ellipse(4, 14, 6, 6, SHELL)
c.ellipse(52, 14, 6, 6, SHELL)
c.ellipse(28, 24, 18, 12, SHELL)
c.detail_ellipse(28, 20, 10, 4, (120, 170, 236, 255))
for x in (22, 34):
    c.detail_line([(x, 14), (x, 8)], SHELL_D, 2)
    c.detail_ellipse(x, 7, 2.5, 2.5, INK)
c.save(f"{OUT}/sprites/crab.png")

c = Canvas(176, 120)  # the Big Blue Crab (mini-boss), anchor = feet at bottom centre
for x in (34, 50, 66, 110, 126, 142):
    c.detail_line([(x + (14 if x < 88 else -14), 80), (x, 116)], SHELL_D, 5)
c.poly([(6, 40), (2, 12), (22, 2), (36, 22), (26, 44)], SHELL)  # left claw
c.poly([(170, 40), (174, 12), (154, 2), (140, 22), (150, 44)], SHELL)  # right claw
c.detail_line([(12, 6), (22, 24)], (250, 240, 230, 255), 3)
c.detail_line([(164, 6), (154, 24)], (250, 240, 230, 255), 3)
c.ellipse(88, 74, 64, 40, SHELL)
c.detail_ellipse(88, 64, 40, 14, (120, 170, 236, 255))
c.detail_ellipse(64, 86, 8, 5, SHELL_D)
c.detail_ellipse(112, 86, 8, 5, SHELL_D)
for x in (72, 104):
    c.detail_line([(x, 42), (x, 26)], SHELL_D, 4)
    c.detail_ellipse(x, 24, 6, 6, (250, 246, 240, 255))
    c.detail_ellipse(x + (2 if x < 88 else -2), 25, 3, 3, INK)
c.detail_line([(64, 18), (78, 24)], INK, 3)  # angry brows
c.detail_line([(112, 18), (98, 24)], INK, 3)
c.detail_line([(78, 96), (88, 92), (98, 96)], INK, 3)
c.save(f"{OUT}/sprites/big_crab.png")


def _boomerang(c):
    c.poly([(8, 34), (22, 6), (30, 10), (20, 30), (42, 38), (38, 44)], (128, 82, 46, 255), outline=2.5)
    c.detail_line([(14, 32), (24, 10)], (176, 124, 76, 255), 2)
    c.detail_line([(22, 34), (38, 40)], (176, 124, 76, 255), 2)
    c.detail_ellipse(21, 32, 3, 3, (250, 244, 230, 255))


icon(f"{OUT}/items/coconut_boomerang.png", _boomerang)

c = Canvas(32, 36)  # small key (HUD and chests)
c.ellipse(16, 10, 9, 9, BRASS, outline=2)
c.rrect(13, 14, 19, 34, 2, BRASS, outline=2)
c.rrect(19, 24, 25, 28, 1, BRASS, outline=1.5)
c.rrect(19, 30, 25, 34, 1, BRASS, outline=1.5)
c.detail_ellipse(16, 10, 4, 4, (120, 90, 30, 255))
c.save(f"{OUT}/sprites/key.png")

c = Canvas(200, 176)  # cave mouth in a rock face (no collision): anchor = bottom centre
c.ellipse(100, 120, 98, 70, STONE)
c.ellipse(100, 70, 80, 64, (150, 140, 132, 255))
c.ellipse(100, 140, 52, 44, (16, 12, 22, 255), outline=4)
c.poly([(48, 176), (152, 176), (148, 140), (52, 140)], (16, 12, 22, 255), outline=0)
c.detail_ellipse(70, 52, 20, 8, (176, 168, 160, 255))
c.detail_line([(30, 110), (46, 130)], STONE_D, 3)
c.detail_line([(166, 96), (156, 120)], STONE_D, 3)
c.save(f"{OUT}/sprites/cave_mouth.png")

c = Canvas(40, 104)  # wall torch on a post: anchor = foot
c.rrect(16, 40, 24, 102, 3, WOOD_D)
c.rrect(8, 34, 32, 46, 4, IRON)
c.poly([(20, 2), (32, 22), (28, 36), (12, 36), (8, 22)], (246, 130, 40, 255), outline=2)
c.detail_ellipse(20, 26, 6, 8, (252, 220, 100, 255))
c.save(f"{OUT}/sprites/torch.png")


# ---- milestone 5: the Temple 1 boss, the rival and Brownie ------------------------------------------
c = Canvas(128, 150)  # sealed pepper door across a top wall: anchor = bottom centre
c.rrect(2, 6, 126, 148, 12, STONE_D)
c.rrect(14, 22, 114, 148, 40, (60, 40, 30, 255))
c.rrect(22, 32, 106, 148, 34, WOOD)
c.detail_line([(64, 34), (64, 146)], WOOD_D, 3)
for y in (70, 118):
    c.detail_line([(24, y), (104, y)], IRON, 6)
c.poly([(64, 64), (80, 82), (76, 108), (64, 116), (52, 108), (48, 82)], (220, 50, 40, 255), outline=2.5)
c.rrect(60, 54, 68, 66, 2, (60, 140, 60, 255), outline=1.5)
c.detail_ellipse(58, 84, 3, 7, (255, 140, 120, 255))
c.save(f"{OUT}/sprites/door_boss_h.png")

c = Canvas(40, 40)  # the Pepper Key (HUD), anchor = centre
c.poly([(12, 6), (22, 14), (20, 28), (12, 34), (4, 28), (2, 14)], (220, 50, 40, 255), outline=2)
c.rrect(10, 2, 14, 8, 1, (60, 140, 60, 255), outline=1.2)
c.rrect(18, 16, 38, 22, 2, BRASS, outline=1.5)
c.rrect(30, 22, 34, 30, 1, BRASS, outline=1.2)
c.detail_ellipse(9, 16, 2, 4, (255, 140, 120, 255))
c.save(f"{OUT}/sprites/pepper_key.png")

c = Canvas(180, 150)  # the Callaloo Cauldron, anchor = bottom centre (the lid is separate)
POT, POT_L = (52, 50, 60, 255), (96, 94, 110, 255)
c.rrect(30, 126, 52, 148, 6, POT)  # legs
c.rrect(128, 126, 150, 148, 6, POT)
c.ellipse(10, 70, 12, 10, POT)  # handles
c.ellipse(170, 70, 12, 10, POT)
c.ellipse(90, 84, 80, 62, POT)
c.ellipse(90, 28, 74, 16, POT_L)  # rim
c.detail_ellipse(90, 28, 66, 11, (70, 140, 60, 255))  # callaloo
c.detail_ellipse(70, 26, 8, 4, (120, 190, 90, 255))
c.detail_ellipse(112, 30, 6, 3, (120, 190, 90, 255))
c.detail_ellipse(48, 60, 16, 10, POT_L)  # shine
for x in (66, 114):
    c.detail_ellipse(x, 82, 11, 9, (250, 246, 240, 255))
    c.detail_ellipse(x, 85, 5, 5, INK)
c.detail_line([(52, 66), (76, 74)], INK, 4)  # grumpy brows
c.detail_line([(128, 66), (104, 74)], INK, 4)
c.detail_line([(70, 110), (90, 104), (110, 110)], INK, 4)
c.save(f"{OUT}/sprites/cauldron.png")

c = Canvas(156, 48)  # the cauldron's lid, anchor = centre
c.ellipse(78, 32, 74, 14, POT_L)
c.ellipse(78, 26, 66, 12, POT)
c.rrect(66, 2, 90, 16, 6, POT_L)
c.detail_ellipse(56, 24, 18, 4, (130, 128, 144, 255))
c.save(f"{OUT}/sprites/cauldron_lid.png")

c = Canvas(36, 36)  # a glob of hot callaloo, anchor = centre
c.ellipse(18, 19, 14, 13, (70, 150, 60, 255))
c.detail_ellipse(13, 13, 5, 3, (150, 210, 110, 255))
c.detail_ellipse(22, 22, 3, 3, (40, 100, 40, 255))
c.save(f"{OUT}/sprites/callaloo_blob.png")

c = Canvas(76, 60)  # Brownie, Chad's pothound: facing right, anchor = feet at bottom centre
BROWN, BROWN_L, BROWN_D = (128, 84, 50, 255), (176, 128, 86, 255), (88, 56, 34, 255)
c.poly([(10, 30), (2, 16), (8, 14), (16, 26)], BROWN)  # tail up
for x in (16, 26, 44, 54):
    c.rrect(x, 38, x + 7, 57, 3, BROWN)
c.ellipse(36, 34, 24, 13, BROWN)
c.ellipse(58, 22, 12, 11, BROWN)
c.ellipse(68, 27, 7, 5.5, BROWN_L)
c.poly([(50, 14), (46, 2), (56, 10)], BROWN_D)  # floppy ear
c.detail_ellipse(36, 40, 15, 5, BROWN_L)
c.detail_line([(48, 30), (54, 34), (62, 32)], (220, 50, 50, 255), 3)  # red collar
c.detail_ellipse(55, 36, 2.5, 2.5, BRASS)
c.detail_ellipse(61, 19, 2.4, 2.8, INK)
c.detail_ellipse(74, 25, 2.4, 2.0, INK)
c.detail_line([(66, 31), (70, 33)], (200, 90, 100, 255), 2)  # tongue
c.save(f"{OUT}/sprites/brownie.png")

# Doner Dread, the rival: a fast-food baron in a shiny purple suit, shades and a chef's hat.
c = Canvas(64, 96)
SUIT, SUIT_L = (110, 50, 150, 255), (150, 90, 190, 255)
c.rrect(21, 76, 30, 93, 4, (40, 30, 50, 255))
c.rrect(34, 76, 43, 93, 4, (40, 30, 50, 255))
c.ellipse(15, 66, 6, 6, SKINS[3])
c.ellipse(49, 66, 6, 6, SKINS[3])
c.rrect(16, 52, 48, 82, 10, SUIT)
c.ellipse(32, 40, 18, 17, SKINS[3])
c.rrect(16, 4, 48, 26, 8, (250, 250, 250, 255))  # chef's toque
c.ellipse(24, 8, 9, 8, (250, 250, 250, 255))
c.ellipse(40, 8, 9, 8, (250, 250, 250, 255))
c.detail_line([(20, 37), (44, 37)], INK, 6)  # shades
c.detail_ellipse(26, 37, 5, 4, INK)
c.detail_ellipse(38, 37, 5, 4, INK)
c.detail_line([(27, 49), (32, 51), (39, 47)], INK, 1.8)  # smirk
c.detail_line([(28, 54), (32, 62), (36, 54)], (250, 240, 230, 255), 3)  # shirt
c.detail_line([(24, 58), (32, 66), (40, 58)], BRASS, 2.2)  # big gold chain
c.detail_line([(20, 56), (24, 74)], SUIT_L, 2)
c.save(f"{OUT}/sprites/npc_rival.png")


def _sacred_beni(c):
    for (cx, cy), r in (((24, 30), 0), ((14, 22), -0.5), ((34, 22), 0.5), ((24, 14), 0)):
        c.poly([(cx - 5, cy + 10), (cx, cy - 10), (cx + 5, cy + 10)], (70, 170, 70, 255), outline=2)
    c.detail_line([(24, 44), (24, 26)], (60, 120, 50, 255), 2)
    c.detail_ellipse(24, 8, 4, 4, (255, 240, 150, 255))


icon(f"{OUT}/items/sacred_chadon_beni.png", _sacred_beni)

# ---- app icon -------------------------------------------------------------------------------------
icon = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
ImageDraw.Draw(icon).rounded_rectangle([0, 0, 255, 255], radius=56, fill=(40, 150, 170, 255))
hero = Image.open(f"{OUT}/sprites/hero.png").resize((64 * 3, 84 * 3), Image.LANCZOS)
icon.alpha_composite(hero, (32, 2))
icon.save(f"{OUT}/sprites/icon.png")
print("art generated")
