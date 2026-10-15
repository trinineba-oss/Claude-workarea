"""Builds the human characters from the Universal LPC Spritesheet Character Generator.

Usage (from projects/pixel-game; needs the network):
    uv run --with pillow --with numpy python -I tools/lpc_build.py

For each character in CAST it downloads the parts' sheets from the generator's site (cached in
tools/.lpc_cache, which git ignores), recolours them (skin, clothes, hair), stacks them in the
generator's layer order, and packs the animations into one sheet:
assets/characters/<name>.png, 64x64 frames, layout in assets/characters/sheets.json.
It also writes assets/characters/CREDITS.md from the generator's credits data: the LPC art is
free to use, but every artist must be credited and the sheets are shared under CC-BY-SA 3.0.
"""

import json
import os
import re
import sys
import urllib.request

import numpy as np
from PIL import Image

SITE = "https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator"
CACHE = "tools/.lpc_cache"
OUT = "assets/characters"
FRAME = 64
# Animation -> (frames, directional). Directional sheets have 4 rows: up, left, down, right.
ANIMS = {"walk": (9, True), "idle": (2, True), "slash": (6, True), "hurt": (6, False)}

# Colour ramps, dark to light: parts are recoloured by brightness onto these.
SKIN = {
    "brown": [(52, 30, 22), (104, 64, 44), (150, 98, 68), (186, 128, 92), (210, 158, 120)],
    "dark": [(30, 18, 14), (66, 40, 30), (98, 62, 44), (128, 84, 60), (156, 108, 80)],
    "tan": [(70, 44, 30), (132, 88, 60), (178, 126, 88), (212, 160, 120), (232, 192, 156)],
    "light": [(92, 60, 48), (164, 112, 88), (214, 160, 128), (238, 196, 164), (250, 220, 196)],
}


def ramp(*colours):
    return [tuple(c) for c in colours]


GREY = ramp((40, 42, 50), (78, 82, 92), (112, 116, 126), (150, 154, 162))
WHITE = ramp((120, 120, 130), (190, 190, 198), (232, 232, 236), (250, 250, 252))
JEANS = ramp((18, 24, 44), (34, 48, 84), (52, 72, 120), (84, 104, 150))
BLACK_HAIR = ramp((12, 10, 10), (28, 22, 22), (48, 38, 36))
GREY_HAIR = ramp((60, 58, 60), (120, 118, 120), (176, 174, 176))
SHOE = ramp((20, 20, 24), (60, 60, 66), (200, 200, 206))
STUBBLE = ramp((40, 28, 24), (70, 50, 42), (96, 70, 58))
GOLD = ramp((90, 64, 20), (180, 140, 50), (240, 210, 110))


def solid(r, g, b, spread=0.45):
    """A ramp around one colour."""
    base = np.array([r, g, b], dtype=float)
    return [tuple((base * f).clip(0, 255).astype(int)) for f in (1 - spread, 1 - spread / 2, 1.0, 1 + spread / 3)]


