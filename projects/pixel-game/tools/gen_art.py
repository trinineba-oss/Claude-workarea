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

# ---- hero: 64x84, anchor = feet at bottom centre ---------------------------------------------
c = Canvas(64, 84)
SKIN, SHIRT, PANTS, CAP = (244, 198, 152, 255), (64, 112, 214, 255), (52, 58, 86, 255), (214, 58, 58, 255)
c.rrect(21, 66, 30, 81, 4, PANTS)
c.rrect(34, 66, 43, 81, 4, PANTS)
c.ellipse(16, 56, 6, 6, SKIN)
c.ellipse(48, 56, 6, 6, SKIN)
c.rrect(18, 42, 46, 72, 10, SHIRT)
c.ellipse(32, 28, 20, 19, SKIN)
c.poly([(12, 26), (14, 12), (24, 5), (40, 5), (50, 12), (52, 26)], CAP)
c.rrect(10, 22, 54, 28, 3, (190, 44, 44, 255))
c.detail_ellipse(25, 34, 2.6, 3.4, INK)
c.detail_ellipse(39, 34, 2.6, 3.4, INK)
c.detail_ellipse(21, 40, 3.4, 2.0, (240, 150, 140, 200))
c.detail_ellipse(43, 40, 3.4, 2.0, (240, 150, 140, 200))
c.detail_line([(28, 43), (32, 45), (36, 43)], INK, 1.6)
c.detail_ellipse(26, 9, 6, 2.5, (240, 110, 110, 255))
c.detail_line([(22, 50), (22, 64)], (90, 140, 230, 255), 2.5)
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

# ---- app icon -------------------------------------------------------------------------------------
icon = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
ImageDraw.Draw(icon).rounded_rectangle([0, 0, 255, 255], radius=56, fill=(40, 150, 170, 255))
hero = Image.open(f"{OUT}/sprites/hero.png").resize((64 * 3, 84 * 3), Image.LANCZOS)
icon.alpha_composite(hero, (32, 2))
icon.save(f"{OUT}/sprites/icon.png")
print("art generated")
