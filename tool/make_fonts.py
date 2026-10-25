"""Rebuilds the app's font files from the two original variable fonts.

    python3 -m pip install fonttools brotli      (once)
    python3 tool/make_fonts.py

Two things happen to each font:
1. A variable font starts at its thinnest weight, so one file is cut into a
   file per weight (a "static" file) that really is bold, medium and so on.
2. Only the letters the app prints are kept (plain Latin and a few symbols).
   The app downloads every font file before it draws its first screen, so a
   full 340 KB file costs about a second on a slow line; the same file with
   only the letters in use is about 25 KB. Sinhala and Tamil text uses the
   browser's own fallback fonts, as before.

The originals stay in assets/fonts (Outfit-Variable.ttf and
Montserrat/Montserrat-VariableFont_wght.ttf). Add a character that is not in
KEEP and it will draw in a fallback font until you add it here and run this.
"""
import os
from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

KEEP = (
    list(range(0x20, 0x7F))          # basic Latin
    + list(range(0xA0, 0x100))       # Latin-1 (copyright, middle dot, multiplication)
    + list(range(0x2010, 0x2028))    # dashes, quotes, bullet, ellipsis
    + [0x2030, 0x2039, 0x203A, 0x2122, 0x2190, 0x2191, 0x2192, 0x2193, 0x2212, 0x20A8, 0x20AC, 0x2794, 0x279D]
)

JOBS = [
    ("assets/fonts/Outfit-Variable.ttf", "assets/fonts/Outfit", "Outfit",
     {300: "Light", 400: "Regular", 500: "Medium", 600: "SemiBold", 700: "Bold", 800: "ExtraBold"}),
    ("assets/fonts/Montserrat/Montserrat-VariableFont_wght.ttf", "assets/fonts/Montserrat", "Montserrat",
     {400: "Regular", 700: "Bold"}),
]

options = subset.Options()
options.layout_features = ["kern", "liga", "calt", "ccmp", "locl", "mark", "mkmk"]
options.name_IDs = [1, 2, 3, 4, 6]
options.notdef_outline = True
options.drop_tables += ["DSIG"]

for src, out_dir, family, weights in JOBS:
    os.makedirs(out_dir, exist_ok=True)
    for weight, name in weights.items():
        font = instancer.instantiateVariableFont(TTFont(src), {"wght": weight})
        sub = subset.Subsetter(options)
        sub.populate(unicodes=KEEP)
        sub.subset(font)
        path = f"{out_dir}/{family}-{name}.ttf"
        font.save(path)
        print(f"{os.path.getsize(path) // 1024:4d} KB  {path}")