# name -> body type, skin, [(item key, ramp or None, alpha)]
CAST = {
    "chad": ("male", "brown", [
        ("feet_shoes_basic", SHOE), ("legs_pants", JEANS), ("torso_clothes_tshirt", GREY),
        ("neck_necklace_chain", GOLD), ("heads_human_male", None), ("beards_5oclock_shadow", STUBBLE, 0.55),
        ("hair_buzzcut", BLACK_HAIR),
    ]),
    "gyro_vendor": ("male", "tan", [
        ("feet_shoes_basic", SHOE), ("legs_pants", solid(60, 60, 80)), ("torso_clothes_tshirt", WHITE),
        ("torso_aprons_apron", WHITE), ("heads_human_male", None), ("beards_mustache", BLACK_HAIR),
        ("hair_flat_top_fade", BLACK_HAIR), ("hat_bandana", solid(40, 140, 96)),
    ]),
    "doubles_vendor": ("female", "dark", [
        ("feet_sandals", SHOE), ("legs_skirts_plain", solid(140, 70, 140)), ("torso_clothes_blouse", solid(232, 96, 140)),
        ("heads_human_female", None), ("hair_bob", BLACK_HAIR), ("hat_headband_kerchief", solid(250, 196, 60)),
    ]),
    "fisherman": ("male", "dark", [
        ("feet_sandals", SHOE), ("legs_shorts", solid(90, 86, 70)), ("torso_clothes_shortsleeve_polo", solid(90, 150, 196)),
        ("heads_human_male_elderly", None), ("beards_mustache", GREY_HAIR), ("hair_curly_short", GREY_HAIR),
    ]),
    "limer": ("male", "tan", [
        ("feet_sandals", SHOE), ("legs_shorts", JEANS), ("torso_clothes_tshirt", WHITE),
        ("heads_human_male", None), ("hair_afro", BLACK_HAIR),
    ]),
    "soup_lady": ("female", "brown", [
        ("feet_sandals", SHOE), ("legs_skirts_plain", solid(110, 70, 50)), ("torso_clothes_blouse", solid(250, 160, 50)),
        ("torso_aprons_apron", WHITE), ("heads_human_female", None), ("hair_bob", BLACK_HAIR),
        ("hat_headband_kerchief", solid(220, 50, 50)),
    ]),
    "pork_man": ("male", "light", [
        ("feet_shoes_basic", SHOE), ("legs_pants", solid(70, 60, 50)), ("torso_clothes_tshirt", solid(240, 140, 60)),
        ("torso_aprons_apron", WHITE), ("heads_human_male_plump", None), ("hair_balding", BLACK_HAIR),
    ]),
    "seafood_man": ("male", "dark", [
        ("feet_sandals", SHOE), ("legs_shorts", solid(60, 70, 90)), ("torso_clothes_shortsleeve_polo", solid(60, 170, 170)),
        ("heads_human_male", None), ("hair_curly_short", BLACK_HAIR), ("hat_bandana", solid(230, 70, 60)),
    ]),
    "bandit": ("male", "brown", [
        ("feet_shoes_basic", ramp((20, 20, 24), (40, 40, 46), (230, 230, 236))), ("legs_pants", solid(34, 34, 44)),
        ("torso_clothes_longsleeve", solid(52, 50, 66)), ("heads_human_male", None),
        ("facial_mask_plain", solid(176, 40, 52)), ("hat_hood_cloth", solid(52, 50, 66)),
    ]),
    "rival": ("male", "light", [
        ("feet_shoes_basic", SHOE), ("legs_formal", solid(110, 50, 150)), ("torso_clothes_longsleeve_formal", solid(110, 50, 150)),
        ("neck_bowtie", GOLD), ("heads_human_male_plump", None), ("hair_flat_top_straight", BLACK_HAIR),
        ("hat_formal_bowler", solid(90, 40, 120)),
    ]),
}


def fetch(url, path):
    if os.path.exists(path):
        return path
    os.makedirs(os.path.dirname(path), exist_ok=True)
    try:
        with urllib.request.urlopen(url, timeout=60) as response:
            data = response.read()
    except Exception:
        return None
    with open(path, "wb") as f:
        f.write(data)
    return path


def metadata():
    """The generator's layer paths/order and credits, from its JavaScript bundles."""
    index = open(fetch(SITE + "/", f"{CACHE}/index.html"), encoding="utf8").read()
    main = re.search(r'src="\./assets/(main-[^"]+\.js)"', index).group(1)
    main_js = open(fetch(f"{SITE}/assets/{main}", f"{CACHE}/{main}"), encoding="utf8", errors="ignore").read()
    names = {}
    for kind in ("layers-metadata", "credits-metadata"):
        names[kind] = re.search(kind + r"-[A-Za-z0-9_-]+\.js", main_js + index).group(0)
    layers = open(fetch(f"{SITE}/assets/{names['layers-metadata']}", f"{CACHE}/{names['layers-metadata']}"), encoding="utf8").read()
    credits = open(fetch(f"{SITE}/assets/{names['credits-metadata']}", f"{CACHE}/{names['credits-metadata']}"), encoding="utf8").read()
    return layers, credits


def block(source, key):
    """The {...} (or [...]) that follows `key:` in a minified JS object."""
    match = re.search(r"[{,]" + re.escape(key) + r":([\[{])", source)
    if not match:
        return None
    opening = match.group(1)
    closing = "}" if opening == "{" else "]"
    depth = 0
    for i in range(match.start(1), len(source)):
        if source[i] == opening:
            depth += 1
        elif source[i] == closing:
            depth -= 1
            if depth == 0:
                return source[match.start(1): i + 1]
    return None


def layer_paths(layers_js, key, body):
    entry = block(layers_js, key)
    if entry is None:
        sys.exit(f"unknown LPC item {key}")
    out = []
    for layer in re.findall(r"layer_\d+:\{([^}]*)\}", entry):
        z = int(re.search(r"zPos:(-?\d+)", layer).group(1))
        path = re.search(r"(?<![a-z])" + body + r":`([^`]*)`", layer) or re.search(r"(?<![a-z])male:`([^`]*)`", layer)
        if path:
            out.append((z, path.group(1)))
    return out


def recolour(img, stops):
    rgb, a = img[..., :3], img[..., 3:]
    lum = (rgb @ np.array([0.299, 0.587, 0.114])) / 255.0
    visible = a[..., 0] > 0
    if not visible.any():
        return img
    lo, hi = np.percentile(lum[visible], [5, 99])
    t = np.clip((lum - lo) / max(hi - lo, 1e-3), 0, 1)
    xs = np.linspace(0, 1, len(stops))
    out = np.stack([np.interp(t, xs, [s[c] for s in stops]) for c in range(3)], -1)
    return np.concatenate([out, a], -1)


