"""Pixel icons for Chad's weapons (assets/items/<id>.png, 48x48 = 24 art pixels at 2x).

    uv run --with pillow python -I tools/weapon_icons.py

Drawn by hand in code, on the 2x pixel grid with a dark outline, in the game's palette.
Placeholders until real pixel art replaces them at the same size.
"""

from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "assets" / "items"
N = 24
OUTLINE = (34, 22, 30, 255)


def canvas():
    return Image.new("RGBA", (N, N), (0, 0, 0, 0))


def line(img, a, b, colour, width=1):
    (x0, y0), (x1, y1) = a, b
    steps = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in range(steps + 1):
        x = round(x0 + (x1 - x0) * i / steps)
        y = round(y0 + (y1 - y0) * i / steps)
        for dx in range(width):
            for dy in range(width):
                if 0 <= x + dx < N and 0 <= y + dy < N:
                    img.putpixel((x + dx, y + dy), colour)


def outline(img):
    px = img.load()
    solid = {(x, y) for y in range(N) for x in range(N) if px[x, y][3] > 0}
    for x, y in solid:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < N and 0 <= ny < N and (nx, ny) not in solid:
                px[nx, ny] = OUTLINE
    return img


def save(img, name):
    outline(img).resize((N * 2, N * 2), Image.NEAREST).save(OUT / f"{name}.png")


def cutlass():
    img = canvas()
    line(img, (5, 18), (8, 15), (107, 63, 34, 255), 2)  # handle
    line(img, (8, 16), (10, 14), (201, 160, 60, 255), 1)  # guard
    line(img, (9, 14), (19, 4), (238, 242, 251, 255), 2)  # blade
    line(img, (10, 15), (20, 5), (154, 166, 191, 255), 1)  # edge
    return img


def branch():
    img = canvas()
    line(img, (4, 19), (19, 4), (122, 82, 48, 255), 2)
    line(img, (12, 11), (15, 15), (122, 82, 48, 255), 1)
    line(img, (15, 15), (17, 16), (70, 130, 60, 255), 2)
    line(img, (18, 5), (20, 3), (70, 130, 60, 255), 2)
    return img


def plank():
    img = canvas()
    line(img, (5, 19), (18, 6), (160, 120, 80, 255), 4)
    line(img, (6, 18), (19, 5), (94, 65, 38, 255), 1)
    img.putpixel((11, 12), (60, 60, 66, 255))  # a nail
    return img


def cricket_bat():
    img = canvas()
    line(img, (4, 20), (8, 16), (58, 42, 28, 255), 2)  # grip
    line(img, (8, 15), (18, 5), (232, 214, 168, 255), 4)  # blade
    line(img, (9, 17), (19, 7), (168, 141, 85, 255), 1)
    return img


def fishing_spear():
    img = canvas()
    line(img, (3, 21), (17, 7), (138, 106, 68, 255), 1)
    line(img, (17, 7), (21, 3), (201, 206, 216, 255), 1)
    line(img, (18, 4), (20, 6), (201, 206, 216, 255), 1)
    line(img, (16, 5), (18, 3), (201, 206, 216, 255), 1)
    return img


def fists():
    img = canvas()
    skin, dark = (122, 74, 48, 255), (74, 42, 26, 255)
    for x in range(8, 17):
        for y in range(9, 17):
            img.putpixel((x, y), skin)
    for x in (10, 12, 14):
        line(img, (x, 9), (x, 12), dark)
    line(img, (8, 17), (16, 17), (74, 106, 48, 255), 2)  # jacket cuff
    return img


if __name__ == "__main__":
    for name, draw in [
        ("cutlass", cutlass),
        ("branch", branch),
        ("plank", plank),
        ("cricket_bat", cricket_bat),
        ("fishing_spear", fishing_spear),
        ("fists", fists),
    ]:
        save(draw(), name)
    print("weapon icons written")
