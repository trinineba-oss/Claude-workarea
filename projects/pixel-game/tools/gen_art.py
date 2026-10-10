"""Regenerates the placeholder pixel art (stdlib only).

Usage: python3 -I tools/gen_art.py   (run from projects/pixel-game)
Replace the PNGs in assets/ with real art whenever it exists; keep the tile
order in assets/tiles/overworld.png in sync with scripts/tiles.gd.
"""

import struct
import zlib

T = (0, 0, 0, 0)


def write_png(path, rows, scale=1):
    h, w = len(rows), len(rows[0])
    raw = b""
    for row in rows:
        line = b"".join(bytes(px) * scale for px in row)
        raw += (b"\x00" + line) * scale

    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    ihdr = struct.pack(">IIBBBBB", w * scale, h * scale, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
    png += chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


# ---- player (16x16) and app icon -------------------------------------------
K = (24, 20, 37, 255)
S = (255, 205, 160, 255)
R = (222, 62, 62, 255)
B = (60, 94, 200, 255)
PLAYER = [
    "................",
    "......KKKK......",
    ".....KRRRRK.....",
    "....KRRRRRRK....",
    "....KSSSSSSK....",
    "....KSKSSKSK....",
    "....KSSSSSSK....",
    ".....KSSSSK.....",
    "....KBBBBBBK....",
    "...KBBBBBBBBK...",
    "...KSBBBBBBSK...",
    "...KSBBBBBBSK...",
    "....KBBBBBBK....",
    "....KBBKKBBK....",
    "....KKK..KKK....",
    "................",
]
PAL = {".": T, "K": K, "S": S, "R": R, "B": B}
player_rows = [[PAL[c] for c in line] for line in PLAYER]
write_png("assets/sprites/player.png", player_rows)
write_png("assets/sprites/icon.png", player_rows, scale=4)


# ---- enemies and pickups -----------------------------------------------------
def sprite(path, art, pal, scale=1):
    rows = [[pal[c] for c in line] for line in art]
    write_png(path, rows, scale)


EK = (24, 20, 37, 255)
CORBEAU = [
    "................",
    "................",
    "......KKKK......",
    ".....KPPPPK.....",
    ".....KPWPPKYY...",
    ".....KPPPPYYK...",
    "..KK..KKKK.KK...",
    ".KGGKKGGGGKKGGK.",
    "KGGGGKGGGGKGGGGK",
    "KGGGGGGGGGGGGGGK",
    ".KGGGGGGGGGGGGK.",
    "..KKGGGGGGGGKK..",
    "....KKGGGGKK....",
    "......KYYK......",
    "......Y..Y......",
    "................",
]
sprite(
    "assets/sprites/corbeau.png",
    CORBEAU,
    {
        ".": T,
        "K": EK,
        "G": (62, 58, 78, 255),
        "P": (214, 128, 128, 255),
        "W": (255, 255, 255, 255),
        "Y": (240, 200, 80, 255),
    },
)

DOG = [
    "................",
    "................",
    "................",
    "..............K.",
    ".............KDK",
    "...........KKDDK",
    "..KK......KDDDDK",
    ".KDDK....KDDDDWK",
    "..KDDKKKKDDDDDNK",
    "..KDDDDDDDDDDKKK",
    "..KDDDDDDDDDDK..",
    "..KDLLLLLDDDDK..",
    "..KDDKKDDDKKDK..",
    "..KKK.KK.KKKK...",
    "................",
    "................",
]
sprite(
    "assets/sprites/dog.png",
    DOG,
    {
        ".": T,
        "K": EK,
        "D": (160, 108, 64, 255),
        "L": (214, 168, 112, 255),
        "W": (255, 255, 255, 255),
        "N": (40, 30, 30, 255),
    },
)

SNACK = [  # a "double": two bara around curried channa
    "........",
    ".KKKKKK.",
    "KBBBBBBK",
    "KOOOOOOK",
    "KBBBBBBK",
    ".KKKKKK.",
    "........",
    "........",
]
sprite(
    "assets/sprites/snack.png",
    SNACK,
    {".": T, "K": (110, 70, 30, 255), "B": (238, 196, 112, 255), "O": (226, 110, 30, 255)},
)
COIN = [
    "..KKKK..",
    ".KYYYYK.",
    "KYYLLYYK",
    "KYLYYYYK",
    "KYLYYYYK",
    "KYYYYYYK",
    ".KYYYYK.",
    "..KKKK..",
]
sprite(
    "assets/sprites/coin.png",
    COIN,
    {".": T, "K": (120, 84, 20, 255), "Y": (250, 206, 60, 255), "L": (255, 244, 170, 255)},
)

# ---- overworld tiles: 9 tiles in a row --------------------------------------
def rgb(r, g, b):
    return (r, g, b, 255)


GRASS, GRASS_D, GRASS_L = rgb(106, 170, 84), rgb(84, 146, 70), rgb(136, 196, 100)
SAND, SAND_D, SAND_L = rgb(232, 214, 160), rgb(210, 190, 130), rgb(244, 232, 190)
WATER, WATER_D, WATER_L = rgb(58, 120, 200), rgb(40, 96, 176), rgb(140, 196, 240)
ROCK, ROCK_D, ROCK_L, ROCK_O = rgb(120, 120, 130), rgb(84, 84, 98), rgb(160, 160, 170), rgb(50, 50, 62)
LEAF, LEAF_D, LEAF_L, LEAF_O = rgb(52, 130, 66), rgb(34, 92, 50), rgb(98, 180, 84), rgb(24, 66, 40)
WOOD, WOOD_D = rgb(120, 78, 44), rgb(84, 54, 30)
DIRT, DIRT_D, DIRT_L = rgb(200, 160, 110), rgb(170, 130, 90), rgb(224, 190, 140)
FLOOR, FLOOR_D = rgb(214, 206, 190), rgb(186, 178, 160)
PINK, WHITE, YELLOW = rgb(240, 120, 150), rgb(255, 255, 255), rgb(250, 214, 70)


class Tile:
    def __init__(self, base, seed):
        self.px = [[base] * 16 for _ in range(16)]
        self.state = seed

    def rnd(self):
        self.state = (self.state * 1103515245 + 12345) & 0x7FFFFFFF
        return self.state >> 8

    def speckle(self, color, count):
        for _ in range(count):
            self.px[self.rnd() % 16][self.rnd() % 16] = color

    def put(self, x, y, color):
        if 0 <= x < 16 and 0 <= y < 16:
            self.px[y][x] = color

    def disc(self, cx, cy, r, color):
        for y in range(16):
            for x in range(16):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    self.px[y][x] = color

    def rect(self, x0, y0, x1, y1, color):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.put(x, y, color)


def grass(seed):
    t = Tile(GRASS, seed)
    t.speckle(GRASS_D, 14)
    t.speckle(GRASS_L, 8)
    return t


def make_tiles():
    tiles = []
    tiles.append(grass(1))  # 0 grass

    t = Tile(SAND, 2)  # 1 sand
    t.speckle(SAND_D, 12)
    t.speckle(SAND_L, 10)
    tiles.append(t)

    t = Tile(WATER, 3)  # 2 water
    for y in (3, 10):
        for x in range(16):
            if (x // 2 + y) % 2 == 0:
                t.put(x, y, WATER_L)
            else:
                t.put(x, y + 1, WATER_D)
    tiles.append(t)

    t = Tile(ROCK, 4)  # 3 rock wall (stone blocks)
    t.rect(0, 0, 15, 0, ROCK_O)
    t.rect(0, 7, 15, 7, ROCK_O)
    t.rect(0, 15, 15, 15, ROCK_O)
    t.rect(7, 0, 7, 7, ROCK_O)
    t.rect(3, 8, 3, 15, ROCK_O)
    t.rect(11, 8, 11, 15, ROCK_O)
    t.rect(1, 1, 6, 1, ROCK_L)
    t.rect(8, 1, 14, 1, ROCK_L)
    t.rect(1, 8, 2, 8, ROCK_L)
    t.rect(4, 8, 10, 8, ROCK_L)
    t.rect(12, 8, 14, 8, ROCK_L)
    t.speckle(ROCK_D, 10)
    tiles.append(t)

    t = grass(5)  # 4 bush
    t.disc(8, 9, 6, LEAF_O)
    t.disc(8, 9, 5, LEAF)
    t.disc(6, 7, 2, LEAF_L)
    t.rect(9, 10, 11, 11, LEAF_D)
    tiles.append(t)

    t = grass(6)  # 5 tree
    t.rect(7, 10, 8, 15, WOOD)
    t.put(8, 12, WOOD_D)
    t.put(8, 14, WOOD_D)
    t.disc(8, 6, 7, LEAF_O)
    t.disc(8, 6, 6, LEAF)
    t.disc(6, 4, 2, LEAF_L)
    t.rect(9, 8, 12, 10, LEAF_D)
    tiles.append(t)

    t = Tile(DIRT, 7)  # 6 path
    t.speckle(DIRT_D, 14)
    t.speckle(DIRT_L, 8)
    tiles.append(t)

    t = grass(8)  # 7 flowers
    for (x, y, c) in ((3, 4, PINK), (11, 3, WHITE), (6, 11, YELLOW), (13, 12, PINK)):
        t.put(x, y, c)
        t.put(x + 1, y, c)
        t.put(x, y + 1, GRASS_D)
    tiles.append(t)

    t = Tile(FLOOR, 9)  # 8 stone floor
    t.rect(0, 7, 15, 7, FLOOR_D)
    t.rect(7, 0, 7, 15, FLOOR_D)
    t.speckle(FLOOR_D, 6)
    tiles.append(t)
    return tiles


tiles = make_tiles()
atlas = [[T] * (16 * len(tiles)) for _ in range(16)]
for i, tile in enumerate(tiles):
    for y in range(16):
        for x in range(16):
            atlas[y][i * 16 + x] = tile.px[y][x]
write_png("assets/tiles/overworld.png", atlas)
print("tiles:", len(tiles))
