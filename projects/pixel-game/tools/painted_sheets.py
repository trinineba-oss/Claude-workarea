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
# Mirrored animations are drawn facing right only: rows for up, side and down. The game flips
# the side and down rows when the character last moved left.
MIRROR_DIRS = ["up", "side", "down"]

# Where each group of figures comes from: (sheet in art_src/painted/, x0, x1, y0, y1, strict),
# the figures in that rectangle read left to right. `strict` uses the tighter backdrop test that
# keeps dark clothes and strips painted floor shadows. Chad and Evey come from sheet_v4.jpg,
# with the cutlass swing and Evey's front and back views from sheet_v3.jpg; earlier drafts
# (chad_poses.jpg, evey_poses.jpg, cycles.jpg, sheet_v2.jpg) are kept for reference only.
REGIONS = {
    # front idle, 3/4 walk x3, back walk x4
    "chad_a": ("sheet_v4.jpg", 0, 1024, 0, 215, True),
    # back walk x3, side x3, 3/4 walk, 3/4 standing
    "chad_b": ("sheet_v4.jpg", 0, 1024, 215, 365, True),
    # cutlass: front, lunge, raised, back
    "chad_swing": ("sheet_v3.jpg", 0, 510, 380, 572, True),
    # trot x6, gallop x2
    "evey_run": ("sheet_v4.jpg", 0, 1024, 365, 462, True),
    # sniff, dig x2, sniff, crouch, lunge, bark, happy standing
    "evey_act": ("sheet_v4.jpg", 0, 1024, 462, 572, True),
    # front, 3/4 right, back 3/4, back
    "evey_turn": ("sheet_v3.jpg", 510, 1024, 0, 225, True),
}
# The colour of each sheet's painted floor shadows, for telling them from dark clothes.
SHADOW_TINT = {"sheet_v3.jpg": "neutral", "sheet_v4.jpg": "warm"}
# The generator drew each group at its own size; these bring every group to the same character
# size in the game (Chad about 110 px tall in a 128 px frame, Evey about 60).
SCALES = {
    "chad_a": 110 / 165,
    "chad_b": 110 / 134,
    "chad_swing": 110 / 166,
    "evey_run": 0.72,
    "evey_act": 0.72,
    "evey_turn": 0.5,
}
# Up-and-down step bob (pixels) for a pose with no drawn walk frames.
BOB = [0, -2, -4, -2, 0, -2, -4]


def _bob(ref: str, frames: int) -> list:
    return [(ref, False, BOB[i % len(BOB)]) for i in range(frames)]


def _frames(group: str, indices) -> list:
    return [(f"{group}:{i}", False) for i in indices]


