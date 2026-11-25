"""Pixel pass (pixel-2d branch): redraws the placeholder art on the 2x pixel grid.

    uv run --with pillow --with numpy python -I tools/pixelate.py

Every PNG in assets/sprites, assets/items and assets/textures is shrunk to half size (one art
pixel per 2x2 screen pixels), its colours snapped to one shared palette (made from all the
art, so everything matches), its edges made hard (no half-transparent pixels), given a dark
outline where it meets transparency, and blown back up 2x with hard pixels. The files keep
their size and anchor, so nothing in the game moves. Run it after tools/gen_art.py; running
it twice changes nothing.

Real pixel art replaces these files later at the same size.
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
FOLDERS = ["assets/sprites", "assets/items", "assets/textures"]
# Textures that are data, not pictures.
SKIP = {"noise.png"}
GRID = 2
COLOURS = 48
OUTLINE = (34, 22, 30)


def art_files():
    for folder in FOLDERS:
        for path in sorted((ROOT / folder).glob("*.png")):
            if path.name not in SKIP:
                yield path


def shrink(image: Image.Image) -> Image.Image:
    w, h = image.size
    return image.resize((max(1, w // GRID), max(1, h // GRID)), Image.BOX)


def build_palette(images) -> Image.Image:
    """One palette for all the art: a median cut over a sample of every opaque pixel."""
    samples = []
    for image in images:
        a = np.asarray(image)
        opaque = a[a[..., 3] > 128][:, :3]
        if len(opaque):
            step = max(1, len(opaque) // 4000)
            samples.append(opaque[::step])
    pixels = np.concatenate(samples)
    side = int(np.ceil(np.sqrt(len(pixels))))
    canvas = np.zeros((side * side, 3), np.uint8)
    canvas[: len(pixels)] = pixels
    canvas[len(pixels) :] = pixels[0]
    sample = Image.fromarray(canvas.reshape(side, side, 3), "RGB")
    return sample.quantize(COLOURS, method=Image.Quantize.MEDIANCUT)


def pixelate(image: Image.Image, palette: Image.Image, outline: bool) -> Image.Image:
    small = shrink(image)
    a = np.asarray(small).copy()
    alpha = a[..., 3] > 110
    rgb = Image.fromarray(a[..., :3], "RGB").quantize(palette=palette, dither=Image.Dither.NONE)
    out = np.asarray(rgb.convert("RGB")).copy()
    result = np.zeros_like(a)
    result[..., :3] = out
    result[..., 3] = np.where(alpha, 255, 0)
    if outline and not alpha.all():
        # Dark pixels just outside the shape (4-neighbours), like hand-drawn sprite outlines.
        # Only next to light pixels: where the art already has a dark rim, none is added
        # (so a second run adds nothing).
        light = alpha & (out.max(axis=2) > 70)
        edge = np.zeros_like(alpha)
        edge[1:, :] |= light[:-1, :]
        edge[:-1, :] |= light[1:, :]
        edge[:, 1:] |= light[:, :-1]
        edge[:, :-1] |= light[:, 1:]
        edge &= ~alpha
        result[edge] = (*OUTLINE, 255)
    big = Image.fromarray(result, "RGBA").resize(
        (small.width * GRID, small.height * GRID), Image.NEAREST
    )
    canvas = Image.new("RGBA", image.size, (0, 0, 0, 0))
    canvas.paste(big, (0, 0))
    return canvas


def main() -> None:
    paths = list(art_files())
    images = {p: Image.open(p).convert("RGBA") for p in paths}
    palette = build_palette([shrink(i) for i in images.values()])
    for path, image in images.items():
        textured = path.parent.name == "textures"
        result = pixelate(image, palette, outline=not textured)
        result.save(path)
    print(f"pixelated {len(paths)} images with a {COLOURS}-colour palette", file=sys.stderr)


if __name__ == "__main__":
    main()
