"""Tidies the pictures in docs/images/ after the screenshot test.

  flutter test tool/doc_screenshots_test.dart --update-goldens
  python3 tool/trim_screenshots.py

1. Cuts the empty white space under each picture.
2. Cuts the pictures that end in a button just above that button. In the test
   renderer, button labels set in weight 800 draw as blank boxes, so those
   pictures stop above the button instead of showing it broken.
"""
import glob
import os
from PIL import Image, ImageChops

# picture name -> y (in pixels) to cut at, measured from the top
CUT_ABOVE_BUTTON = {
    "bus-card": 296,
    "bus-card-delayed": 346,
    "conductor-rejected": 222,
    "conductor-already-boarded": 222,
    "seat-map": 900,
}

# picture name -> y to start at (dialogs are centred in a tall empty screen)
CUT_FROM_TOP = {"delay-dialog": 285}

for path in sorted(glob.glob("docs/images/*.png")):
    name = os.path.splitext(os.path.basename(path))[0]
    im = Image.open(path).convert("RGB")
    bottom = im.height
    if name in CUT_ABOVE_BUTTON:
        bottom = min(bottom, CUT_ABOVE_BUTTON[name])
    else:
        bg = Image.new("RGB", im.size, (255, 255, 255))
        box = ImageChops.difference(im, bg).getbbox()
        if box:
            bottom = min(bottom, box[3] + 16)
    top = CUT_FROM_TOP.get(name, 0)
    im.crop((0, top, im.width, bottom)).save(path, optimize=True)
