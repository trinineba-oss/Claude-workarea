"""Stand-in painted ground textures for the illustrated-look trial (the beach): tileable 512 px
squares with soft colour blotches, brush dabs and a few inked pebbles, shells, blades and
cracks. Real painted textures replace them at the same paths (assets/illustrated/ground/).

    uv run --with pillow --with numpy python -I tools/illustrated_placeholders.py
"""

import math
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SIZE = 512
OUT = Path(__file__).resolve().parent.parent / "assets" / "illustrated" / "ground"
INK = (40, 28, 20)


def tileable_noise(rng: random.Random, waves: int, max_freq: int) -> np.ndarray:
    """Smooth noise in -1..1 that wraps around (a sum of whole-period waves)."""
    y, x = np.mgrid[0:SIZE, 0:SIZE] / SIZE
    total = np.zeros((SIZE, SIZE))
    for _ in range(waves):
        fx, fy = rng.randint(1, max_freq), rng.randint(0, max_freq)
        phase = rng.uniform(0, math.tau)
        total += math.cos(phase) * np.sin(math.tau * (fx * x + fy * y) + phase)
    return total / max(np.abs(total).max(), 1e-6)


def base(rng: random.Random, colour: tuple, spread: float) -> Image.Image:
    noise = tileable_noise(rng, 14, 4) * 0.6 + tileable_noise(rng, 20, 9) * 0.4
    rgb = np.array(colour, float)[None, None, :] * (1.0 + noise[..., None] * spread)
    return Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB").convert("RGBA")


def wrapped(draw_fn) -> None:
    """Draw a shape at all nine wrap-around offsets so it tiles."""
    for ox in (-SIZE, 0, SIZE):
        for oy in (-SIZE, 0, SIZE):
            draw_fn(ox, oy)


def dab(draw: ImageDraw.ImageDraw, cx, cy, length, width, angle, fill) -> None:
    ca, sa = math.cos(angle), math.sin(angle)
    points = []
    for i in range(14):
        t = math.tau * i / 14
        px, py = math.cos(t) * length / 2, math.sin(t) * width / 2
        points.append((px * ca - py * sa, px * sa + py * ca))
    wrapped(lambda ox, oy: draw.polygon([(cx + ox + px, cy + oy + py) for px, py in points], fill=fill))


def vary(colour, rng, amount):
    """The same colour, lighter or darker (never a different hue)."""
    k = rng.uniform(1 - amount, 1 + amount)
    return tuple(int(max(0, min(255, c * k))) for c in colour)


def dabs(img, rng, colour, count, size, alpha, amount=0.12, angle=None) -> None:
    draw = ImageDraw.Draw(img, "RGBA")
    for _ in range(count):
        a = angle if angle is not None else rng.uniform(0, math.pi)
        a += rng.uniform(-0.25, 0.25)
        length = rng.uniform(size * 0.6, size * 1.4)
        dab(draw, rng.uniform(0, SIZE), rng.uniform(0, SIZE), length, length * rng.uniform(0.25, 0.45),
            a, vary(colour, rng, amount) + (alpha,))


def pebbles(img, rng, colour, count, size) -> None:
    draw = ImageDraw.Draw(img, "RGBA")
    for _ in range(count):
        cx, cy = rng.uniform(0, SIZE), rng.uniform(0, SIZE)
        r = rng.uniform(size * 0.5, size)
        fill = vary(colour, rng, 0.15) + (255,)
        wrapped(lambda ox, oy: draw.ellipse(
            (cx + ox - r - 1.5, cy + oy - r * 0.75 - 1.5, cx + ox + r + 1.5, cy + oy + r * 0.75 + 1.5),
            fill=INK + (200,)))
        wrapped(lambda ox, oy: draw.ellipse(
            (cx + ox - r, cy + oy - r * 0.75, cx + ox + r, cy + oy + r * 0.75), fill=fill))
        wrapped(lambda ox, oy: draw.ellipse(
            (cx + ox - r * 0.5, cy + oy - r * 0.6, cx + ox + r * 0.1, cy + oy - r * 0.1),
            fill=(255, 255, 255, 70)))


def lines(img, rng, colour, count, length, width, alpha, wiggle=0.6, upward=False) -> None:
    draw = ImageDraw.Draw(img, "RGBA")
    for _ in range(count):
        x, y = rng.uniform(0, SIZE), rng.uniform(0, SIZE)
        if upward:
            angle = -math.pi / 2 + rng.uniform(-0.5, 0.5)
        elif wiggle < 0.3:
            angle = rng.uniform(-0.15, 0.15)  # nearly level, like wave crests
        else:
            angle = rng.uniform(0, math.tau)
        points = [(x, y)]
        steps = rng.randint(2, 4)
        for _ in range(steps):
            angle += rng.uniform(-wiggle, wiggle) * (0.4 if upward else 1)
            x += math.cos(angle) * length / steps
            y += math.sin(angle) * length / steps
            points.append((x, y))
        fill = vary(colour, rng, 0.1) + (alpha,)
        wrapped(lambda ox, oy: draw.line([(px + ox, py + oy) for px, py in points], fill=fill, width=width))


def finish(img: Image.Image, name: str) -> None:
    img = img.filter(ImageFilter.GaussianBlur(1.4)).convert("RGB")
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / f"{name}.png")
    print(name)


def sand(rng):
    img = base(rng, (238, 212, 160), 0.06)
    dabs(img, rng, (246, 224, 180), 110, 60, 45, 0.04)
    dabs(img, rng, (222, 192, 140), 90, 50, 40, 0.04)
    dabs(img, rng, (255, 242, 212), 70, 22, 60, 0.03)
    pebbles(img, rng, (196, 170, 140), 3, 7)
    pebbles(img, rng, (250, 236, 222), 2, 5)  # shell bits
    finish(img, "sand")


def water(rng):
    img = base(rng, (64, 160, 182), 0.1)
    dabs(img, rng, (48, 134, 166), 90, 90, 50, 0.05, angle=0.0)
    dabs(img, rng, (104, 196, 206), 80, 70, 45, 0.05, angle=0.0)
    lines(img, rng, (225, 248, 250), 26, 40, 3, 130, wiggle=0.2)
    finish(img, "water")


def grass(rng):
    img = base(rng, (112, 168, 72), 0.08)
    dabs(img, rng, (94, 148, 60), 120, 50, 50, 0.05)
    dabs(img, rng, (140, 190, 88), 100, 40, 50, 0.05)
    lines(img, rng, (62, 112, 46), 300, 14, 2, 130, upward=True)
    lines(img, rng, (178, 216, 116), 160, 10, 2, 120, upward=True)
    finish(img, "grass")


def dirt(rng):
    img = base(rng, (204, 162, 108), 0.07)
    dabs(img, rng, (220, 182, 128), 100, 56, 45, 0.04)
    dabs(img, rng, (182, 138, 88), 80, 46, 40, 0.04)
    lines(img, rng, (110, 76, 46), 14, 60, 2, 170, wiggle=0.9)
    pebbles(img, rng, (168, 150, 130), 4, 6)
    finish(img, "dirt")


def main() -> None:
    for i, make in enumerate((sand, water, grass, dirt)):
        make(random.Random(100 + i))


if __name__ == "__main__":
    main()
