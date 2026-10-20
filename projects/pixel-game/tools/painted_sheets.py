"""Painted character sheets (Chad and Evey, option under review): cuts the 4x2 pose sheets in
art_src/painted/ (flat grey background, outlined figures) into transparent poses and packs them
into game sheets with 128 px frames, adding their layouts to assets/characters/sheets.json.

    uv run --with pillow --with numpy python -I tools/painted_sheets.py

Pose sheet layout: row 1 = facing camera, 3/4 view, back, back 3/4; row 2 = walk step 1,
walk step 2, action 1, action 2 (see docs/04-assets.md).
"""

import json
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter, ImageOps

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "art_src" / "painted"
OUT = ROOT / "assets" / "characters"

FRAME = 128
FOOT = 8  # feet sit this many pixels above the bottom of a frame
DIRS = ["up", "left", "down", "right"]

# Height of a pose -> height in the frame (keeps the cast at the same size as the LPC sheets).
SCALES = {"chad": 110 / 227, "evey": 0.39}

# For each animation: rows (one per direction, or one) of [pose, mirrored] frames.
LAYOUTS = {
    "chad": {
        "idle": {
            "up": [(2, False), (3, False)],
            "left": [(1, False), (1, False)],
            "down": [(0, False), (0, False)],
            "right": [(1, True), (1, True)],
        },
        "walk": {
            "up": [(2, False), (3, False)],
            "left": [(4, True), (5, True)],
            "down": [(0, False), (1, False)],
            "right": [(4, False), (5, False)],
        },
        "slash": {"all": [(6, False), (7, False)]},
        "hurt": {"all": [(6, False)]},
    },
    "evey": {
        "idle": {
            "up": [(2, False), (3, False)],
            "left": [(0, True), (1, True)],
            "down": [(0, False), (1, False)],
            "right": [(0, False), (1, False)],
        },
        "walk": {
            "up": [(2, False), (3, False)],
            "left": [(4, True), (5, True)],
            "down": [(4, False), (5, False)],
            "right": [(4, False), (5, False)],
        },
        "sit": {
            "up": [(6, False)],
            "left": [(6, True)],
            "down": [(6, False)],
            "right": [(6, False)],
        },
        "bite": {
            "up": [(7, False)],
            "left": [(7, False)],
            "down": [(7, False)],
            "right": [(7, True)],
        },
    },
}




def background_mask(rgb: np.ndarray) -> np.ndarray:
    """Background and painted shadows: greyish pixels reachable from the edges."""
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    grey = (np.abs(r - g) < 14) & (np.abs(g - b) < 14) & (np.abs(r - b) < 16)
    passable = grey & (rgb.max(axis=2) >= 30) & (rgb.max(axis=2) <= 105)
    h, w = passable.shape
    seen = np.zeros_like(passable)
    queue = deque()
    for x in range(w):
        for y in (0, h - 1):
            if passable[y, x]:
                seen[y, x] = True
                queue.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if passable[y, x] and not seen[y, x]:
                seen[y, x] = True
                queue.append((y, x))
    while queue:
        y, x = queue.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and passable[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = True
                queue.append((ny, nx))
    return seen



def cut_poses(path: Path) -> list[Image.Image]:
    """The eight figures of a 4x2 pose sheet, each cropped, on transparency."""
    rgb = np.asarray(Image.open(path).convert("RGB")).astype(int)
    alpha = np.where(background_mask(rgb), 0, 255).astype(np.uint8)
    # Pull the cut edge in by a pixel so JPEG fringes don't show.
    alpha = np.asarray(Image.fromarray(alpha).filter(ImageFilter.MinFilter(3)))
    rgba = np.dstack([rgb.astype(np.uint8), alpha])
    h, w = alpha.shape
    cw, ch = w // 4, h // 2
    poses = []
    for i in range(8):
        cx, cy = (i % 4) * cw, (i // 4) * ch
        cell = rgba[cy : cy + ch, cx : cx + cw]
        ys, xs = np.nonzero(cell[..., 3])
        poses.append(Image.fromarray(cell[ys.min() : ys.max() + 1, xs.min() : xs.max() + 1], "RGBA"))
    return poses


def frame_of(pose: Image.Image, scale: float, mirror: bool) -> Image.Image:
    size = (max(1, round(pose.width * scale)), max(1, round(pose.height * scale)))
    img = pose.resize(size, Image.LANCZOS)
    if mirror:
        img = ImageOps.mirror(img)
    cell = Image.new("RGBA", (FRAME, FRAME))
    cell.alpha_composite(img, ((FRAME - img.width) // 2, FRAME - FOOT - img.height))
    return cell


def main() -> None:
    sheets_path = OUT / "sheets.json"
    sheets = json.loads(sheets_path.read_text())
    for name, layout in LAYOUTS.items():
        poses = cut_poses(SOURCE / f"{name}_poses.jpg")
        rows: list[list[Image.Image]] = []
        entry: dict = {"frame": FRAME, "smooth": True}
        for anim, spec in layout.items():
            order = DIRS if "all" not in spec else ["all"]
            entry[anim] = {"row": len(rows), "frames": len(spec[order[0]]), "rows": len(order)}
            for key in order:
                rows.append([frame_of(poses[p], SCALES[name], m) for p, m in spec[key]])
        cols = max(len(r) for r in rows)
        sheet = Image.new("RGBA", (cols * FRAME, len(rows) * FRAME))
        for y, row in enumerate(rows):
            for x, cell in enumerate(row):
                sheet.alpha_composite(cell, (x * FRAME, y * FRAME))
        sheet.save(OUT / f"{name}_painted.png")
        sheets["characters"][f"{name}_painted"] = entry
        print(f"{name}_painted.png", sheet.size)
    sheets_path.write_text(json.dumps(sheets, indent=2) + "\n")


if __name__ == "__main__":
    main()
