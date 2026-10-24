"""Painted character sheets (Chad and Evey, option under review): cuts the figures out of the
owner's sheet in art_src/painted/ (flat grey background, outlined figures) and packs them into
game sheets with 128 px frames, adding their layouts to assets/characters/sheets.json.

    uv run --with pillow --with numpy python -I tools/painted_sheets.py

New sheets made with docs/15-character-art-prompts.md: add their rectangles to REGIONS and
their frames to LAYOUTS.
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

# Where each group of figures comes from: (sheet in art_src/painted/, x0, x1, y0, y1), the
# figures in that rectangle read left to right. Chad comes from sheet_v2.jpg, Evey from
# sheet_v3.jpg; earlier drafts (chad_poses.jpg, evey_poses.jpg, cycles.jpg) are kept for
# reference only.
REGIONS = {
    "chad_turn": ("sheet_v2.jpg", 0, 520, 0, 225),  # front, 3/4, side (right), back 3/4, back
    "chad_walk": ("sheet_v2.jpg", 0, 520, 225, 390),  # 7-frame walk, facing right
    "chad_swing": ("sheet_v2.jpg", 0, 520, 390, 572),  # cutlass: front, 3/4 right, back 3/4, back
    "evey_turn": ("sheet_v3.jpg", 510, 1024, 0, 225),  # front, 3/4 right, back 3/4, back
    "evey_walk": ("sheet_v3.jpg", 0, 650, 225, 380),  # 4-frame walk, facing right
    "evey_pounce": ("sheet_v3.jpg", 650, 1024, 225, 380),  # crouch, leap
    "evey_more": ("sheet_v3.jpg", 510, 1024, 380, 572),  # sniff, lunge, happy standing
}
# Groups whose figures stand on a painted floor shadow that gets trapped between the legs.
CLEAR_LOW = ("evey_turn", "evey_walk", "evey_pounce", "evey_more")
# The generator drew each group at its own size; these bring every group to the same character
# size in the game (Chad about 110 px tall in a 128 px frame).
SCALES = {
    "chad_turn": 110 / 208,
    "chad_walk": 106 / 135,
    "chad_swing": 110 / 152,
    "evey_turn": 0.54,
    "evey_walk": 0.54,
    "evey_pounce": 0.54,
    "evey_more": 0.54,
}
# Up-and-down step bob (pixels) for walking towards or away from the camera, which has no
# drawn frames yet.
BOB = [0, -2, -4, -2, 0, -2, -4]


def _bob(ref: str, frames: int) -> list:
    return [(ref, False, BOB[i % len(BOB)]) for i in range(frames)]


def _row(group: str, count: int, mirror: bool) -> list:
    return [(f"{group}:{i}", mirror) for i in range(count)]


# For each animation: rows (one per direction, or one "all") of frames: (figure, mirrored[, dy]).
LAYOUTS = {
    "chad": {
        "idle": {
            "up": [("turn:4", False)] * 2,
            "left": [("turn:2", True)] * 2,
            "down": [("turn:0", False)] * 2,
            "right": [("turn:2", False)] * 2,
        },
        "walk": {
            "up": _bob("turn:4", 7),
            "left": _row("walk", 7, True),
            "down": _bob("turn:0", 7),
            "right": _row("walk", 7, False),
        },
        "slash": {
            "up": [("swing:3", False), ("swing:2", False)],
            "left": [("swing:1", True), ("swing:1", True)],
            "down": [("swing:0", False), ("swing:1", False)],
            "right": [("swing:1", False), ("swing:1", False)],
        },
        "hurt": {"all": [("turn:0", False)]},
    },
    "evey": {
        "idle": {
            "up": [("turn:3", False)] * 2,
            "left": [("more:2", True)] * 2,
            "down": [("turn:0", False)] * 2,
            "right": [("more:2", False)] * 2,
        },
        "walk": {
            "up": _bob("turn:3", 4),
            "left": _row("walk", 4, True),
            "down": _bob("turn:0", 4),
            "right": _row("walk", 4, False),
        },
        "sit": {
            "up": [("turn:3", False)],
            "left": [("turn:1", True)],
            "down": [("turn:0", False)],
            "right": [("turn:1", False)],
        },
        "bite": {
            "up": [("pounce:0", False), ("more:1", False), ("pounce:1", False)],
            "left": [("pounce:0", True), ("more:1", True), ("pounce:1", True)],
            "down": [("pounce:0", False), ("more:1", False), ("pounce:1", False)],
            "right": [("pounce:0", False), ("more:1", False), ("pounce:1", False)],
        },
        "sniff": {
            "up": [("more:0", False)],
            "left": [("more:0", True)],
            "down": [("more:0", False)],
            "right": [("more:0", False)],
        },
    },
}


def background_mask(rgb: np.ndarray) -> np.ndarray:
    """Background and painted shadows: greyish pixels reachable from the edges."""
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    # Neutral or a touch blue, like the backdrop; olive and brown (jackets, fur) are not.
    grey = (np.abs(r - g) < 12) & (np.abs(g - b) < 12) & (b - r >= -5)
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



def _components(mask: np.ndarray) -> tuple[np.ndarray, list]:
    """Label 4-connected blobs: (labels, [(label, size, top, bottom, left, right)])."""
    h, w = mask.shape
    label = np.zeros((h, w), int)
    found = []
    for y0, x0 in zip(*np.nonzero(mask)):
        if label[y0, x0]:
            continue
        n = len(found) + 1
        label[y0, x0] = n
        queue = deque([(y0, x0)])
        top, bottom, left, right, size = y0, y0, x0, x0, 0
        while queue:
            y, x = queue.popleft()
            size += 1
            top, bottom, left, right = min(top, y), max(bottom, y), min(left, x), max(right, x)
            for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not label[ny, nx]:
                    label[ny, nx] = n
                    queue.append((ny, nx))
        found.append((n, size, top, bottom, left, right))
    return label, found


def cut_regions(path: Path, regions: dict, dilate: int = 5, clear_low: tuple = ()) -> dict:
    """Figures laid out in named rectangles of one sheet, {name: (x0, x1, y0, y1)}, each read
    left to right: {name: [frames]}. A figure belongs to the rectangle holding its centre."""
    rgb = np.asarray(Image.open(path).convert("RGB")).astype(int)
    solid = ~background_mask(rgb)
    solid = np.asarray(Image.fromarray((solid * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(3))) > 0
    near = np.asarray(Image.fromarray((solid * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(dilate))) > 0
    label, found = _components(near)
    groups = {}
    for name, (x0, x1, y0, y1) in regions.items():
        figures = sorted(
            (
                c
                for c in found
                if c[1] > 1500 and x0 <= (c[4] + c[5]) // 2 < x1 and y0 <= (c[2] + c[3]) // 2 < y1
            ),
            key=lambda c: c[4],
        )
        groups[name] = [_figure(rgb, solid, label, c, name in clear_low) for c in figures]
    return groups


def _figure(rgb, solid, label, component, clear_low: bool) -> Image.Image:
    n, _size, top, bottom, left, right = component
    keep = (label[top : bottom + 1, left : right + 1] == n) & solid[top : bottom + 1, left : right + 1]
    parts, pieces = _components(keep)
    for m, size, *_ in pieces:
        if size < 300:
            keep[parts == m] = False
    if clear_low:
        patch = rgb[top : bottom + 1, left : right + 1]
        pr, pg, pb = patch[..., 0], patch[..., 1], patch[..., 2]
        shadow = (np.abs(pr - pg) < 12) & (np.abs(pg - pb) < 12) & (patch.max(axis=2) < 80)
        low = np.zeros_like(keep)
        low[int(keep.shape[0] * 0.75) :, :] = True
        keep &= ~(shadow & low)
    ys, xs = np.nonzero(keep)
    rgba = np.dstack(
        [rgb[top : bottom + 1, left : right + 1].astype(np.uint8), (keep * 255).astype(np.uint8)]
    )[ys.min() : ys.max() + 1, xs.min() : xs.max() + 1]
    return Image.fromarray(rgba, "RGBA")


def frame_of(pose: Image.Image, scale: float, mirror: bool, dy: int = 0) -> Image.Image:
    size = (max(1, round(pose.width * scale)), max(1, round(pose.height * scale)))
    img = pose.resize(size, Image.LANCZOS)
    if mirror:
        img = ImageOps.mirror(img)
    cell = Image.new("RGBA", (FRAME, FRAME))
    cell.alpha_composite(img, ((FRAME - img.width) // 2, FRAME - FOOT - img.height + dy))
    return cell


def main() -> None:
    sheets_path = OUT / "sheets.json"
    sheets = json.loads(sheets_path.read_text())
    groups = {}
    for sheet_file in sorted({spec[0] for spec in REGIONS.values()}):
        regions = {name: spec[1:] for name, spec in REGIONS.items() if spec[0] == sheet_file}
        groups.update(cut_regions(SOURCE / sheet_file, regions, dilate=3, clear_low=CLEAR_LOW))
    for name, layout in LAYOUTS.items():
        rows: list[list[Image.Image]] = []
        entry: dict = {"frame": FRAME, "smooth": True}
        for anim, spec in layout.items():
            order = DIRS if "all" not in spec else ["all"]
            entry[anim] = {"row": len(rows), "frames": len(spec[order[0]]), "rows": len(order)}
            for key in order:
                row = []
                for ref, mirror, *dy in spec[key]:
                    group, index = ref.split(":")
                    figure = groups[f"{name}_{group}"][int(index)]
                    row.append(frame_of(figure, SCALES[f"{name}_{group}"], mirror, dy[0] if dy else 0))
                rows.append(row)
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