# For each animation: rows of frames, (figure, mirrored[, dy]). Rows are keyed up/side/down
# (drawn facing right, flipped by the game for left) or up/left/down/right, or "all".
LAYOUTS = {
    "chad": {
        "idle": {
            "up": _frames("b", [1]),
            "side": _frames("b", [7]),
            "down": _frames("a", [0]),
        },
        "walk": {
            "up": _frames("a", [4, 5, 6, 7]) + _frames("b", [0, 1, 2]),
            "side": _frames("a", [1, 2, 3]) + _frames("b", [6]),
            "down": _frames("a", [1, 2, 3]) + _frames("b", [6]),
        },
        "slash": {
            "up": _frames("swing", [3, 3]),
            "side": _frames("swing", [2, 1]),
            "down": _frames("swing", [0, 1]),
        },
        "hurt": {"all": _frames("a", [0])},
    },
    "evey": {
        "idle": {
            "up": _frames("turn", [3]),
            "side": _frames("act", [7]),
            "down": _frames("turn", [0]),
        },
        "walk": {
            "up": _bob("turn:3", 6),
            "side": _frames("run", range(6)),
            "down": _bob("turn:0", 6),
        },
        "run": {
            "up": _bob("turn:3", 4),
            "side": _frames("run", [4, 5, 6, 7]),
            "down": _bob("turn:0", 4),
        },
        "sit": {
            "up": _frames("turn", [3]),
            "side": _frames("turn", [1]),
            "down": _frames("turn", [0]),
        },
        "bite": {
            "up": _frames("act", [4, 5, 6]),
            "side": _frames("act", [4, 5, 6]),
            "down": _frames("act", [4, 5, 6]),
        },
        "sniff": {
            "up": _frames("act", [0, 3]),
            "side": _frames("act", [0, 3]),
            "down": _frames("act", [0, 3]),
        },
        "dig": {
            "up": _frames("act", [1, 2]),
            "side": _frames("act", [1, 2]),
            "down": _frames("act", [1, 2]),
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



def backdrop_mask(rgb: np.ndarray, tolerance: float = 9.0) -> np.ndarray:
    """A stricter backdrop test for sheets whose dark clothes are close to the backdrop grey:
    only pixels within `tolerance` of the backdrop colour (the median of the image border),
    reachable from the edges."""
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
    backdrop = np.median(border, axis=0)
    passable = np.sqrt(((rgb - backdrop) ** 2).sum(axis=2)) < tolerance
    return _flood_from_edges(passable)


def _flood_from_edges(passable: np.ndarray) -> np.ndarray:
    h, w = passable.shape
    seen = np.zeros_like(passable)
    queue = deque()
    for y in range(h):
        for x in range(w):
            if (y in (0, h - 1) or x in (0, w - 1)) and passable[y, x]:
                seen[y, x] = True
                queue.append((y, x))
    while queue:
        y, x = queue.popleft()
        for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
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


def cut_regions(
    path: Path,
    regions: dict,
    dilate: int = 5,
    clear_low: tuple = (),
    strict: bool = False,
    shadow_tint: str = "warm",
) -> dict:
    """Figures laid out in named rectangles of one sheet, {name: (x0, x1, y0, y1)}, each read
    left to right: {name: [frames]}. A figure belongs to the rectangle holding its centre.
    `strict` uses the tighter backdrop test and strips painted floor shadows."""
    rgb = np.asarray(Image.open(path).convert("RGB")).astype(int)
    solid = ~(backdrop_mask(rgb) if strict else background_mask(rgb))
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
        groups[name] = [
            _figure(rgb, solid, label, c, name in clear_low, strict, shadow_tint) for c in figures
        ]
    return groups


def _floor_shadows(patch: np.ndarray, keep: np.ndarray, tint: str = "warm") -> np.ndarray:
    """A painted floor shadow under a figure: colourless grey in the bottom of its box that
    joins the empty space around it. The ink outline walls the figure off, so boots and dark
    trousers are safe. `tint` is the shadow's grey on that sheet: "warm" (sheet_v4, where dark
    trousers lean blue) or "neutral" (sheet_v3); either way shadows are mid-grey, trousers darker."""
    value = patch.max(axis=2)
    spread = value - patch.min(axis=2)
    if tint == "warm":
        hue = patch[..., 2] <= patch[..., 0] - 1
    else:
        hue = np.abs(patch[..., 2] - patch[..., 0]) <= 5
    shadowy = (spread < 20) & hue & (value >= 44) & (value <= 72)
    top = int(keep.shape[0] * 0.8)
    band = np.zeros_like(keep)
    band[top:, :] = True
    # Boots are the shadow's colour too, but their soles are inked: only grey below the lowest
    # ink in each column can be shadow.
    ink = value < 30
    below_ink = np.zeros_like(keep)
    for x in range(keep.shape[1]):
        inked = np.nonzero(ink[top:, x] & keep[top:, x])[0]
        below_ink[top + (inked.max() + 1 if len(inked) else 0) :, x] = True
    return _flood_from_edges(band & ((shadowy & below_ink) | ~keep)) & keep


def _figure(
    rgb, solid, label, component, clear_low: bool, floor_shadow: bool = False, tint: str = "warm"
) -> Image.Image:
    n, _size, top, bottom, left, right = component
    keep = (label[top : bottom + 1, left : right + 1] == n) & solid[top : bottom + 1, left : right + 1]
    shadow = np.zeros_like(keep)
    if floor_shadow:
        shadow = _floor_shadows(rgb[top : bottom + 1, left : right + 1], keep, tint)
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
    patch = rgb[top : bottom + 1, left : right + 1].astype(float)
    alpha = keep * 255.0
    colour = patch.copy()
    if shadow.any():
        # The painted floor shadow becomes a real, see-through one: dark, as strong as it was
        # darker than the backdrop.
        backdrop = float(np.median(np.concatenate([rgb[0], rgb[-1]]).max(axis=1)))
        darkness = np.clip((backdrop - patch.max(axis=2)) / backdrop, 0.0, 1.0)
        alpha = np.where(shadow, np.clip(darkness * 1.6, 0.0, 0.6) * 255.0, alpha)
        colour[shadow] = (24, 18, 12)
    ys, xs = np.nonzero(alpha > 8)
    rgba = np.dstack([colour.astype(np.uint8), alpha.astype(np.uint8)])
    return Image.fromarray(rgba[ys.min() : ys.max() + 1, xs.min() : xs.max() + 1], "RGBA")


def frame_of(pose: Image.Image, scale: float, mirror: bool, dy: int = 0) -> Image.Image:
    """One frame: the figure scaled, feet on the baseline, and centred on its mass (not its box),
    so swinging arms and legs don't shift the body from frame to frame."""
    size = (max(1, round(pose.width * scale)), max(1, round(pose.height * scale)))
    img = pose.resize(size, Image.LANCZOS)
    if mirror:
        img = ImageOps.mirror(img)
    alpha = np.asarray(img)[..., 3].astype(float)
    centre = (alpha.sum(axis=0) * np.arange(img.width)).sum() / max(alpha.sum(), 1.0)
    cell = Image.new("RGBA", (FRAME, FRAME))
    cell.alpha_composite(img, (round(FRAME / 2 - centre), FRAME - FOOT - img.height + dy))
    return cell


def main() -> None:
    sheets_path = OUT / "sheets.json"
    sheets = json.loads(sheets_path.read_text())
    groups = {}
    for sheet_file in sorted({spec[0] for spec in REGIONS.values()}):
        for strict in (False, True):
            regions = {
                name: spec[1:5]
                for name, spec in REGIONS.items()
                if spec[0] == sheet_file and spec[5] == strict
            }
            if regions:
                tint = SHADOW_TINT.get(sheet_file, "warm")
                groups.update(
                    cut_regions(
                        SOURCE / sheet_file, regions, dilate=3, strict=strict, shadow_tint=tint
                    )
                )
    for name, layout in LAYOUTS.items():
        rows: list[list[Image.Image]] = []
        entry: dict = {"frame": FRAME, "smooth": True}
        for anim, spec in layout.items():
            order = MIRROR_DIRS if "side" in spec else (["all"] if "all" in spec else DIRS)
            counts = [len(spec[key]) for key in order]
            entry[anim] = {"row": len(rows), "frames": max(counts), "rows": len(order)}
            if "side" in spec:
                entry[anim]["mirror"] = True
            if len(set(counts)) > 1:
                entry[anim]["counts"] = counts
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