def sheet_for(path, anim):
    """A part's sheet for one animation. Some parts keep a file per colour; any will do, since
    parts are recoloured. Parts without an idle pose stand still in their walk pose."""
    for name in (f"{anim}.png", f"{anim}/white.png", f"{anim}/black.png", f"{anim}/brown.png"):
        local = fetch(f"{SITE}/spritesheets/{path}{name}", f"{CACHE}/sheets/{path}{name}")
        if local is not None:
            return np.asarray(Image.open(local).convert("RGBA")).astype(np.float32)
    if anim == "idle":
        walk = sheet_for(path, "walk")
        if walk is not None:
            stand = walk[:, :FRAME]
            return np.concatenate([stand, stand], axis=1)
    return None


def build(name, body, skin, parts, layers_js):
    pieces = [(10, "body", f"body/bodies/{body}/", SKIN[skin], 1.0)]
    for part in parts:
        key, stops = part[0], part[1]
        alpha = part[2] if len(part) > 2 else 1.0
        for z, path in layer_paths(layers_js, key, body):
            pieces.append((z, key, path, stops if stops is not None else SKIN[skin], alpha))
    pieces.sort(key=lambda p: p[0])
    rows = []
    layout = {}
    row = 0
    for anim, (frames, directional) in ANIMS.items():
        canvas = None
        for _z, key, path, stops, alpha in pieces:
            img = sheet_for(path, anim)
            if img is None:
                continue
            img = recolour(img, stops)
            img[..., 3] *= alpha
            layer = Image.fromarray(img.clip(0, 255).astype(np.uint8), "RGBA")
            if canvas is None:
                canvas = Image.new("RGBA", layer.size, (0, 0, 0, 0))
            if layer.size != canvas.size:
                continue
            canvas = Image.alpha_composite(canvas, layer)
        if canvas is None:
            continue
        rows.append(canvas)
        count = canvas.size[1] // FRAME
        layout[anim] = {"row": row, "frames": frames, "rows": count}
        row += count
    width = max(r.size[0] for r in rows)
    out = Image.new("RGBA", (width, row * FRAME), (0, 0, 0, 0))
    y = 0
    for r in rows:
        out.paste(r, (0, y))
        y += r.size[1]
    os.makedirs(OUT, exist_ok=True)
    out.save(f"{OUT}/{name}.png")
    return layout, [p[1] for p in pieces]


def credit_lines(credits_js, keys):
    lines = []
    for key in sorted(set(keys)):
        entry = block(credits_js, key)
        if entry is None:
            continue
        for item in re.findall(r"\{file:`([^`]*)`,notes:`([^`]*)`,authors:\[([^\]]*)\],licenses:\[([^\]]*)\],urls:\[([^\]]*)\]", entry):
            file, notes, authors, licenses, urls = item
            names = ", ".join(re.findall(r"`([^`]*)`", authors))
            lics = ", ".join(re.findall(r"`([^`]*)`", licenses))
            links = " ".join(re.findall(r"`([^`]*)`", urls))
            lines.append(f"- **{file}** by {names}. Licences: {lics}. {notes} {links}".rstrip())
    return lines


def main():
    layers_js, credits_js = metadata()
    sheets = {"frame": FRAME, "anims": {}, "characters": {}}
    used = {}
    for name, (body, skin, parts) in CAST.items():
        layout, keys = build(name, body, skin, parts, layers_js)
        sheets["characters"][name] = layout
        used[name] = keys
        print("built", name, layout)
    for anim, (frames, directional) in ANIMS.items():
        sheets["anims"][anim] = {"frames": frames, "directional": directional}
    with open(f"{OUT}/sheets.json", "w") as f:
        json.dump(sheets, f, indent=2)
        f.write("\n")
    all_keys = [k for keys in used.values() for k in keys]
    with open(f"{OUT}/CREDITS.md", "w") as f:
        f.write("# Character art credits\n\n")
        f.write(
            "The human characters in this folder were built with the Universal LPC Spritesheet "
            "Character Generator\n(" + SITE + "/), recoloured and combined by "
            "`tools/lpc_build.py`. The combined sheets are\nshared under **CC-BY-SA 3.0** "
            "(https://creativecommons.org/licenses/by-sa/3.0/), as the parts' licences\nallow. "
            "Parts used, with their authors and licences:\n\n"
        )
        f.write("\n".join(credit_lines(credits_js, all_keys)) + "\n")
        f.write("\nWhich parts each character uses:\n\n")
        for name, keys in used.items():
            f.write(f"- {name}: {', '.join(keys)}\n")


if __name__ == "__main__":
    main()
