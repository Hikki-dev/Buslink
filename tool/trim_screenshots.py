"""Tidies the pictures that tool/doc_screenshots_test.dart draws in docs/images/.

  flutter test tool/doc_screenshots_test.dart --update-goldens
  python3 tool/trim_screenshots.py

The test draws each small piece on a tall white screen. This cuts the empty
white space around it, keeping a little margin, so a card is only as tall as
the card. Only those pictures are touched. The screens taken from the running
app (passenger-*, conductor-*, admin-* and so on) are left exactly as taken.
"""
import os
from PIL import Image, ImageChops

PIECES = [
    "bus-card", "bus-card-delayed", "my-trips-card", "seat-map",
    "conductor-verified", "conductor-already-boarded", "conductor-rejected",
    "delay-dialog", "refund-progress", "status-chips", "trip-form-steps",
    "payment-states", "splash", "splash-slow", "startup-failed",
]
MARGIN = 24  # pixels, at three times the sharpness

for name in PIECES:
    path = f"docs/images/{name}.png"
    if not os.path.exists(path):
        continue
    im = Image.open(path).convert("RGB")
    box = ImageChops.difference(im, Image.new("RGB", im.size, (255, 255, 255))).getbbox()
    if not box:
        continue
    top = max(0, box[1] - MARGIN)
    bottom = min(im.height, box[3] + MARGIN)
    im.crop((0, top, im.width, bottom)).save(path, optimize=True)
