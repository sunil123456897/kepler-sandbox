"""Builds crisp pixel-art building, unit, flora, and FX strip atlases, source sprites, and shader masks.

Generates native-size PNGs in `assets/src_sprites/` and packs them into:
1. `assets/atlases/buildings_atlas.png` + `buildings_atlas_mask.png` + `buildings_atlas.json` (24x24 cells, 38 cols)
2. `assets/atlases/units_atlas.png` + `units_atlas_mask.png` + `units_atlas.json` (8x8 cells, 24 cols, shadowless)
3. `assets/atlases/flora_atlas.png` + `flora_atlas_mask.png` + `flora_atlas.json` (12x12 cells, 14 cols, shadowless)
4. `assets/atlases/fx_strips_atlas.png` + `fx_strips_atlas_mask.png` + `fx_strips_atlas.json` (8x8 cells, 16 cols)

Mask channel contract (`sprite_mode = 3` in `shaders/unit_sprite.gdshader`):
- R: faction / role / subtle flora tint weight (0..255)
- G: HDR emission mask (0 = strictly <= 0.95 non-HDR; >0 = emissive visor/core/flame/crystal/shield ring)
- B: subtle glass/metal/crystal specular sheen weight
- A: sprite silhouette alpha (255 on visible pixels)
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Dict, List, Tuple

from PIL import Image

ROOT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = ROOT_DIR / "assets" / "src_sprites"
ATLAS_DIR = ROOT_DIR / "assets" / "atlases"

BLD_CELL_W = 24
BLD_CELL_H = 24
UNIT_CELL_W = 8
UNIT_CELL_H = 8
FLORA_CELL_W = 12
FLORA_CELL_H = 12
FX_CELL_W = 8
FX_CELL_H = 8

# Material-tinted dark outlines (WorldBox-calibrated; never near-black charcoal #1A2230/#15241A)
TREE_EDGE = "#1E4627"
WOOD_EDGE = "#4A2B1D"
ROOF_EDGE = "#5B2318"
ALLOY_EDGE = "#263245"
SPORE_EDGE = "#3A1D52"
CRYSTAL_EDGE = "#183B54"
STONE_EDGE = "#343944"
TEAL_EDGE = "#1B4A42"

SHADOW_RGBA = (16, 24, 36, 90)  # #101824 alpha ~0.353 (building 1px contact crease only)

# Palette entry: (R, G, B, A), (Mask.R, Mask.G, Mask.B)
PaletteEntry = Tuple[Tuple[int, int, int, int], Tuple[int, int, int]]


def _hex(code: str, alpha: int = 255) -> Tuple[int, int, int, int]:
    h = code.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alpha)


# Curated non-#000000 palette with top-left (-0.707, -0.707) key lighting.
# All non-emissive entries (Mask.G == 0) have max(R, G, B) <= 242 (0.949 <= 0.95).
PALETTE: Dict[str, PaletteEntry] = {
    ".": ((0, 0, 0, 0), (0, 0, 0)),
    "~": (SHADOW_RGBA, (0, 0, 0)),  # legacy contact shadow token (forbidden in units/flora)
    # Material-tinted outlines & deep shadows (never pure #000000)
    "o": (_hex(ALLOY_EDGE), (0, 0, 0)),    # cobalt-steel tech / armor / shuttle outline
    "T": (_hex(TREE_EDGE), (0, 0, 0)),     # botanical tree / pine / scrub outline
    "O": (_hex(SPORE_EDGE), (0, 0, 0)),    # xenospore / mycelial chitin outline
    "#": (_hex(WOOD_EDGE), (0, 0, 0)),     # timber / bark / crate / boot outline
    "@": (_hex(ROOF_EDGE), (0, 0, 0)),     # terracotta roof / rocket cap / warm rim outline
    "+": (_hex(CRYSTAL_EDGE), (0, 0, 0)),  # deep sapphire crystal / biodome glass outline
    "=": (_hex(STONE_EDGE), (0, 0, 0)),    # cool basalt / boulder / ash / stalk outline
    "*": (_hex(TEAL_EDGE), (0, 0, 0)),     # deep teal-moss mushroom cap outline
    "p": (_hex("#222834"), (0, 0, 0)),     # recessed blast pit / dark doorway
    "x": (_hex("#2E333E"), (0, 0, 0)),     # scorched soot / dark interior
    # Alloy / steel structural tones (NW lit -> mid -> SE shaded)
    "h": (_hex("#DCE4EE"), (0, 0, 0)),  # top-left bevel highlight
    "a": (_hex("#9EAAB8"), (0, 0, 0)),  # lit steel
    "m": (_hex("#6E7B90"), (0, 0, 0)),  # mid slate steel
    "A": (_hex("#4D5A70"), (0, 0, 0)),  # shaded steel
    "d": (_hex("#3B4659"), (0, 0, 0)),  # deep structural shadow
    # Warm masonry / canvas / wood / rubble
    "w": (_hex("#E2DACB"), (0, 0, 0)),  # lit cream wall / canvas
    "W": (_hex("#B8B0A0"), (0, 0, 0)),  # shaded wall / canvas
    "u": (_hex("#8E887C"), (0, 0, 0)),  # deep wall shadow
    "n": (_hex("#855E4B"), (0, 0, 0)),  # lit timber log / bark
    "N": (_hex("#634436"), (0, 0, 0)),  # shaded timber log / bark
    "r": (_hex("#747982"), (0, 0, 0)),  # lit stone / ash / rubble
    "R": (_hex("#52565E"), (0, 0, 0)),  # shaded stone / ash / rubble
    "$": (_hex("#9E7A5F"), (0, 0, 0)),  # warm ash-brown snag
    "%": (_hex("#B4C4B2"), (0, 0, 0)),  # pale mushroom stalk
    # Faction-tinted structural plates (neutral grayscale carries key-light value)
    "f": (_hex("#DCE4EE"), (240, 0, 0)),  # primary faction highlight
    "F": (_hex("#A4B2C2"), (240, 0, 0)),  # primary faction shaded
    "q": (_hex("#E2DACB"), (96, 0, 0)),   # subtle faction tint (lit)
    "Q": (_hex("#B6AEA0"), (96, 0, 0)),   # subtle faction tint (mid)
    "v": (_hex("#8C8880"), (96, 0, 0)),   # subtle faction tint (shade)
    # Caution / rocket / cargo accents (non-emissive! zero false HDR bloom!)
    "k": (_hex("#E05534"), (0, 0, 0)),    # rocket nose / warning cap
    "K": (_hex("#A83B24"), (0, 0, 0)),    # shaded red-orange metal
    "z": (_hex("#D8A438"), (0, 0, 0)),    # hazard yellow stripe / brass crate / engineer helmet
    "Z": (_hex("#9E7428"), (0, 0, 0)),    # shaded brass / crate
    # Solar glass & biodome glass (Mask.B = specular sheen, non-HDR)
    "s": (_hex("#3A82C4"), (0, 0, 210)),  # sunlit solar cell
    "S": (_hex("#255A94"), (0, 0, 140)),  # mid solar cell
    "P": (_hex("#1B3E73"), (0, 0, 80)),   # shaded solar cell
    "g": (_hex("#7CE0EE"), (0, 0, 235)),  # biodome / cockpit NW glass highlight
    "G": (_hex("#45A8C0"), (0, 0, 180)),  # biodome mid glass
    "j": (_hex("#286D82"), (0, 0, 110)),  # biodome SE shaded glass
    # Flora & organic palettes (non-HDR; subtle Mask.R on trees/chitin for hue variation)
    "Y": (_hex("#74E690"), (110, 0, 0)),  # bright emerald leaf rim
    "l": (_hex("#66CC62"), (110, 0, 0)),  # lush canopy highlight
    "L": (_hex("#3D994F"), (110, 0, 0)),  # lush canopy mid
    "D": (_hex("#286B35"), (85, 0, 0)),   # deep canopy shadow (distinct from TREE_EDGE)
    "t": (_hex("#887A48"), (80, 0, 0)),   # wilted olive foliage (damaged dome)
    "1": (_hex("#2B544A"), (90, 0, 0)),   # frost pine dark needles
    "2": (_hex("#40786A"), (90, 0, 0)),   # frost pine mid needles
    "3": (_hex("#DCE8F2"), (0, 0, 0)),    # frost pine snow cap (242 <= 0.95!)
    "4": (_hex("#4D562B"), (80, 0, 0)),   # desert scrub dark
    "5": (_hex("#788740"), (90, 0, 0)),   # desert scrub mid
    "6": (_hex("#A4B358"), (90, 0, 0)),   # desert scrub highlight
    "J": (_hex("#276E62"), (80, 0, 0)),   # mushroom/mycelium teal dark
    "M": (_hex("#3FA692"), (90, 0, 0)),   # mushroom/mycelium teal mid
    "U": (_hex("#9644DC"), (140, 0, 0)),  # xenospore chitin lit violet
    "V": (_hex("#5A347D"), (115, 0, 0)),  # xenospore chitin shaded plum
    # Non-tinted FX strip icon tones (Mask.R = 0 so alpha fades without faction recolor)
    "!": (_hex("#52D96B"), (0, 0, 0)),    # bright emerald icon highlight
    "?": (_hex("#289444"), (0, 0, 0)),    # mid emerald icon body
    "(": (_hex("#B058F0"), (0, 180, 0)),  # bright violet helix strand (HDR soft)
    ")": (_hex("#7B2CB8"), (0, 115, 0)),  # shaded violet helix strand
    # Crystal facets (specular sheen on body, HDR on tips)
    "7": (_hex("#223845"), (0, 0, 0)),    # crystal dark slate base
    "8": (_hex("#1F627D"), (0, 0, 180)),  # crystal facet dark + sheen
    "9": (_hex("#299BC0"), (0, 0, 215)),  # crystal facet mid + sheen
    "0": (_hex("#5AF2FF"), (0, 235, 0)),  # crystal shard glowing tip (HDR)
    # HDR Emissive accents (Mask.G > 0; ONLY flames, lanterns, optics, beacons, plasma, spores!)
    "y": (_hex("#FFD84A"), (0, 250, 0)),  # bright flame / floodlight core
    "e": (_hex("#FF9422"), (0, 225, 0)),  # orange fire / drill sparks / thruster glow
    "E": (_hex("#C23610"), (0, 175, 0)),  # glowing embers / coals
    "i": (_hex("#FFE45E"), (0, 155, 0)),  # warm tent doorway lantern
    "I": (_hex("#D4A83C"), (0, 115, 0)),  # soft lantern doorway spill
    "c": (_hex("#38F0FF"), (0, 235, 0)),  # cyan plasma / visor / bright beacon
    "C": (_hex("#2498B8"), (0, 165, 0)),  # dimmer cyan glow / blueprint grid
    "H": (_hex("#D9FEFF"), (0, 255, 0)),  # white-cyan fusion / mutant crystal peak
    "b": (_hex("#DCE4EE"), (220, 200, 0)),  # faction-colored roof beacon
    "X": (_hex("#FF3838"), (0, 245, 0)),  # crimson robot optic / laser core
    "B": (_hex("#38FFB0"), (0, 230, 0)),  # bioluminescent neon-mint spore glow
    # Obsidian / violet quantum gate frame (non-HDR <= 0.95) & singularity/diplo accents
    ":": (_hex("#28223A"), (0, 0, 55)),   # deep obsidian-violet shadow
    ";": (_hex("#3F325C"), (0, 0, 95)),   # mid obsidian-violet frame
    "^": (_hex("#665294"), (0, 0, 145)),  # lit amethyst-obsidian bevel
    "&": (_hex("#8B75BD"), (0, 0, 185)),  # bright obsidian-violet rim highlight
    "_": (_hex("#18162C"), (0, 0, 0)),    # deep cosmic event horizon void
    "[": (_hex("#6E88FF"), (0, 225, 0)),  # electric cyan-indigo portal plasma (HDR)
    "]": (_hex("#B85CFF"), (0, 235, 0)),  # vibrant violet singularity plasma (HDR)
    "<": (_hex("#ECE4FF"), (0, 255, 0)),  # white-violet singularity peak (HDR)
    "/": (_hex("#FF6E24"), (0, 235, 0)),  # crimson-orange war spark (HDR)
    "-": (_hex("#DC2E2E"), (0, 185, 0)),  # crimson war blade (HDR)
    "{": (_hex("#FF9B26"), (0, 175, 0)),  # rebel amber-coral emblem (HDR soft)
    "}": (_hex("#F0B121"), (0, 175, 0)),  # pact/war gold emblem (HDR soft)
    ",": (_hex("#FFE156"), (0, 195, 0)),  # rebel marigold-gold highlight (HDR soft)
}


# ---------------------------------------------------------------------------
# 1. BUILDINGS & SHUTTLES (24x24 cells; cols 0..33 preserved, 34..35 Shield, 36..37 Quantum Gate)
# ---------------------------------------------------------------------------
BUILDING_SPECS: List[dict] = [
    {
        "col": 0,
        "id": "bld_campfire",
        "src_name": "bld_campfire_0",
        "size": (8, 8),
        "tier": 0,
        "rows": [
            "..e.....",
            "..ey.e..",
            ".Eeye...",
            ".EeyeE..",
            ".neyeN..",
            "#rNErR#.",
            "#RNnnRr.",
            ".#####..",
        ],
    },
    {
        "col": 1,
        "id": "bld_tent",
        "src_name": "bld_tent_0",
        "size": (12, 12),
        "tier": 0,
        "rows": [
            "............",
            ".....@@.....",
            "....@ff@....",
            "...@qffQ@...",
            "..@qqffQv@..",
            ".@qqqffQvv@.",
            ".#qQFFQqQv#.",
            ".#wwwmmWuv#.",
            ".#wwmiimWv#.",
            ".#wwmIImWv#.",
            "#nwwmIImWvn.",
            ".##########.",
        ],
    },
    {
        "col": 2,
        "id": "bld_drill",
        "src_name": "bld_drill_0",
        "size": (12, 12),
        "tier": 1,
        "rows": [
            "............",
            "..oooooooo..",
            ".oahffffFAo.",
            ".oaaafyeFAo.",
            ".oaohmmhoAo.",
            ".oa.ahma.Ao.",
            ".oa.amha.Ao.",
            ".oo.ahma.oo.",
            ".=RrrpprrR=.",
            "=RRrRppRrRR=",
            "=RrrReeRrrR=",
            ".==========.",
        ],
    },
    {
        "col": 3,
        "id": "bld_depot",
        "src_name": "bld_depot_0",
        "size": (12, 12),
        "tier": 1,
        "rows": [
            "..o.........",
            "..co........",
            "..aoooooooo.",
            ".oahffffffAo",
            ".oaFFFFFFFAo",
            ".ohmmmmmmmAo",
            ".#wwwppppWA#",
            ".#wwppzzpWA#",
            ".#wwpzZZpWA#",
            ".#wwppppppA#",
            ".#wwCppppWA#",
            ".##########.",
        ],
    },
    {
        "col": 4,
        "id": "bld_solar_array",
        "src_name": "bld_solar_array_0",
        "size": (12, 12),
        "tier": 2,
        "rows": [
            "............",
            "............",
            "..++++.++++.",
            ".+sSSP+sSSP+",
            "+sSPPP+SPPP+",
            "+SPPPa+PPPS+",
            "oooooooooooo",
            "..oaffmFAo..",
            "...oafCAo...",
            "...oammao...",
            "..oaaAAaAo..",
            "..oooooooo..",
        ],
    },
    {
        "col": 5,
        "id": "bld_biodome",
        "src_name": "bld_biodome_0",
        "size": (16, 16),
        "tier": 2,
        "rows": [
            "................",
            ".....++++++.....",
            "...++ggagGG++...",
            "..+ggGGaGGGjj+..",
            ".+gamGGaGGmGjj+.",
            ".+gGllGllGGmGj+.",
            "+gGlLLlLLlGGmjj+",
            "+gamLLlLLLaGmjj+",
            "+GgaLllLLmaGmjj+",
            "+GGammmmmmaGGjj+",
            ".+GGGGmmGGGGjj+.",
            ".oaaffmmmmFFAAo.",
            ".oaffCmppmCFFAo.",
            ".oaaampccpmAAAo.",
            "..ooammmmmmaoo..",
            "...oooooooooo...",
        ],
    },
    {
        "col": 6,
        "id": "bld_fusion_reactor",
        "src_name": "bld_fusion_reactor_0",
        "size": (16, 16),
        "tier": 2,
        "rows": [
            "................",
            "..oo..oooo..oo..",
            ".oahoammmmaoaAo.",
            ".oaohhaaaammaAo.",
            "..ohamcHHcmAAo..",
            ".ooaHcCCCCcHaoo.",
            "oafhcCppppCcmFAo",
            "oafmcCpbbpCcmFAo",
            "oaFmcCppppCcmFAo",
            ".ooAHcCCCCcHAoo.",
            "..oAAmcHHcmddo..",
            ".oaohammmmaadAo.",
            ".oaooamddmaooAo.",
            "..ooamCCCCmaoo..",
            "...oammmmmmao...",
            "...oooooooooo...",
        ],
    },
    {
        "col": 7,
        "id": "bld_launchpad",
        "src_name": "bld_launchpad_0",
        "size": (24, 24),
        "tier": 3,
        "rows": [
            "...........@@...........",
            "..........@kk@..........",
            ".....@@...@kK@..........",
            "....@ka@..ohao..........",
            "....oaooooohao..........",
            "....oaahaaohao..........",
            "....oamooohaho..........",
            "....oaooooohaoooo.......",
            "...ooammmmaohaooaoo.....",
            "...ohao..ooohaoammao....",
            "...oaoo..oohahoommmao...",
            "...oamooooohahoammFAo...",
            "...oao..ooohahoammFAo...",
            "...oao..oohafahoamFAo...",
            "..ooaoooohafmfhoaaAAo...",
            "..oyaoohaaofmfomAAyyo...",
            "..oaaoaffaaeeeoAAFAo....",
            "..oaaoaFFaoeeeoaAFAo....",
            "..oamooaaappppooAAdo....",
            "..oaamzzzzppppzzAAdo....",
            "..oAAmZZZZppppZZdddo....",
            "..oyddmmmmppppmmddyo....",
            "...oooooooooooooooo.....",
            "........................",
        ],
    },
    # --- Cols 8..16: Animation frames & damaged variants ---
    {
        "col": 8,
        "id": "bld_campfire_1",
        "src_name": "bld_campfire_1",
        "size": (8, 8),
        "tier": 0,
        "rows": [
            "....e...",
            "..e.ye..",
            "...eyeE.",
            "..eeyeE.",
            ".neyeN..",
            "#rNErR#.",
            "#RNnnRr.",
            ".#####..",
        ],
    },
    {
        "col": 9,
        "id": "bld_tent_1",
        "src_name": "bld_tent_1",
        "size": (12, 12),
        "tier": 0,
        "rows": [
            "............",
            "....oooo....",
            "...oaFFao...",
            "..oaFmmFAo..",
            ".oamddddmao.",
            ".oaAdXXdAAo.",
            ".oaAddddAAo.",
            ".oaFmmmmFAo.",
            ".oAAApppAAo.",
            ".oAAdpXpAAo.",
            "ooAAdpppAAoo",
            ".oooooooooo.",
        ],
    },
    {
        "col": 10,
        "id": "bld_drill_1",
        "src_name": "bld_drill_1",
        "size": (12, 12),
        "tier": 1,
        "rows": [
            "............",
            "............",
            "..oooooooo..",
            ".oahffffFAo.",
            ".oaaafeeFAo.",
            ".ooaammmAoo.",
            ".oa.ahma.Ao.",
            ".oa.amha.Ao.",
            ".=RrahmaRR=.",
            "=RRrRyeRrRR=",
            "=RreeyyeerR=",
            ".==========.",
        ],
    },
    {
        "col": 11,
        "id": "bld_depot_1",
        "src_name": "bld_depot_1",
        "size": (12, 12),
        "tier": 1,
        "rows": [
            "..o.........",
            ".cHo........",
            "..aoooooooo.",
            ".oahffffffAo",
            ".oaFFFFFFFAo",
            ".ohmmmmmmmAo",
            ".#wwwppppWA#",
            ".#wwppzzpWA#",
            ".#wwpzZZpWA#",
            ".#wwppppppA#",
            ".#wwcppppWA#",
            ".##########.",
        ],
    },
    {
        "col": 12,
        "id": "bld_solar_array_1",
        "src_name": "bld_solar_array_1",
        "size": (12, 12),
        "tier": 2,
        "rows": [
            "............",
            "............",
            "..++++.++++.",
            ".+SSsP+sSSP+",
            "+SSPsP+SPsP+",
            "+SPPma+PPSS+",
            "oooooooooooo",
            "..oaffmFAo..",
            "...oafHAo...",
            "...oammao...",
            "..oaaAAaAo..",
            "..oooooooo..",
        ],
    },
    {
        "col": 13,
        "id": "bld_biodome_1",
        "src_name": "bld_biodome_1",
        "size": (16, 16),
        "tier": 2,
        "rows": [
            "................",
            ".....++++++.....",
            "...++ggagpx++...",
            "..+ggGGaxppxx+..",
            ".+gamGGaxppxxj+.",
            ".+gGttGaxpejxj+.",
            "+gGtLLtaxpGjmxj+",
            "+gamLLtLLLaGmjj+",
            "+GgaLttLtmaGmjj+",
            "+GGammmmmmaGGjj+",
            ".+GGGGmmGGGGjj+.",
            ".oaaffmmmmFFAAo.",
            ".oaffCmppmCFFAo.",
            ".oaaampcepmAAAo.",
            "..ooammmmmmaoo..",
            "...oooooooooo...",
        ],
    },
    {
        "col": 14,
        "id": "bld_fusion_reactor_1",
        "src_name": "bld_fusion_reactor_1",
        "size": (16, 16),
        "tier": 2,
        "rows": [
            "................",
            "..oo..oooo..oo..",
            ".oahoammmmaoaAo.",
            ".oaohhaaaammaAo.",
            "..ohamCCCCmAAo..",
            ".ooacHcCCcHcaoo.",
            "oafhHppppppHmFAo",
            "oafmcCpbbpCcmFAo",
            "oaFmcCppppCcmFAo",
            ".ooAHcCCCCcHAoo.",
            "..oAAmCHHCmddo..",
            ".oaohammmmaadAo.",
            ".oaooamddmaooAo.",
            "..ooamHHHHmaoo..",
            "...oammmmmmao...",
            "...oooooooooo...",
        ],
    },
    {
        "col": 15,
        "id": "bld_launchpad_1",
        "src_name": "bld_launchpad_1",
        "size": (24, 24),
        "tier": 3,
        "rows": [
            "........................",
            ".....@@.................",
            "....@ka@................",
            "....oaoo................",
            "....oaahoooo............",
            "....oamooaoo............",
            "....oao.................",
            "....oaoooooooo..........",
            "...ooammmmaaaaooo.......",
            "...ohao..ooammmmaoo.....",
            "...oaoo..ooammmmmmao....",
            "...oamoooooammmmmFAo....",
            "...oao..ooohmmpppFAo....",
            "...oao..oohammpFpFAo....",
            "..ooaoooohafmmpFpAAo....",
            "..oyaoohaaaffmpFpyyo....",
            "..oaaoaffaaapppppFAo....",
            "..oaaoaFFaoappppAAFo....",
            "..oamooaaappppppAAdo....",
            "..oaamzzzzppppzzAAdo....",
            "..oAAmZZZZppppZZdddo....",
            "..oyddmmmmppppmmddyo....",
            "...oooooooooooooooo.....",
            "........................",
        ],
    },
    {
        "col": 16,
        "id": "bld_launchpad_2",
        "src_name": "bld_launchpad_2",
        "size": (24, 24),
        "tier": 3,
        "rows": [
            "........................",
            ".....@@.................",
            "....@ka@................",
            "....oaoo................",
            "....oaaaoo..............",
            "....oamoo...............",
            "....oao.................",
            "....oaoooooooo..........",
            "...ooammmmaaaaooo.......",
            "...ohao..ooamxxxaoo.....",
            "...oaoo..ooaxxxxxxo.....",
            "...oamoooooaxxEExxAo....",
            "...oao..ooohxxEExxAo....",
            "...oao..oohamxEExxAo....",
            "..ooaoooohafmxExAAo.....",
            "..oyaoohaaaffxEexyyo....",
            "..oaaoaffaaaxeeepFAo....",
            "..oaaoaFFaoaxepppAFo....",
            "..oamooaaappppppAAdo....",
            "..oaamzzzzppppzzAAdo....",
            "..oAAmZZZZppppZZdddo....",
            "..oyddmmmmppppmmddyo....",
            "...oooooooooooooooo.....",
            "........................",
        ],
    },
    # --- Cols 17..19: Ruins & Construction Blueprint Scaffolds ---
    {
        "col": 17,
        "id": "bld_ruins",
        "src_name": "bld_ruins_0",
        "size": (16, 16),
        "tier": 0,
        "rows": [
            "................",
            "................",
            ".......==.......",
            "......oah=......",
            "....===rRa=.==..",
            "...=Rrrxma==Ra=.",
            "..=rRxxcHxrmRA=.",
            ".==RrxHcCxerRA==",
            ".=RrRxCCCCxrRra=",
            ".=RarxpmmxrrRRA=",
            "=RRrrxpaaxRrrRA=",
            "=RrrRmmAamRRrRA=",
            "=RrRRrrrrrRRrRA=",
            ".=RRrrrrrrrRRA=.",
            "..============..",
            "................",
        ],
    },
    {
        "col": 18,
        "id": "bld_scaffold",
        "src_name": "bld_scaffold_0",
        "size": (12, 12),
        "tier": 0,
        "rows": [
            "............",
            ".oo.cccc.oo.",
            "oaoc....coao",
            "omc.fCCf.cmo",
            "omc.cccc.cmo",
            "oaCCCCCCCCao",
            "omc..cc..cmo",
            "omc.cCCc.cmo",
            "omo.c..c.omo",
            "oaoCCCCCCoao",
            "omo.oooo.omo",
            ".oooooooooo.",
        ],
    },
    {
        "col": 19,
        "id": "bld_scaffold_lg",
        "src_name": "bld_scaffold_lg_0",
        "size": (16, 16),
        "tier": 2,
        "rows": [
            "................",
            "..oo..cccc..oo..",
            ".oaoc......coao.",
            ".omc.ffCCff.cmo.",
            ".omc.c....c.cmo.",
            ".oacCCCCCCCCcao.",
            ".omc.c.cc.c.cmo.",
            ".omc.c.CC.c.cmo.",
            ".oacCCCCCCCCcao.",
            ".omc.c....c.cmo.",
            ".omc.c.cc.c.cmo.",
            ".omo.c....c.omo.",
            ".oaoCCCCCCCCoao.",
            ".omo..oooo..omo.",
            "..oooooooooooo..",
            "................",
        ],
    },
    # --- Cols 20..24: Distinct ROBOT Cybernetic Variants ---
    {
        "col": 20,
        "id": "bld_robot_extractor",
        "src_name": "bld_robot_extractor_0",
        "size": (12, 12),
        "tier": 1,
        "rows": [
            ".....oo.....",
            "....oFFo....",
            "...oaFFao...",
            "..oamXXmao..",
            "..oaAddAAo..",
            ".oamAXXAmAo.",
            ".oa.aXXa.Ao.",
            ".oo.aXXa.oo.",
            ".oRddXXddRo.",
            "oRRRdXXdRRRo",
            "oRRrdeedrRRo",
            ".oooooooooo.",
        ],
    },
    {
        "col": 21,
        "id": "bld_robot_depot",
        "src_name": "bld_robot_depot_0",
        "size": (12, 12),
        "tier": 1,
        "rows": [
            "............",
            "..oooooooo..",
            ".oahFFFFFAo.",
            ".oaFFmmFFAo.",
            ".oaAmXXmAAo.",
            ".oAAdXXdAAo.",
            ".oaFppppFAo.",
            ".oAApXXpAAo.",
            ".oAAppppAAo.",
            ".oAApXXpAAo.",
            "ooAAdppdAAoo",
            ".oooooooooo.",
        ],
    },
    {
        "col": 22,
        "id": "bld_robot_pylon",
        "src_name": "bld_robot_pylon_0",
        "size": (12, 12),
        "tier": 2,
        "rows": [
            ".....oo.....",
            "....oXXo....",
            "...oaffao...",
            "..osAoAoSo..",
            ".osPAXXAPSo.",
            ".osPAXXAPSo.",
            "..ooAXXAoo..",
            "...oAFFAo...",
            "...oaXXao...",
            "..oAAmmAAo..",
            ".oAAddddAAo.",
            ".oooooooooo.",
        ],
    },
    {
        "col": 23,
        "id": "bld_robot_reactor",
        "src_name": "bld_robot_reactor_0",
        "size": (16, 16),
        "tier": 2,
        "rows": [
            "................",
            "......oooo......",
            ".....oaXXao.....",
            "....oaFmmFAo....",
            "...oaFFddFFao...",
            "..ooAddXXddAoo..",
            ".oaFAdXeeXdAFAo.",
            ".oAFmdXeeydAmFo.",
            "oaFFmdXeeXdAmFFo",
            "oAAmmdXXXXdAmAAo",
            ".ooAAdmmmmddAoo.",
            "..oaFFddddFFAo..",
            "..oAAdXXXXdAAo..",
            "..oAAdmmmmddAo..",
            "...oooooooooo...",
            "................",
        ],
    },
    {
        "col": 24,
        "id": "bld_robot_gantry",
        "src_name": "bld_robot_gantry_0",
        "size": (24, 24),
        "tier": 3,
        "rows": [
            "...........oo...........",
            "..........oXXo..........",
            "..........oaao..........",
            "....oo....oFFo..........",
            "...oaao...oFFo..........",
            "...oFFo..oammao...oo....",
            "...oAAo..oaXXao..oAAo...",
            "...oAAooooammao..oFFo...",
            "...oAAammmammaoooAAao...",
            "...oAAo..oammao..oAAo...",
            "...oFFo..oammao..oAAo...",
            "...oAAooooaFFaoooAAao...",
            "...oAAammmammaoooAAao...",
            "...oAAo..oammao..oAAo...",
            "...oAAo..oaXXao..oAAo...",
            "..ooAAooooaFFaoooAAaoo..",
            "..oXAAaammmXXmmaaAAAXo..",
            "..oaAAoaFFoeeooFFoAAAo..",
            "..oaAAoaAAoeeooAAoAAAo..",
            "..oAAdooAAppppAAodAAAo..",
            "..oAAdzzzzppppzzddAAAo..",
            "..oAAdZZZZppppZZddAAAo..",
            "..oXddmmmmppppmmdddddXo.",
            "........................",
        ],
    },
    # --- Cols 25..31: Distinct SPORE Bioluminescent Variants ---
    {
        "col": 25,
        "id": "bld_spore_pod",
        "src_name": "bld_spore_pod_0",
        "size": (12, 12),
        "tier": 0,
        "rows": [
            "............",
            "....OOOO....",
            "...OUUBUO...",
            "..OUBUUUBO..",
            ".OUUUVVUUUO.",
            ".OUBVBBVBUO.",
            ".OUVVBBVVUO.",
            ".OVVJMJMJVO.",
            ".OVVMBBMVVO.",
            ".OVVMBBMVVO.",
            "OOVVJJJJVVOO",
            ".OOOOOOOOOO.",
        ],
    },
    {
        "col": 26,
        "id": "bld_spore_extractor",
        "src_name": "bld_spore_extractor_0",
        "size": (12, 12),
        "tier": 1,
        "rows": [
            "....OOOO....",
            "...OBUUUO...",
            "..OUBMMBUO..",
            "..OUVBBVUO..",
            "...OUBBUO...",
            "..OUJBBJUO..",
            ".OOUJBBJUOO.",
            ".OVVBBBBVVO.",
            ".OVJJBBJJVO.",
            "OOVJMeBMJVOO",
            "OOVJBBBBJVOO",
            ".OOOOOOOOOO.",
        ],
    },
    {
        "col": 27,
        "id": "bld_spore_hive",
        "src_name": "bld_spore_hive_0",
        "size": (12, 12),
        "tier": 1,
        "rows": [
            ".....OO.....",
            "....OBBO....",
            "...OUBBUO...",
            "..OUUVVUUO..",
            ".OUUVBBVUUO.",
            ".OUBVBBVBUO.",
            ".OUVVJJVVUO.",
            ".OVVJBBJVVO.",
            ".OVJJBBJJVO.",
            ".OVVMBBMVVO.",
            "OOVVJJJJVVOO",
            ".OOOOOOOOOO.",
        ],
    },
    {
        "col": 28,
        "id": "bld_spore_spire",
        "src_name": "bld_spore_spire_0",
        "size": (12, 12),
        "tier": 2,
        "rows": [
            "....OOOO....",
            "...OBBBBO...",
            "..OBMBBMBO..",
            ".OUBMBBMBUO.",
            "..OOJBBJOO..",
            "....OVVO....",
            "...OUUBUO...",
            "...OVBBVO...",
            "..OUVBBVUO..",
            "..OVJBBJVO..",
            ".OOVJJJJVOO.",
            ".OOOOOOOOOO.",
        ],
    },
    {
        "col": 29,
        "id": "bld_spore_dome",
        "src_name": "bld_spore_dome_0",
        "size": (16, 16),
        "tier": 2,
        "rows": [
            "................",
            ".....OOOOOO.....",
            "...OOgBBBBgOO...",
            "..OgGBBMMBBGGO..",
            ".OgGMBBHHBBMGjO.",
            ".OgMBHBBBBHBMjO.",
            "OgMBBBBBBBBBBMjO",
            "OGMBBBUUUBBBBMjO",
            "OGGMBBUVUBBBMGjO",
            "OGGUVBBBBBBVUGjO",
            ".OGGUVVBBVVUGjO.",
            ".OUUVVJBBJVVUUO.",
            ".OUUVJBBBBJVUUO.",
            "..OOVVJJJJVVOO..",
            "...OOOOOOOOOO...",
            "................",
        ],
    },
    {
        "col": 30,
        "id": "bld_spore_heart",
        "src_name": "bld_spore_heart_0",
        "size": (16, 16),
        "tier": 2,
        "rows": [
            "................",
            "...OO..OO..OO...",
            "..OBBOOBBOOBBO..",
            "..OUBBOUBBOUBUO.",
            "...OUVBBBBVUO...",
            "..OUBBHHHHBBUO..",
            ".OUUBHHHHHHBUUO.",
            ".OVVBBHHHHBBVVO.",
            "OOVVUBBHHBBVUVOO",
            "OUVVUBBBBBBUVVUO",
            ".OOVVVJBBJVVVOO.",
            "..OUUVJBBJVUUO..",
            "..OVVJJBBJJVVO..",
            "..OOVVJJJJVVOO..",
            "...OOOOOOOOOO...",
            "................",
        ],
    },
    {
        "col": 31,
        "id": "bld_spore_launch",
        "src_name": "bld_spore_launch_0",
        "size": (24, 24),
        "tier": 3,
        "rows": [
            "...........OO...........",
            "..........OBBO..........",
            ".........OBHHBO.........",
            "........OUBHHBUO........",
            "........OUBBBBUO........",
            "........OUVBBVUO........",
            ".....OO..OVBBVO..OO.....",
            "....OBBO.OUVVUO.OBBO....",
            "....OUBOOUJBBJUOOBUO....",
            "....OUVOOUBBBBUOOVUO....",
            "....OVVOUUVBBVUOOVVO....",
            ".....OOUUVJBBJVUUOO.....",
            ".....OUUVVJBBJVVUUO.....",
            "....OUUVJJBBBBJJVUUO....",
            "....OVVJBBBBBBBBJVVO....",
            "...OOVJJBBHHHHBBJJVOO...",
            "...OUVJBBHHHHHHBBJVUO...",
            "..OOUVJBHHHHHHHHBJVUOO..",
            "..OUVVJBBHHHHHHBBJVVUO..",
            "..OVVVJJBBHHHHBBJJVVVO..",
            "..OVVVJJJBBBBBBJJJVVVO..",
            "..OBVJJJJJBBBBJJJJJVBO..",
            "..OOVVJJJJJJJJJJJJVVOO..",
            "........................",
        ],
    },
    # --- Cols 32..33: 12x12 Shuttle Craft (no floor shadow so it flies/rotates cleanly) ---
    {
        "col": 32,
        "id": "craft_shuttle",
        "src_name": "craft_shuttle_0",
        "size": (12, 12),
        "tier": 3,
        "shadow": False,
        "center_y": True,
        "rows": [
            "............",
            "..oo........",
            ".offo.......",
            ".oFFoo......",
            "ooaaffooo...",
            "ceamffggao..",
            "ceamffggao..",
            "ooaaffooo...",
            ".oFFoo......",
            ".offo.......",
            "..oo........",
            "............",
        ],
    },
    {
        "col": 33,
        "id": "craft_shuttle_boost",
        "src_name": "craft_shuttle_1",
        "size": (12, 12),
        "tier": 3,
        "shadow": False,
        "center_y": True,
        "rows": [
            "............",
            "..oo........",
            ".offo.......",
            ".oFFoo......",
            "ooaaffooo...",
            "yeHmffggao..",
            "yeHmffggao..",
            "ooaaffooo...",
            ".oFFoo......",
            ".offo.......",
            "..oo........",
            "............",
        ],
    },
    # --- Cols 34..35: Orbital Shield Pylon (idle cobalt spire & active pulsing cyan dome emitter) ---
    {
        "col": 34,
        "id": "bld_shield_pylon",
        "src_name": "bld_shield_pylon_0",
        "size": (16, 20),
        "tier": 2,
        "rows": [
            "......oooo......",
            ".....o+cH+o.....",
            ".....o+CC+o.....",
            "....oohaaaoo....",
            "...o+gGCCGg+o...",
            "...o+GaccaG+o...",
            "....oamCCmao....",
            "....oamCCmao....",
            "...oaffmmffao...",
            "..oaFFmCCmFFao..",
            "..osSPaCCaPSSo..",
            "..osSPmCCmPSSo..",
            "..oAAmmCCmmAAo..",
            ".oaffAammaAffao.",
            ".oaFFAammaAFFao.",
            ".oammmapppammmAo",
            "oAAmmappppammAAo",
            "oAAdmappppamdAAo",
            "oAdddmammmamdddo",
            ".oooooooooooooo.",
        ],
    },
    {
        "col": 35,
        "id": "bld_shield_pylon_active",
        "src_name": "bld_shield_pylon_1",
        "size": (16, 20),
        "tier": 2,
        "rows": [
            "....ccHHHHcc....",
            "..ccH+cHHc+Hcc..",
            ".cH..o+HH+o..Hc.",
            ".C..oohHHhoo..C.",
            "...o+gCHHCg+o...",
            "...o+cHHHHc+o...",
            "....oacHHcao....",
            "....oamHHmao....",
            "...oaffccffao...",
            "..oaFFcHHcFFao..",
            "..osSPcHHcPSSo..",
            "..osSPmHHmPSSo..",
            "..oAAmmccmmAAo..",
            ".oaffAammaAffao.",
            ".oaFFAamcaAFFao.",
            ".oammmapppammmAo",
            "oAAmmappppammAAo",
            "oAAdmappppamdAAo",
            "oAdddmammmamdddo",
            ".oooooooooooooo.",
        ],
    },
    # --- Cols 36..37: Tier 4 Quantum Gate (dormant obsidian/violet ring & active singularity portal) ---
    {
        "col": 36,
        "id": "bld_quantum_gate",
        "src_name": "bld_quantum_gate_0",
        "size": (16, 20),
        "tier": 4,
        "rows": [
            "....oOooooOo....",
            "...O^&;mm;&^O...",
            "..O^&;O++O;^:O..",
            ".O^&O+8998+O::O.",
            ".O^;O......O::O.",
            "oafO........OFAo",
            "oaCO........OCAo",
            "oF;O........O:Ao",
            "oF;O........O:Ao",
            ".O;O........O:O.",
            ".O:;O......O::O.",
            "..O:;O....O::O..",
            ".oaa;^OOOO^:aAo.",
            ".oahmm;;;;mmAAo.",
            ".oaffmppppmfFAo.",
            "oahmmaapppammmAo",
            "oaffmappppammFAo",
            "oAFFCmapppamCAAo",
            "oAdddmmmmmmddAAo",
            ".oooooooooooooo.",
        ],
    },
    {
        "col": 37,
        "id": "bld_quantum_gate_active",
        "src_name": "bld_quantum_gate_1",
        "size": (16, 20),
        "tier": 4,
        "rows": [
            "....oOooooOo....",
            "...O^cHHHHc^O...",
            "..O^[cO++Oc]^O..",
            ".O^[O+cHHc+O]^O.",
            ".O^cOc[<<]cO]cO.",
            "oafO[ccHH<c]OFAo",
            "oaCOcH<<_[c]OCAo",
            "oFcO[c_<H<]]OcAo",
            "oFcO]<H__[c]OcAo",
            ".OcO[]cHH<<]O]O.",
            ".O^]Oc[<<]]O^:O.",
            "..O^]O[cc]O^:O..",
            ".oaac^O++O^caAo.",
            ".oahmm[cc]mmAAo.",
            ".oaffmpCCpmfFAo.",
            "oahmmaapppammmAo",
            "oaffmappppammFAo",
            "oAFFcmapppamcAAo",
            "oAdddmmmmmmddAAo",
            ".oooooooooooooo.",
        ],
    },
]


# ---------------------------------------------------------------------------
# 2. UNITS (8x8 crisp 1:1 cells, material-tinted edges, NO baked '~' shadow!)
# ---------------------------------------------------------------------------
UNIT_SPECS: List[dict] = [
    # --- HUMAN & WANDERERS (cols 0..7, 22..23) ---
    {
        "col": 0,
        "id": "human_walk_a",
        "src_name": "unit_human_walk_a",
        "size": (8, 8),
        "rows": [
            "..oooo..",
            ".offffo.",
            ".ofccco.",
            "#pffFFo.",
            ".#pFFm#.",
            ".#FooF#.",
            ".##..##.",
            "........",
        ],
    },
    {
        "col": 1,
        "id": "human_walk_b",
        "src_name": "unit_human_walk_b",
        "size": (8, 8),
        "rows": [
            "..oooo..",
            ".offffo.",
            ".ofccco.",
            "#pffFFo.",
            ".#pFF##.",
            "..#FF#..",
            "..####..",
            "........",
        ],
    },
    {
        "col": 2,
        "id": "human_work",
        "src_name": "unit_human_work",
        "size": (8, 8),
        "rows": [
            "..oooo..",
            ".offffo.",
            ".ofccco.",
            "#pffmmco",
            ".#pFFo##",
            ".#FooF#.",
            ".##..##.",
            "........",
        ],
    },
    {
        "col": 3,
        "id": "human_cargo",
        "src_name": "unit_human_cargo",
        "size": (8, 8),
        "rows": [
            "..oooo..",
            ".offffo.",
            ".ofccco.",
            "#pff####",
            ".#pfozz#",
            ".#FooZZ#",
            ".##..###",
            "........",
        ],
    },
    {
        "col": 4,
        "id": "human_soldier_a",
        "src_name": "unit_human_soldier_a",
        "size": (8, 8),
        "rows": [
            "..oooo..",
            ".oaFFao.",
            ".oaccco.",
            "opffmooo",
            ".opFFmco",
            ".#FooF#o",
            ".##..##.",
            "........",
        ],
    },
    {
        "col": 5,
        "id": "human_soldier_b",
        "src_name": "unit_human_soldier_b",
        "size": (8, 8),
        "rows": [
            "..oooo..",
            ".oaFFao.",
            ".oaccco.",
            "opffmooo",
            ".opFFmyo",
            "..#FF#oo",
            "..####..",
            "........",
        ],
    },
    {
        "col": 6,
        "id": "human_engineer",
        "src_name": "unit_human_engineer",
        "size": (8, 8),
        "rows": [
            "..@@@@..",
            ".@zzzz@.",
            ".ofccco.",
            "#pffmmo.",
            ".#pFFm#.",
            ".#FooF#.",
            ".##..##.",
            "........",
        ],
    },
    {
        "col": 7,
        "id": "human_jetpack",
        "src_name": "unit_human_jetpack",
        "size": (8, 8),
        "rows": [
            "..oooo..",
            ".offffo.",
            ".ofccco.",
            "opffFFo.",
            "eypFFmo.",
            ".eoFF#..",
            "..####..",
            "........",
        ],
    },
    # --- ROBOT (cols 8..14) ---
    {
        "col": 8,
        "id": "robot_drone_a",
        "src_name": "unit_robot_drone_a",
        "size": (8, 8),
        "rows": [
            "..oooo..",
            ".oammao.",
            "oaFdXdro",
            "oaFFmFAo",
            ".oaddao.",
            "..oeyo..",
            "........",
            "........",
        ],
    },
    {
        "col": 9,
        "id": "robot_drone_b",
        "src_name": "unit_robot_drone_b",
        "size": (8, 8),
        "rows": [
            "........",
            "..oooo..",
            ".oammao.",
            "oaFXXXao",
            "oaFFmFAo",
            ".oaddao.",
            "..oeeo..",
            "........",
        ],
    },
    {
        "col": 10,
        "id": "robot_walker_a",
        "src_name": "unit_robot_walker_a",
        "size": (8, 8),
        "rows": [
            ".oooooo.",
            "oadXXdao",
            "oaFFFFao",
            "oammmmao",
            ".oaddao.",
            ".oaooao.",
            ".oo..oo.",
            "........",
        ],
    },
    {
        "col": 11,
        "id": "robot_walker_b",
        "src_name": "unit_robot_walker_b",
        "size": (8, 8),
        "rows": [
            ".oooooo.",
            "oadXXdao",
            "oaFFFFao",
            "oammmyeo",
            ".oaddaoo",
            "..oAAo..",
            "..oooo..",
            "........",
        ],
    },
    {
        "col": 12,
        "id": "robot_heavy_a",
        "src_name": "unit_robot_heavy_a",
        "size": (8, 8),
        "rows": [
            ".oooooo.",
            "oaFdXFao",
            "oFFmmFFo",
            "oamXXamo",
            "ooAAAAoo",
            ".oaooao.",
            ".oo..oo.",
            "........",
        ],
    },
    {
        "col": 13,
        "id": "robot_heavy_b",
        "src_name": "unit_robot_heavy_b",
        "size": (8, 8),
        "rows": [
            ".oooooo.",
            "oaFdXFao",
            "oFFmmFFo",
            "oamXXaXy",
            "ooAAAAoo",
            "..oAAo..",
            "..oooo..",
            "........",
        ],
    },
    {
        "col": 14,
        "id": "robot_cargo",
        "src_name": "unit_robot_cargo",
        "size": (8, 8),
        "rows": [
            ".oooooo.",
            "oadXXdao",
            "oaFF####",
            "oamm#zy#",
            ".oad#ZZ#",
            ".oao#a##",
            ".oo..oo.",
            "........",
        ],
    },
    # --- SPORE (cols 15..19) ---
    {
        "col": 15,
        "id": "spore_crawler_a",
        "src_name": "unit_spore_crawler_a",
        "size": (8, 8),
        "rows": [
            "........",
            "..OOOO..",
            ".OOBBOO.",
            "OOUUBUUO",
            "OUUUVVUO",
            ".OOUVOO.",
            ".O.OO.O.",
            "........",
        ],
    },
    {
        "col": 16,
        "id": "spore_crawler_b",
        "src_name": "unit_spore_crawler_b",
        "size": (8, 8),
        "rows": [
            "........",
            "..OOOO..",
            ".OBBBBO.",
            "OOUUBUUO",
            "OUVVUUUO",
            ".OVVUUO.",
            "..O..O..",
            "........",
        ],
    },
    {
        "col": 17,
        "id": "spore_stalker_a",
        "src_name": "unit_spore_stalker_a",
        "size": (8, 8),
        "rows": [
            "..OOOO..",
            ".OUBBUO.",
            ".OBUUBO.",
            "OOUVVUOO",
            "O.OVVO.O",
            "..OUOO..",
            ".OO..OO.",
            "........",
        ],
    },
    {
        "col": 18,
        "id": "spore_stalker_b",
        "src_name": "unit_spore_stalker_b",
        "size": (8, 8),
        "rows": [
            "..OOOO..",
            ".OUBBUO.",
            ".OBUUBOO",
            "OOUVVUBO",
            ".O.VVO.O",
            "..OUOO..",
            "..OOOO..",
            "........",
        ],
    },
    {
        "col": 19,
        "id": "spore_cargo",
        "src_name": "unit_spore_cargo",
        "size": (8, 8),
        "rows": [
            "..OOOO..",
            ".OUBBUO.",
            ".OUUUOOO",
            "OOUVOBBO",
            ".OVUOBZO",
            ".OUOOUUO",
            ".OO..OO.",
            "........",
        ],
    },
    # --- CRYSTAL MUTANT & SPECIALS (cols 20..23) ---
    {
        "col": 20,
        "id": "mutant_crystal_a",
        "src_name": "unit_mutant_crystal_a",
        "size": (8, 8),
        "rows": [
            "...++...",
            "..+cH+..",
            ".+cHHc+.",
            "o+cmmH+o",
            "oamHcmm+",
            ".oaooao.",
            ".oo..oo.",
            "........",
        ],
    },
    {
        "col": 21,
        "id": "mutant_crystal_b",
        "src_name": "unit_mutant_crystal_b",
        "size": (8, 8),
        "rows": [
            "...++...",
            "..+HH+..",
            ".+cHHc++",
            "o+cmmHc+",
            "oamHcmm+",
            "..oAAo..",
            "..oooo..",
            "........",
        ],
    },
    {
        "col": 22,
        "id": "human_farmer",
        "src_name": "unit_human_farmer",
        "size": (8, 8),
        "rows": [
            "..TTTT..",
            ".TffffT.",
            ".ofccco.",
            "TlffFFo.",
            ".TlFFl#.",
            ".#FooF#.",
            ".##..##.",
            "........",
        ],
    },
    {
        "col": 23,
        "id": "cargo_pip",
        "src_name": "unit_cargo_pip",
        "size": (8, 8),
        "rows": [
            "........",
            "........",
            "..####..",
            ".#zzzz#.",
            ".#zZZz#.",
            ".#ZZZZ#.",
            "..####..",
            "........",
        ],
    },
]


# ---------------------------------------------------------------------------
# 3. FLORA & LANDMARKS (12x12 cells; material-tinted edges, NO baked '~' shadow!)
# ---------------------------------------------------------------------------
FLORA_SPECS: List[dict] = [
    {
        "col": 0,
        "id": "flora_tree_lush",
        "src_name": "flora_tree_lush",
        "size": (12, 12),
        "rows": [
            "....TTTT....",
            "..TTlYlLTT..",
            ".TlYlllLLLT.",
            ".TlllLLLLDT.",
            ".TlLLLLLDDT.",
            "..TLLDDDDT..",
            "...##NN##...",
            "....#nN#....",
            "....#nN#....",
            "....#nN#....",
            "...##NN##...",
            "............",
        ],
    },
    {
        "col": 1,
        "id": "flora_shroom_lush",
        "src_name": "flora_shroom_lush",
        "size": (12, 12),
        "rows": [
            "............",
            "...******...",
            "..*MMBBMM*..",
            ".*MMMMBJMM*.",
            ".*MBMJJBMJ*.",
            ".*JJJJJJJJ*.",
            "..===%%===..",
            "....=%%=....",
            "....=%%=....",
            "....=%%=....",
            "...==%%==...",
            "............",
        ],
    },
    {
        "col": 2,
        "id": "flora_rust_scrub",
        "src_name": "flora_rust_scrub",
        "size": (12, 12),
        "rows": [
            "............",
            "....TTTT....",
            "....T65T....",
            ".TTT.54.TTT.",
            "T65T.65.T54T",
            "T54TT54TT54T",
            ".T45554544T.",
            "..###54###..",
            "....#54#....",
            "....#54#....",
            "...##44##...",
            "............",
        ],
    },
    {
        "col": 3,
        "id": "flora_crystal_small",
        "src_name": "flora_crystal_small",
        "size": (12, 12),
        "rows": [
            "............",
            "............",
            "....++++....",
            "....+00+....",
            "..+++09+++..",
            ".+00+09+00+.",
            ".+09+98+98+.",
            ".+98+98+87+.",
            ".+87+87+77+.",
            ".+77777777+.",
            "..++++++++..",
            "............",
        ],
    },
    {
        "col": 4,
        "id": "flora_crystal_tall",
        "src_name": "flora_crystal_tall",
        "size": (12, 12),
        "rows": [
            "...+++......",
            "...+0+..+++.",
            "..+00+..+0+.",
            "..+09+.+00+.",
            "..+09+.+09+.",
            "..+98+.+98+.",
            ".++98+++98+.",
            "+0+87+0+87+.",
            "+9+77+9+77+.",
            "+877777777+.",
            ".+++++++++..",
            "............",
        ],
    },
    {
        "col": 5,
        "id": "flora_boulder",
        "src_name": "flora_boulder",
        "size": (12, 12),
        "rows": [
            "............",
            "............",
            "....====....",
            "..==rrRR==..",
            ".=rrRRRRdd=.",
            ".=rRRRddRd=.",
            "=rRRdReeRdd=",
            "=rRdddeRddd=",
            "=RRdddxdddd=",
            ".=xdddddxdo.",
            "..========..",
            "............",
        ],
    },
    {
        "col": 6,
        "id": "flora_magma_vent",
        "src_name": "flora_magma_vent",
        "size": (12, 12),
        "rows": [
            "............",
            "....eyye....",
            "...@eyye@...",
            "...@ReeR@...",
            "..@RreerR@..",
            "..=RRddRR=..",
            ".=RRdeedRR=.",
            ".=RddEEdRd=.",
            "=RRddEedddd=",
            "=RRdddddddd=",
            ".==========.",
            "............",
        ],
    },
    {
        "col": 7,
        "id": "flora_frost_pine",
        "src_name": "flora_frost_pine",
        "size": (12, 12),
        "rows": [
            ".....TT.....",
            "....+33+....",
            "...+3211T...",
            "...+3321T...",
            "..+332211T..",
            ".T22221111T.",
            "..TT3321TT..",
            ".T33222111T.",
            "T2222111111T",
            ".###NNN###..",
            "....#nN#....",
            "............",
        ],
    },
    # --- Stage 2.5 Flora Columns (cols 8..13) ---
    {
        "col": 8,
        "id": "flora_tree_charred",
        "src_name": "flora_tree_charred",
        "size": (12, 12),
        "rows": [
            "....#..#....",
            "..#@xe@#@@..",
            ".@xeRxxRxE@.",
            ".#xRRxxRxx#.",
            "..##xRxE@@..",
            "....#Rx#....",
            "....#Rx#....",
            "....#Ex#....",
            "....#xx#....",
            "...#RxxR#...",
            "...######...",
            "............",
        ],
    },
    {
        "col": 9,
        "id": "flora_tree_ash",
        "src_name": "flora_tree_ash",
        "size": (12, 12),
        "rows": [
            "............",
            "............",
            "............",
            "....=..=....",
            "...=r==r=...",
            "....=rR=....",
            "....=RR=....",
            "....=RR=....",
            "...=rRRr=...",
            "..=rrRRrr=..",
            "..########..",
            "............",
        ],
    },
    {
        "col": 10,
        "id": "flora_spore_pod",
        "src_name": "flora_spore_pod",
        "size": (12, 12),
        "rows": [
            "............",
            "....OOOO....",
            "...OBHHBO...",
            "..OUBBBBUO..",
            ".OUBBHHBBUO.",
            ".OUVBBBBVUO.",
            ".OVVUBBUVVO.",
            "..OVJJJJVO..",
            "..OOVBBVOO..",
            "...OVJJVO...",
            "...OOOOOO...",
            "............",
        ],
    },
    {
        "col": 11,
        "id": "flora_crystal_cluster",
        "src_name": "flora_crystal_cluster",
        "size": (12, 12),
        "rows": [
            "............",
            "....++++....",
            "....+0H+....",
            "..+++09+....",
            ".+0H+98+++..",
            ".+09+87+00+.",
            "++98rRRr98++",
            "=amRRrRRrRm=",
            "=mRRrRRrRRA=",
            "=ARRRRRRRdd=",
            ".==========.",
            "............",
        ],
    },
    {
        "col": 12,
        "id": "flora_lush_sapling",
        "src_name": "flora_lush_sapling",
        "size": (12, 12),
        "rows": [
            "............",
            "............",
            "............",
            "............",
            "....TTTT....",
            "...TlYlLT...",
            "..TllLLLDT..",
            "...TTLLTT...",
            "....#nN#....",
            "....#nN#....",
            "...##NN##...",
            "............",
        ],
    },
    {
        "col": 13,
        "id": "flora_burning_bush",
        "src_name": "flora_burning_bush",
        "size": (12, 12),
        "rows": [
            "............",
            "....ey.e....",
            "...eyyeE....",
            "..@eyyye@...",
            ".@EeyeyeE@..",
            ".#RxeeexR#..",
            "=RRxEeeRxR=.",
            "=RxxRRxxxR=.",
            ".=Rxxxxxx=..",
            ".#xxxRxxx#..",
            "..########..",
            "............",
        ],
    },
]


# ---------------------------------------------------------------------------
# 4. FX REACTION & STATUS ICON STRIPS (8x8 cells x 16 cols = 128x8, zero digits!)
# ---------------------------------------------------------------------------
FX_STRIP_SPECS: List[dict] = [
    {
        "col": 0,
        "id": "dodge",
        "src_name": "fx_strip_dodge",
        "size": (8, 8),
        "rows": [
            "........",
            ".C..3c..",
            "..C..3c.",
            ".C3c.cHc",
            "..C..3c.",
            ".C..3c..",
            "........",
            "........",
        ],
    },
    {
        "col": 1,
        "id": "block",
        "src_name": "fx_strip_block",
        "size": (8, 8),
        "rows": [
            "......y.",
            ".ooooHy.",
            "ohaaHy..",
            "ohmay...",
            ".oaao...",
            "..oo....",
            "........",
            "........",
        ],
    },
    {
        "col": 2,
        "id": "happy",
        "src_name": "fx_strip_happy",
        "size": (8, 8),
        "rows": [
            ".TT..TT.",
            "T!zTTz!T",
            "T!yzyz!T",
            "T!zzzz!T",
            ".T?zz?T.",
            "..T??T..",
            "...TT...",
            "........",
        ],
    },
    {
        "col": 3,
        "id": "angry",
        "src_name": "fx_strip_angry",
        "size": (8, 8),
        "rows": [
            "..@@@@..",
            "..@kX@..",
            "..@XX@..",
            "..@XX@..",
            "..@@@@..",
            "..@XX@..",
            "..@@@@..",
            "........",
        ],
    },
    {
        "col": 4,
        "id": "food",
        "src_name": "fx_strip_food",
        "size": (8, 8),
        "rows": [
            "...TT!..",
            "..##T#..",
            ".#yzzZ#.",
            "#yzzzzZ#",
            "#zzzzZZ#",
            ".#ZZZZ#.",
            "..####..",
            "........",
        ],
    },
    {
        "col": 5,
        "id": "shield",
        "src_name": "fx_strip_shield",
        "size": (8, 8),
        "rows": [
            "..++++..",
            ".+HccC+.",
            "+HcgGCc+",
            "+ccGGCc+",
            "+CcGGCC+",
            ".+CCCC+.",
            "..++++..",
            "........",
        ],
    },
    {
        "col": 6,
        "id": "lvlup",
        "src_name": "fx_strip_lvlup",
        "size": (8, 8),
        "rows": [
            "...z....",
            "..zHz...",
            ".zyHHyz.",
            "zHHHHHHz",
            ".zyHHyz.",
            "..zHz...",
            "...z....",
            "........",
        ],
    },
    {
        "col": 7,
        "id": "mutate",
        "src_name": "fx_strip_mutate",
        "size": (8, 8),
        "rows": [
            ".((..BB.",
            ".(B..B(.",
            "..()B)..",
            "...()...",
            "..B)()..",
            ".B(..().",
            ".BB..((.",
            "........",
        ],
    },
    {
        "col": 8,
        "id": "pact",
        "src_name": "fx_strip_pact",
        "size": (8, 8),
        "rows": [
            ".+++....",
            "+Hcc+...",
            "+c.c@@..",
            "+cH}y}@.",
            ".++}.}@.",
            "..@}}}@.",
            "...@@@..",
            "........",
        ],
    },
    {
        "col": 9,
        "id": "war",
        "src_name": "fx_strip_war",
        "size": (8, 8),
        "rows": [
            ".@....@.",
            "@/@..@/@",
            ".@-@@-@.",
            "..@yy@..",
            "..@ee@..",
            ".@-@@-@.",
            "@}@..@}@",
            ".@....@.",
        ],
    },
    {
        "col": 10,
        "id": "rebel",
        "src_name": "fx_strip_rebel",
        "size": (8, 8),
        "rows": [
            ".@.@@.@.",
            "@{@,,@{@",
            "@{{,,{{@",
            ".@{,,{@.",
            "..@,,@..",
            ".@{,,{@.",
            "..@@@@..",
            "........",
        ],
    },
    {
        "col": 11,
        "id": "portal",
        "src_name": "fx_strip_portal",
        "size": (8, 8),
        "rows": [
            "..OOOO..",
            ".O[ccHO.",
            "OcH<_]cO",
            "Oc_<<_]O",
            "O[]_<]cO",
            ".O)]]cO.",
            "..OOOO..",
            "........",
        ],
    },
    {
        "col": 12,
        "id": "plot_war",
        "src_name": "fx_strip_plot_war",
        "size": (8, 8),
        "rows": [
            ".o....o.",
            "oh@..@ho",
            ".a/--/a.",
            "..@yy@..",
            ".@a--a@.",
            "@z@..@z@",
            ".@....@.",
            "........",
        ],
    },
    {
        "col": 13,
        "id": "plot_pact",
        "src_name": "fx_strip_plot_pact",
        "size": (8, 8),
        "rows": [
            ".#wwww#.",
            "#wCCCCw#",
            "#wWWWWw#",
            "#W@@@@W#",
            "#W@},@W#",
            ".#W@@W#.",
            "..####..",
            "........",
        ],
    },
    {
        "col": 14,
        "id": "plot_rebel",
        "src_name": "fx_strip_plot_rebel",
        "size": (8, 8),
        "rows": [
            "...@@...",
            "..@,,@..",
            ".@/{/@..",
            "..@--@..",
            "oo.@@.oo",
            "oha..aho",
            ".oo..oo.",
            "........",
        ],
    },
    {
        "col": 15,
        "id": "crown_banner",
        "src_name": "fx_strip_crown_banner",
        "size": (8, 8),
        "rows": [
            ".@.@@.@.",
            "@,@,,@,@",
            "@z@zz@Z@",
            "@zzHczZ@",
            "@zzCCZZ@",
            "@ZZZZZZ@",
            ".@@@@@@.",
            "........",
        ],
    },
]


def render_sprite(spec: dict) -> Tuple[Image.Image, Image.Image]:
    """Converts an ASCII pixel map into native RGBA albedo and mask images."""
    w, h = spec["size"]
    rows: List[str] = spec["rows"]
    if len(rows) != h:
        raise ValueError(f"{spec['src_name']}: expected {h} rows, got {len(rows)}")

    albedo = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    mask = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    a_px = albedo.load()
    m_px = mask.load()

    for y, row in enumerate(rows):
        if len(row) != w:
            raise ValueError(f"{spec['src_name']} row {y}: expected len {w}, got {len(row)}")
        for x, ch in enumerate(row):
            if ch not in PALETTE:
                raise ValueError(f"{spec['src_name']} ({x},{y}): unknown symbol {ch!r}")
            rgba, m_rgb = PALETTE[ch]
            a_px[x, y] = rgba
            if rgba[3] > 0:
                m_px[x, y] = (m_rgb[0], m_rgb[1], m_rgb[2], 255)
            else:
                m_px[x, y] = (0, 0, 0, 0)

    return albedo, mask


def bake_se_contact_shadow(
    atlas_img: Image.Image,
    mask_img: Image.Image,
    cell_x: int,
    cell_y: int,
    cell_w: int,
    cell_h: int,
) -> None:
    """Bakes a 1-2px SE translucent grounded contact shadow under a building cell."""
    a_px = atlas_img.load()
    m_px = mask_img.load()

    # Find lowest non-transparent pixel inside this cell
    base_y = -1
    solid_points: List[Tuple[int, int]] = []
    for y in range(cell_y, cell_y + cell_h):
        for x in range(cell_x, cell_x + cell_w):
            if a_px[x, y][3] > 128:
                solid_points.append((x, y))
                if y > base_y:
                    base_y = y

    if base_y < 0:
        return

    # Only ground-contact skirt (bottom 3 rows of structure) casts SE shadow
    shadow_targets: set[Tuple[int, int]] = set()
    for x, y in solid_points:
        if y >= base_y - 2:
            for dx, dy in ((0, 1), (1, 1), (2, 1), (1, 0)):
                tx = x + dx
                ty = y + dy
                if cell_x <= tx < cell_x + cell_w and cell_y <= ty < cell_y + cell_h:
                    if a_px[tx, ty][3] == 0:
                        shadow_targets.add((tx, ty))

    for tx, ty in shadow_targets:
        a_px[tx, ty] = SHADOW_RGBA
        m_px[tx, ty] = (0, 0, 0, 255)


def validate_pair(name: str, albedo: Image.Image, mask: Image.Image) -> None:
    """Enforces zero #000000, non-emissive <= 0.95 (242), and mask/albedo sync."""
    w, h = albedo.size
    a_px = albedo.load()
    m_px = mask.load()
    opaque = 0

    for y in range(h):
        for x in range(w):
            r, g, b, a = a_px[x, y]
            mr, mg, mb, ma = m_px[x, y]
            if a == 0:
                if ma != 0:
                    raise AssertionError(f"{name} ({x},{y}): mask alpha non-zero on transparent px")
                continue
            opaque += 1
            if (r, g, b) == (0, 0, 0):
                raise AssertionError(f"{name} ({x},{y}): forbidden pure black #000000")
            if mg == 0 and max(r, g, b) > 242:
                raise AssertionError(
                    f"{name} ({x},{y}): non-emissive RGB {(r, g, b)} > 242 (exceeds 0.95 HDR gate)"
                )
            if ma != 255:
                raise AssertionError(f"{name} ({x},{y}): visible albedo missing mask alpha 255")

    if opaque == 0:
        raise AssertionError(f"{name}: sprite is completely empty")


