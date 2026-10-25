"""Makes the hero animation and the social preview from the pictures in docs/images/.

    python3 tool/make_story_images.py        (needs Pillow: python3 -m pip install pillow)

Run it after tool/doc_screenshots_test.dart and tool/trim_screenshots.py.
Writes docs/images/journey.gif and docs/images/social-preview.png.
"""
import glob
import os
from PIL import Image, ImageDraw, ImageFont

RED, DARK, INK, MUTED, BG = (186, 24, 27), (102, 7, 8), (20, 20, 22), (90, 98, 106), (253, 247, 247)
IMG = "docs/images"


def font(size, bold=False):
    root = os.environ.get("FLUTTER_ROOT", "/Users/hikki/development/flutter")
    for p in [f"{root}/bin/cache/artifacts/material_fonts/Roboto-{'Bold' if bold else 'Regular'}.ttf",
              "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf"]:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def wrap(draw, text, fnt, width):
    lines, line = [], ""
    for word in text.split():
        t = (line + " " + word).strip()
        if draw.textlength(t, font=fnt) <= width:
            line = t
        else:
            lines.append(line)
            line = word
    return lines + [line]


def phone(img_path, box_w, box_h, crop_h=None):
    im = Image.open(img_path).convert("RGB")
    if crop_h:
        im = im.crop((0, 0, im.width, min(im.height, crop_h)))
    s = min(box_w / im.width, box_h / im.height)
    im = im.resize((int(im.width * s), int(im.height * s)), Image.LANCZOS)
    card = Image.new("RGB", (im.width + 16, im.height + 16), (255, 255, 255))
    card.paste(im, (8, 8))
    d = ImageDraw.Draw(card)
    d.rounded_rectangle((0, 0, card.width - 1, card.height - 1), 18, outline=(224, 214, 215), width=2)
    return card


# (number, title, sentence, picture, crop height or None)
# The phone pictures are 1170 pixels wide and are shrunk to fit the frame.
SCENES = [
    ("1", "Sign in", "Choose English, Sinhala or Tamil, then sign in with email, Google or your phone.", "passenger-1-sign-in-phone.png", None),
    ("2", "Find a bus", "Choose where from, where to and the day. Your favourite routes are one tap away.", "passenger-2-search-phone.png", None),
    ("3", "Choose a bus", "Real times, how long it takes, and how many seats are left. A late bus says so in words.", "passenger-4-results-phone.png", None),
    ("4", "Pick your seats", "Taken seats are grey with a cross. Yours show a tick. The map is live.", "passenger-6-seats-chosen-phone.png", None),
    ("5", "Keep your ticket", "A QR code and a short code. It is always in My Trips, and Track bus shows where the bus is.", "passenger-8-ticket-phone.png", None),
    ("6", "The conductor checks it", "Name, seats and a big code to compare. Then Approve Boarding.", "conductor-2-verified-phone.png", None),
    ("7", "Once only", "Show the same ticket again and the app refuses it, and says when it first boarded.", "conductor-already-boarded.png", None),
]


def frame(n, title, sentence, pic, crop, W=960, H=540):
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 10, H), fill=RED)
    d.text((56, 40), "BusLink", font=font(30, True), fill=RED)
    for i in range(len(SCENES)):          # progress dots
        x = 56 + i * 26
        d.ellipse((x, 92, x + 14, 106), fill=RED if i + 1 == int(n) else (232, 214, 215))
    d.ellipse((56, 150, 112, 206), fill=RED)
    d.text((84, 178), n, font=font(34, True), fill=(255, 255, 255), anchor="mm")
    d.text((56, 236), title, font=font(40, True), fill=INK)
    f = font(23)
    y = 296
    for line in wrap(d, sentence, f, 420):
        d.text((56, y), line, font=f, fill=MUTED)
        y += 34
    ph = phone(f"{IMG}/{pic}", 400, 480, crop)
    im.paste(ph, (W - ph.width - 70, (H - ph.height) // 2))
    return im


def make_gif():
    frames = [frame(*s) for s in SCENES]
    pal = [f.convert("P", palette=Image.ADAPTIVE, colors=128) for f in frames]
    pal[0].save(f"{IMG}/journey.gif", save_all=True, append_images=pal[1:], duration=3200, loop=0, optimize=True)
    print("journey.gif", os.path.getsize(f"{IMG}/journey.gif") // 1024, "KB")


def make_social():
    W, H = 1280, 640
    im = Image.new("RGB", (W, H), RED)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, W, H), fill=RED)
    d.text((80, 150), "BusLink", font=font(96, True), fill=(255, 255, 255))
    f = font(36)
    y = 280
    for line in wrap(d, "Book a seat, pay, and show a ticket on your phone. One app for passengers, conductors and the people who run the buses.", f, 600):
        d.text((80, y), line, font=f, fill=(255, 226, 227))
        y += 52
    d.text((80, 540), "Flutter  ·  Firebase  ·  Stripe", font=font(28), fill=(255, 226, 227))
    for i, (pic, crop) in enumerate([("passenger-2-search-phone.png", None), ("passenger-8-ticket-phone.png", None)]):
        ph = phone(f"{IMG}/{pic}", 250, 460 - i * 40, crop)
        im.paste(ph, (730 + i * 270, 90 + i * 70))
    im.save(f"{IMG}/social-preview.png", optimize=True)
    print("social-preview.png", os.path.getsize(f"{IMG}/social-preview.png") // 1024, "KB")


if __name__ == "__main__":
    make_gif()
    make_social()
