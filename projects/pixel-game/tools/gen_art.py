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

# ---- app icon -------------------------------------------------------------------------------------
icon = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
ImageDraw.Draw(icon).rounded_rectangle([0, 0, 255, 255], radius=56, fill=(40, 150, 170, 255))
hero = Image.open(f"{OUT}/sprites/hero.png").resize((64 * 3, 84 * 3), Image.LANCZOS)
icon.alpha_composite(hero, (32, 2))
icon.save(f"{OUT}/sprites/icon.png")
print("art generated")