def build_atlas_set(
    atlas_name: str,
    specs: List[dict],
    cell_w: int,
    cell_h: int,
    motion_mode: int,
    bake_building_shadows: bool,
    extra_manifest: dict,
    forbid_shadow_tokens: bool = False,
) -> dict:
    """Renders, validates, packs, and writes PNG + Mask + JSON for one atlas."""
    sorted_specs = sorted(specs, key=lambda s: s["col"])
    cols = len(sorted_specs)
    atlas_w = cols * cell_w
    atlas_h = cell_h

    atlas_img = Image.new("RGBA", (atlas_w, atlas_h), (0, 0, 0, 0))
    mask_img = Image.new("RGBA", (atlas_w, atlas_h), (0, 0, 0, 0))

    manifest_entries = []

    for idx, spec in enumerate(sorted_specs):
        if spec["col"] != idx:
            raise AssertionError(f"{atlas_name}: column gap at index {idx}: got {spec['col']}")
        if forbid_shadow_tokens and "~" in "".join(spec["rows"]):
            raise AssertionError(f"{atlas_name}: forbidden '~' baked shadow pixel in {spec['id']}")

        albedo, mask = render_sprite(spec)
        validate_pair(spec["src_name"], albedo, mask)

        albedo.save(SRC_DIR / f"{spec['src_name']}.png")
        mask.save(SRC_DIR / f"{spec['src_name']}_mask.png")

        sw, sh = spec["size"]
        ox_rel = (cell_w - sw) // 2
        if spec.get("center_y", False):
            oy_rel = (cell_h - sh) // 2
        elif bake_building_shadows and sh < cell_h:
            # Leave 1px bottom row inside cell for grounded SE contact shadow
            oy_rel = cell_h - sh - 1
        else:
            oy_rel = cell_h - sh

        ox = idx * cell_w + ox_rel
        oy = oy_rel
        atlas_img.paste(albedo, (ox, oy))
        mask_img.paste(mask, (ox, oy))

        if bake_building_shadows and spec.get("shadow", True):
            bake_se_contact_shadow(atlas_img, mask_img, idx * cell_w, 0, cell_w, cell_h)

        manifest_entries.append(
            {
                "col": idx,
                "id": spec["id"],
                "src": f"assets/src_sprites/{spec['src_name']}.png",
                "native_size": [sw, sh],
                "tier": spec.get("tier", 0),
                "cell_px": [idx * cell_w, 0, cell_w, cell_h],
                "sprite_offset_in_cell": [ox_rel, oy_rel],
                "uv_rect": [
                    round((idx * cell_w) / atlas_w, 6),
                    0.0,
                    round(cell_w / atlas_w, 6),
                    1.0,
                ],
            }
        )

    validate_pair(atlas_name, atlas_img, mask_img)

    atlas_path = ATLAS_DIR / f"{atlas_name}.png"
    mask_path = ATLAS_DIR / f"{atlas_name}_mask.png"
    json_path = ATLAS_DIR / f"{atlas_name}.json"

    atlas_img.save(atlas_path)
    mask_img.save(mask_path)

    manifest = {
        "atlas_path": f"res://assets/atlases/{atlas_name}.png",
        "mask_path": f"res://assets/atlases/{atlas_name}_mask.png",
        "atlas_size": [atlas_w, atlas_h],
        "cell_size": [cell_w, cell_h],
        "atlas_cols": cols,
        "shader_mode": 3,
        "shader_uniforms": {
            "sprite_mode": 3,
            "motion_mode": motion_mode,
            "atlas_cols": cols,
            "sprite_size": [cell_w, cell_h],
            "mask_tex": f"res://assets/atlases/{atlas_name}_mask.png",
            "hdr_emissive": 2.6,
        },
        **extra_manifest,
        "cells": manifest_entries,
    }
    json_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest


