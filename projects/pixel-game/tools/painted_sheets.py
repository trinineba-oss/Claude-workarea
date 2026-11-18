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
# keeps dark clothes and strips painted floor shadows. Chad and Evey come from the v5 sheets
# (the volume style), with the cutlass swing (sheet_v3.jpg) and Evey's bite, sniff and dig
# (sheet_v4.jpg) from older sheets until new ones are drawn; other drafts are kept for reference.
REGIONS = {
    # v5 (the volume style, docs/16-image-prompts.md): the current look.
    # front, 3/4 right, side right, back 3/4, back
    "chad_model": ("v5_chad_model.jpg", 0, 1376, 0, 768, True),
    # 3/4 walk to the right: frames 0-3 on top, 4-7 below (6 and 7 are not walk poses)
    "chad_walk_a": ("v5_chad_walk.jpg", 0, 1376, 0, 384, True),
    "chad_walk_b": ("v5_chad_walk.jpg", 0, 1376, 384, 768, True),
    # 8-frame walk away from the viewer
    "chad_back": ("v5_chad_walk_back.jpg", 0, 1376, 0, 482, True),
    # dodge roll to the right: run-in, dive, roll, kneel, rise, ready
    "chad_roll": ("v5_chad_roll.jpg", 0, 1376, 0, 768, True),
    # front, 3/4 right, side (facing left), back 3/4, back
    "evey_model": ("v5_evey_model.jpg", 0, 1376, 0, 768, True),
    # trot to the right: 0-3 on top; below 4-5 trot, 6 sitting, 7 a play bow facing left
    "evey_trot_a": ("v5_evey_trot.jpg", 0, 1376, 0, 384, True),
    "evey_trot_b": ("v5_evey_trot.jpg", 0, 1376, 384, 768, True),
    # 8-frame run to the right
    "chad_run": ("v5_chad_run.jpg", 0, 1376, 0, 768, True),
    # hit (hand to head), stagger, sat down dazed, dizzy
    "chad_hurt": ("v5_chad_hurt.jpg", 0, 1376, 0, 768, True),
    # holding a gyro, a bite, chewing, satisfied
    "chad_eat": ("v5_chad_eat.jpg", 0, 1376, 0, 768, True),
    # holding a find up: front, 3/4, 3/4
    "chad_hold": ("v5_chad_hold.jpg", 0, 1376, 0, 768, True),
    # fishing: hold, cast, side, reel, reel (the line joins them, so one box each)
    "chad_fish_0": ("v5_chad_fish.jpg", 0, 300, 0, 768, True),
    "chad_fish_1": ("v5_chad_fish.jpg", 300, 600, 0, 768, True),
    "chad_fish_2": ("v5_chad_fish.jpg", 600, 840, 0, 768, True),
    "chad_fish_3": ("v5_chad_fish.jpg", 840, 1105, 0, 768, True),
    "chad_fish_4": ("v5_chad_fish.jpg", 1105, 1376, 0, 768, True),
    # 5-frame gallop to the right
    "evey_run": ("v5_evey_run.jpg", 0, 1376, 0, 768, True),
    # front, side, bark, side
    "evey_bark": ("v5_evey_bark.jpg", 0, 1376, 0, 768, True),
    # 4-frame paddle to the right
    "evey_swim": ("v5_evey_swim.jpg", 0, 1376, 0, 768, True),
    # 6-frame walk carrying a slipper
    "evey_carry": ("v5_evey_carry.jpg", 0, 1376, 0, 768, True),
    # lying down, head down, asleep
    "evey_rest": ("v5_evey_rest.jpg", 0, 1376, 0, 768, True),
    # Older sheets still used until the new style has them:
    # cutlass: front, lunge, raised, back
    "chad_swing": ("sheet_v3.jpg", 0, 510, 380, 572, True),
    # sniff, dig x2, sniff, crouch, lunge, bark, happy standing
    "evey_act": ("sheet_v4.jpg", 0, 1024, 462, 572, True),
}
# Rectangles whose figures are cut at its sides (the fishing line joins those figures).
BOXED = tuple(f"chad_fish_{i}" for i in range(5))
# The colour of each sheet's painted floor shadows, for telling them from dark clothes.
SHADOW_TINT = {
    "sheet_v3.jpg": "neutral",
    "sheet_v4.jpg": "warm",
    "v5_chad_walk_back.jpg": "neutral",
}
# The generator drew each group at its own size; these bring every group to the same character
# size in the game (Chad about 110 px tall in a 128 px frame, Evey about 58 tail to paw).
# Numbers: target height / a standing figure's height in that group.
SCALES = {
    "chad_model": 110 / 595,
    "chad_walk_a": 110 / 312,
    "chad_walk_b": 110 / 312,
    "chad_back": 110 / 238,
    "chad_roll": 110 / 556,
    "chad_swing": 110 / 166,
    "chad_run": 110 / 268,
    "chad_hurt": 110 / 597,
    "chad_eat": 110 / 600,
    "chad_hold": 110 / 600,
    "chad_fish_0": 110 / 597,
    "chad_fish_1": 110 / 597,
    "chad_fish_2": 110 / 597,
    "chad_fish_3": 110 / 597,
    "chad_fish_4": 110 / 597,
    "evey_run": 58 / 262,
    "evey_bark": 58 / 318,
    "evey_swim": 58 / 262,
    "evey_carry": 58 / 262,
    "evey_rest": 58 / 318,
    "evey_model": 58 / 312,
    "evey_trot_a": 58 / 276,
    "evey_trot_b": 58 / 276,
    "evey_act": 0.72,
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
            "up": _frames("model", [4]),
            "side": _frames("model", [2]),
            "down": _frames("model", [0]),
        },
        "walk": {
            "up": _frames("back", range(8)),
            "side": _frames("walk_a", range(4)) + _frames("walk_b", [0, 1]),
            "down": _frames("walk_a", range(4)) + _frames("walk_b", [0, 1]),
        },
        "slash": {
            "up": _frames("swing", [3, 3]),
            "side": _frames("swing", [2, 1]),
            "down": _frames("swing", [0, 1]),
        },
        "roll": {
            "up": _frames("roll", range(6)),
            "side": _frames("roll", range(6)),
            "down": _frames("roll", range(6)),
        },
        "run": {
            "up": _frames("back", range(8)),
            "side": _frames("run", range(8)),
            "down": _frames("walk_a", range(4)) + _frames("walk_b", [0, 1]),
        },
        "hurt": {
            "up": _frames("hurt", [1]),
            "side": _frames("hurt", [1]),
            "down": _frames("hurt", [0]),
        },
        "faint": {"all": _frames("hurt", [2])},
        "dizzy": {"all": _frames("hurt", [3])},
        "eat": {"all": _frames("eat", range(4))},
        "hold": {
            "up": _frames("hold", [0]),
            "side": _frames("hold", [1]),
            "down": _frames("hold", [0]),
        },
        "fish": {
            "up": [(f"fish_{i}:0", False) for i in range(5)],
            "side": [(f"fish_{i}:0", False) for i in range(5)],
            "down": [(f"fish_{i}:0", False) for i in range(5)],
        },
    },
    "evey": {
        "idle": {
            "up": _frames("model", [4]),
            "side": _frames("model", [1]),
            "down": _frames("model", [0]),
        },
        "walk": {
            "up": _bob("model:4", 6),
            "side": _frames("trot_a", range(4)) + _frames("trot_b", [0, 1]),
            "down": _bob("model:0", 6),
        },
        "run": {
            "up": _bob("model:4", 5),
            "side": _frames("run", range(5)),
            "down": _bob("model:0", 5),
        },
        "swim": {
            "up": _frames("swim", range(4)),
            "side": _frames("swim", range(4)),
            "down": _frames("swim", range(4)),
        },
        "carry": {
            "up": _bob("model:4", 6),
            "side": _frames("carry", range(6)),
            "down": _bob("model:0", 6),
        },
        "bark": {
            "up": _frames("model", [4]),
            "side": _frames("bark", [2]),
            "down": _frames("bark", [0]),
        },
        "lie": {"all": _frames("rest", [0])},
        "sleep": {"all": _frames("rest", [1, 2])},
        "sit": {
            "up": _frames("model", [4]),
            "side": _frames("trot_b", [2]),
            "down": _frames("trot_b", [2]),
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
    boxed: tuple = (),
) -> dict:
    """Figures laid out in named rectangles of one sheet, {name: (x0, x1, y0, y1)}, each read
    left to right: {name: [frames]}. A figure belongs to the rectangle holding its centre.
    `strict` uses the tighter backdrop test and strips painted floor shadows. Figures in `boxed`
    rectangles are cut at the rectangle's sides (for figures joined by a fishing line or rod)."""
    rgb = np.asarray(Image.open(path).convert("RGB")).astype(int)
    solid = ~(backdrop_mask(rgb) if strict else background_mask(rgb))
    if strict and any(name in regions for name in boxed):
        # A fishing line closes off patches of backdrop that the edge flood can't reach.
        border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
        close = np.sqrt(((rgb - np.median(border, axis=0)) ** 2).sum(axis=2)) < 9.0
        pockets, found_pockets = _components(close & solid)
        for n, size, *_ in found_pockets:
            if size > 400:
                solid[pockets == n] = False
    solid = np.asarray(Image.fromarray((solid * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(3))) > 0
    near = np.asarray(Image.fromarray((solid * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(dilate))) > 0
    for name in boxed:
        if name in regions:
            x0, x1, y0, y1 = regions[name]
            for x in (x0, x1 - 1):
                near[y0:y1, max(x - dilate, 0) : x + dilate + 1] = False
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
        # Loose bits below the feet (the top of a figure in the next row down, touching this
        # one's shadow) are not part of this figure.
        body, pieces = _components(keep & ~shadow)
        if pieces:
            biggest = max(pieces, key=lambda c: c[1])
            for m, size, p_top, *_ in pieces:
                if m != biggest[0] and p_top >= biggest[3] - (biggest[3] - biggest[2]) * 0.08:
                    keep[body == m] = False
        keep &= ~(shadow & ~_flood_from_edges(shadow | ~keep)) | shadow
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


# The comic look, matched to shaders/comic_screen.gdshader (the environment's comic mockup).
COMIC_INK = (18, 13, 13)
COMIC_BANDS = 4.0
COMIC_SATURATION = 1.3


def comic(img: Image.Image) -> Image.Image:
    """The comic pass for a character, run at twice its final size: a bold ink outline, ink
    where shapes change inside, flat colour bands, bolder colour, and halftone dots in the
    deepest shadows (never on skin or fur). The soft contact shadow is left alone."""
    a = np.asarray(img).astype(float)
    alpha = a[..., 3]
    solid = alpha > 200
    raw = np.asarray(img.convert("RGB")).astype(float) / 255
    rgb = np.asarray(img.convert("RGB").filter(ImageFilter.MedianFilter(3))).astype(float) / 255
    lum = rgb @ np.array([0.299, 0.587, 0.114])
    # Lift the darkest clothes a little so the olive jacket and trousers read as colour, not
    # black, once the screen's own comic pass darkens them again.
    lift = np.clip(0.16 - lum, 0, 1) * 0.6
    rgb = np.clip(rgb + lift[..., None] * (rgb / np.maximum(lum, 0.02)[..., None]), 0, 1)
    lum = rgb @ np.array([0.299, 0.587, 0.114])
    banded = (np.floor(lum * COMIC_BANDS) + 0.5) / COMIC_BANDS
    banded = banded * 0.65 + lum * 0.35
    flat = rgb * (banded / np.maximum(lum, 0.001))[..., None]
    grey = (flat @ np.array([0.299, 0.587, 0.114]))[..., None]
    flat = np.clip(grey + (flat - grey) * COMIC_SATURATION, 0, 1) * 255
    # Ink inside: strong brightness edges only, so faces stay clean.
    gx = np.zeros_like(lum)
    gy = np.zeros_like(lum)
    gx[:, 1:-1] = lum[:, 2:] - lum[:, :-2]
    gy[1:-1, :] = lum[2:, :] - lum[:-2, :]
    ink = (np.hypot(gx, gy) > 0.22) & solid
    # Small dark details (eyes, brows, mouth) are drawn from the unfiltered art, so the median
    # filter and the colour bands don't wipe out the face.
    raw_lum = raw @ np.array([0.299, 0.587, 0.114])
    local = np.asarray(
        Image.fromarray((raw_lum * 255).astype(np.uint8)).filter(ImageFilter.BoxBlur(3))
    ) / 255.0
    ink |= (raw_lum < local - 0.12) & (raw_lum < 0.35) & solid
    flat[ink] = flat[ink] * 0.2 + np.array(COMIC_INK) * 0.8
    # Halftone: a 45-degree dot screen in the darkest tones, not on warm browns.
    yy, xx = np.mgrid[0 : lum.shape[0], 0 : lum.shape[1]]
    cell = (np.stack([(xx + yy), (xx - yy)]) * 0.7071 / 8.0) % 1.0 - 0.5
    shade = np.clip((0.2 - lum) / 0.2, 0, 1)
    warm = (rgb[..., 0] - rgb[..., 2] > 0.08) & (rgb[..., 2] <= rgb[..., 1])
    shade[warm] = 0
    dots = np.hypot(cell[0], cell[1]) < np.sqrt(shade) * 0.5
    flat[dots & solid & ~ink] *= 0.5
    # A bold, rounded outline around the silhouette.
    grow = np.asarray(
        Image.fromarray((solid * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2.2))
    ) / 255.0
    rim = np.clip((grow - 0.06) * 7.0, 0, 1) * 255
    rgba = np.dstack([flat, alpha])
    rgba[~solid, :3] = a[~solid, :3]
    outside = ~solid & (rim > alpha)
    rgba[outside, :3] = COMIC_INK
    rgba[outside, 3] = rim[outside]
    return Image.fromarray(np.clip(rgba, 0, 255).astype(np.uint8), "RGBA")


def frame_of(
    pose: Image.Image, scale: float, mirror: bool, dy: int = 0, style: str = "painted"
) -> Image.Image:
    """One frame: the figure scaled, feet on the baseline, and centred on its mass (not its box),
    so swinging arms and legs don't shift the body from frame to frame."""
    size = (max(1, round(pose.width * scale)), max(1, round(pose.height * scale)))
    if style == "comic":
        img = comic(pose.resize((size[0] * 2, size[1] * 2), Image.LANCZOS))
        img = img.resize(size, Image.LANCZOS)
    else:
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
                        SOURCE / sheet_file,
                        regions,
                        dilate=3,
                        strict=strict,
                        shadow_tint=tint,
                        boxed=BOXED,
                    )
                )
    for name, layout in LAYOUTS.items():
        for style in ("painted", "comic"):
            _pack(name, style, layout, groups, sheets)
    sheets_path.write_text(json.dumps(sheets, indent=2) + "\n")


# Normal maps: how rounded a figure's edges are (pixels from the edge to the full "dome"), how
# much the painting's own light and dark adds surface detail, and how steep the result is.
ROUND = 13
DETAIL = 0.35
STRENGTH = 2.6


def _blur(values: np.ndarray, sigma: float) -> np.ndarray:
    """A Gaussian blur of a float array (separable, edges clamped)."""
    radius = int(sigma * 3)
    xs = np.arange(-radius, radius + 1)
    kernel = np.exp(-(xs**2) / (2 * sigma * sigma))
    kernel /= kernel.sum()
    out = values
    for axis in (0, 1):
        padded = np.pad(out, [(radius, radius) if a == axis else (0, 0) for a in (0, 1)], mode="edge")
        out = sum(
            kernel[i] * np.take(padded, range(i, i + out.shape[axis]), axis=axis)
            for i in range(len(kernel))
        )
    return out


def normals(sheet: Image.Image) -> Image.Image:
    """A normal map for a painted sheet, so the game's lights shade the flat figures as if they
    were rounded: each figure becomes a soft dome (height from the distance to its edge), with
    a little relief from the painted shading (folds, the backpack, the face). Encoded the usual
    way (x right, y up, z out of the picture: flat is (128, 128, 255)). Transparent and
    see-through pixels (the contact shadow) stay flat."""
    rgba = np.asarray(sheet).astype(float)
    solid = rgba[..., 3] > 200
    # Distance to the edge, up to ROUND, by growing the outside inwards one pixel at a time.
    dist = np.zeros(solid.shape)
    inside = solid.copy()
    for step in range(1, ROUND + 1):
        dist[inside] = step
        shrunk = Image.fromarray((inside * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(3))
        inside = np.asarray(shrunk) > 0
        if not inside.any():
            break
    t = dist / ROUND
    dome = np.sqrt(np.clip(1.0 - (1.0 - t) ** 2, 0.0, 1.0))
    lum = (rgba[..., :3] @ np.array([0.299, 0.587, 0.114])) / 255.0
    lum = np.asarray(Image.fromarray((lum * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))) / 255.0
    height = _blur(np.where(solid, dome, 0.0), 1.8) + np.where(solid, lum * DETAIL, 0.0)
    gx = np.zeros_like(height)
    gy = np.zeros_like(height)
    gx[:, 1:-1] = (height[:, 2:] - height[:, :-2]) / 2.0
    gy[1:-1, :] = (height[2:, :] - height[:-2, :]) / 2.0
    nx = -gx * STRENGTH * ROUND / 4.0
    ny = gy * STRENGTH * ROUND / 4.0  # image rows go down; normal-map y goes up
    nz = np.ones_like(height)
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    n = np.dstack([nx, ny, nz]) / length[..., None]
    n[~solid] = (0.0, 0.0, 1.0)
    out = np.clip((n * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    return Image.fromarray(out, "RGB")


def _pack(name: str, style: str, layout: dict, groups: dict, sheets: dict) -> None:
    """One character's frames as a game sheet, assets/characters/<name>_<style>.png."""
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
                scale = SCALES[f"{name}_{group}"]
                row.append(frame_of(figure, scale, mirror, dy[0] if dy else 0, style))
            rows.append(row)
    cols = max(len(r) for r in rows)
    sheet = Image.new("RGBA", (cols * FRAME, len(rows) * FRAME))
    for y, row in enumerate(rows):
        for x, cell in enumerate(row):
            sheet.alpha_composite(cell, (x * FRAME, y * FRAME))
    sheet.save(OUT / f"{name}_{style}.png")
    normals(sheet).save(OUT / f"{name}_{style}_n.png")
    entry["normals"] = True
    sheets["characters"][f"{name}_{style}"] = entry
    print(f"{name}_{style}.png", sheet.size)


if __name__ == "__main__":
    main()
