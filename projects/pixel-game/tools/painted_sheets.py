"""Painted character sheets (Chad and Evey, option under review): cuts the 4x2 pose sheets in
art_src/painted/ (flat grey background, outlined figures) into transparent poses and packs them
into game sheets with 128 px frames, adding their layouts to assets/characters/sheets.json.

    uv run --with pillow --with numpy python -I tools/painted_sheets.py

Pose sheet layout: row 1 = facing camera, 3/4 view, back, back 3/4; row 2 = walk step 1,
walk step 2, action 1, action 2 (see docs/04-assets.md). cycles.jpg holds side-on motion cycles
(Chad's run, Evey's trot), used for walking left and right.
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

# Motion cycles from art_src/painted/cycles.jpg: Chad's run on top, Evey's trot below. The
# cycle sheet is drawn smaller than the pose sheets, so it has its own scale (matched by eye
# to the same height in the game). Frames are referred to as "cycle:<n>" in LAYOUTS.
CYCLES_SOURCE = "cycles.jpg"
CYCLE_BANDS = {"chad": (0, 245), "evey": (245, 400)}
CYCLE_SCALES = {"chad": 110 / 165, "evey": 0.39 * 200 / 132}

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
            "up": [(2, False), (3, False), (2, False), (3, False)],
            "left": [("cycle:0", True), ("cycle:1", True), ("cycle:2", True), ("cycle:3", True)],
            "down": [(0, False), (1, False), (0, False), (1, False)],
            "right": [("cycle:0", False), ("cycle:1", False), ("cycle:2", False), ("cycle:3", False)],
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
            "up": [(2, False), (3, False), (2, False), (3, False)],
            "left": [("cycle:0", True), ("cycle:1", True), ("cycle:2", True), ("cycle:3", True)],
            "down": [("cycle:0", False), ("cycle:1", False), ("cycle:2", False), ("cycle:3", False)],
            "right": [("cycle:0", False), ("cycle:1", False), ("cycle:2", False), ("cycle:3", False)],
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


def cut_cycles(path: Path, bands: dict, clear_low: tuple = ()) -> dict:
    """Animation strips laid out left to right in horizontal bands (e.g. a run cycle on top, a
    trot below): {band: [frames left to right]}. Pieces close together (a head, a strap) are
    kept with their figure; small marks (frame numbers, arrows) are dropped. For bands in
    `clear_low`, shadow-grey pixels in the bottom quarter of each frame are cleared too (painted
    shadow trapped between legs, which the flood fill can't reach)."""
    rgb = np.asarray(Image.open(path).convert("RGB")).astype(int)
    solid = ~background_mask(rgb)
    solid = np.asarray(Image.fromarray((solid * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(3))) > 0
    near = np.asarray(Image.fromarray((solid * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(9))) > 0
    label, found = _components(near)
    strips = {}
    for band, (y0, y1) in bands.items():
        figures = sorted(
            (c for c in found if c[1] > 4000 and y0 <= (c[2] + c[3]) // 2 < y1), key=lambda c: c[4]
        )
        frames = []
        for n, _size, top, bottom, left, right in figures:
            keep = (label[top : bottom + 1, left : right + 1] == n) & solid[top : bottom + 1, left : right + 1]
            # Drop small loose marks (arrows, speed lines) that sit near the figure.
            parts, pieces = _components(keep)
            for m, size, *_ in pieces:
                if size < 400:
                    keep[parts == m] = False
            if band in clear_low:
                patch = rgb[top : bottom + 1, left : right + 1]
                pr, pg, pb = patch[..., 0], patch[..., 1], patch[..., 2]
                shadow = (np.abs(pr - pg) < 12) & (np.abs(pg - pb) < 12) & (patch.max(axis=2) < 80)
                low = np.zeros_like(keep)
                low[int(keep.shape[0] * 0.75) :, :] = True
                keep &= ~(shadow & low)
            ys, xs = np.nonzero(keep)
            box = (ys.min(), ys.max() + 1, xs.min(), xs.max() + 1)
            rgba = np.dstack(
                [rgb[top : bottom + 1, left : right + 1].astype(np.uint8), (keep * 255).astype(np.uint8)]
            )[box[0] : box[1], box[2] : box[3]]
            frames.append(Image.fromarray(rgba, "RGBA"))
        strips[band] = frames
    return strips


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
    cycles = cut_cycles(SOURCE / CYCLES_SOURCE, CYCLE_BANDS, clear_low=("evey",))
    for name, layout in LAYOUTS.items():
        poses = cut_poses(SOURCE / f"{name}_poses.jpg")

        def cell(ref, mirror, name=name, poses=poses):
            if isinstance(ref, str):
                return frame_of(cycles[name][int(ref.split(":")[1])], CYCLE_SCALES[name], mirror)
            return frame_of(poses[ref], SCALES[name], mirror)

        rows: list[list[Image.Image]] = []
        entry: dict = {"frame": FRAME, "smooth": True}
        for anim, spec in layout.items():
            order = DIRS if "all" not in spec else ["all"]
            entry[anim] = {"row": len(rows), "frames": len(spec[order[0]]), "rows": len(order)}
            for key in order:
                rows.append([cell(p, m) for p, m in spec[key]])
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