def build_all() -> Dict[str, dict]:
    SRC_DIR.mkdir(parents=True, exist_ok=True)
    ATLAS_DIR.mkdir(parents=True, exist_ok=True)

    buildings = build_atlas_set(
        atlas_name="buildings_atlas",
        specs=BUILDING_SPECS,
        cell_w=BLD_CELL_W,
        cell_h=BLD_CELL_H,
        motion_mode=0,
        bake_building_shadows=False,
        forbid_shadow_tokens=True,
        extra_manifest={
            "primary_columns": {
                "BLD_CAMPFIRE": 0,
                "BLD_TENT": 1,
                "BLD_DRILL": 2,
                "BLD_DEPOT": 3,
                "BLD_SOLAR_ARRAY": 4,
                "BLD_BIODOME": 5,
                "BLD_FUSION_REACTOR": 6,
                "BLD_LAUNCHPAD": 7,
            },
            "variant_columns": {
                "BLD_CAMPFIRE_1": 8,
                "BLD_TENT_POD": 9,
                "BLD_DRILL_1": 10,
                "BLD_DEPOT_1": 11,
                "BLD_SOLAR_ARRAY_1": 12,
                "BLD_BIODOME_DAMAGED": 13,
                "BLD_FUSION_REACTOR_1": 14,
                "BLD_LAUNCHPAD_EMPTY": 15,
                "BLD_LAUNCHPAD_SCORCHED": 16,
                "BLD_RUINS": 17,
                "BLD_SCAFFOLD": 18,
                "BLD_SCAFFOLD_LG": 19,
                "BLD_ROBOT_EXTRACTOR": 20,
                "BLD_ROBOT_DEPOT": 21,
                "BLD_ROBOT_PYLON": 22,
                "BLD_ROBOT_REACTOR": 23,
                "BLD_ROBOT_GANTRY": 24,
                "BLD_SPORE_POD": 25,
                "BLD_SPORE_EXTRACTOR": 26,
                "BLD_SPORE_HIVE": 27,
                "BLD_SPORE_SPIRE": 28,
                "BLD_SPORE_DOME": 29,
                "BLD_SPORE_HEART": 30,
                "BLD_SPORE_LAUNCH": 31,
                "CRAFT_SHUTTLE": 32,
                "CRAFT_SHUTTLE_BOOST": 33,
                "BLD_SHIELD_PYLON": 34,
                "BLD_SHIELD_PYLON_ACTIVE": 35,
                "BLD_QUANTUM_GATE": 36,
                "BLD_QUANTUM_GATE_ACTIVE": 37,
            },
        },
    )

    units = build_atlas_set(
        atlas_name="units_atlas",
        specs=UNIT_SPECS,
        cell_w=UNIT_CELL_W,
        cell_h=UNIT_CELL_H,
        motion_mode=2,
        bake_building_shadows=False,
        forbid_shadow_tokens=True,
        extra_manifest={
            "columns": {spec["id"].upper(): spec["col"] for spec in UNIT_SPECS},
        },
    )

    flora = build_atlas_set(
        atlas_name="flora_atlas",
        specs=FLORA_SPECS,
        cell_w=FLORA_CELL_W,
        cell_h=FLORA_CELL_H,
        motion_mode=1,
        bake_building_shadows=False,
        forbid_shadow_tokens=True,
        extra_manifest={
            "columns": {spec["id"].upper(): spec["col"] for spec in FLORA_SPECS},
        },
    )

    fx_strips = build_atlas_set(
        atlas_name="fx_strips_atlas",
        specs=FX_STRIP_SPECS,
        cell_w=FX_CELL_W,
        cell_h=FX_CELL_H,
        motion_mode=0,
        bake_building_shadows=False,
        forbid_shadow_tokens=True,
        extra_manifest={
            "columns": {spec["id"].upper(): spec["col"] for spec in FX_STRIP_SPECS},
        },
    )

    return {"buildings": buildings, "units": units, "flora": flora, "fx_strips": fx_strips}


def main() -> int:
    results = build_all()
    for name, m in results.items():
        w, h = m["atlas_size"]
        cw, ch = m["cell_size"]
        cols = m["atlas_cols"]
        print(f"BUILD_ATLAS_OK name={name} size={w}x{h} cell={cw}x{ch} cols={cols}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
