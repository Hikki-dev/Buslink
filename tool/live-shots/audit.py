"""Measures text contrast in the pictures made by capture.js.

Usage: python3 audit.py <folder with .png and .json> [minimum ratio, default 4.5]

For each piece of text the accessibility tree reports, takes the picture under it, calls
the commonest colour the background and the colour furthest from it the text, and
works out the WCAG contrast ratio. Text over photos is skipped (no single background).
"""
import colorsys, glob, json, os, sys
from collections import Counter
from PIL import Image

import numpy as np

def lum(c):
    c = np.asarray(c, dtype=float) / 255
    c = np.where(c <= 0.03928, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return c @ np.array([0.2126, 0.7152, 0.0722])

def ratio(a, b):
    la, lb = lum(a), lum(b)
    hi, lo = np.maximum(la, lb), np.minimum(la, lb)
    return (hi + 0.05) / (lo + 0.05)

def measure(im, box, dsf):
    x0, y0 = max(0, int(box['x'] * dsf)), max(0, int(box['y'] * dsf))
    x1, y1 = min(im.width, int((box['x'] + box['w']) * dsf)), min(im.height, int((box['y'] + box['h']) * dsf))
    if x1 - x0 < 8 or y1 - y0 < 8: return None
    px = np.asarray(im.crop((x0, y0, x1, y1)).convert('RGB')).reshape(-1, 3)
    keys = (px // 8) @ np.array([1024, 32, 1])
    vals, counts = np.unique(keys, return_counts=True)
    top = vals[counts.argmax()]
    if counts.max() / len(px) < 0.35: return None      # a photo or a gradient
    bg = px[keys == top].mean(axis=0)
    r = ratio(px, bg)
    far = px[np.argsort(-r)[:max(3, len(px) // 200)]].mean(axis=0)
    return tuple(bg.astype(int)), tuple(far.astype(int)), float(ratio(far, bg))

def main():
    folder = sys.argv[1]; need = float(sys.argv[2]) if len(sys.argv) > 2 else 4.5
    bad = []; total = 0
    for js in sorted(glob.glob(os.path.join(folder, '*.json'))):
        png = js[:-5] + '.png'
        if not os.path.exists(png): continue
        data = json.load(open(js)); im = Image.open(png)
        seen = set()
        for b in data['boxes']:
            m = measure(im, b, data['dsf'])
            if not m: continue
            total += 1
            if m[2] < need and (b['t'], round(b['x']), round(b['y'])) not in seen:
                seen.add((b['t'], round(b['x']), round(b['y'])))
                bad.append((m[2], os.path.basename(png), b['t'][:50], '#%02x%02x%02x' % m[1], '#%02x%02x%02x' % m[0]))
    bad.sort()
    for r, f, t, fg, bg in bad: print(f'{r:4.1f}  {f:34} {t!r:54} text {fg} on {bg}')
    print(f'\n{len(bad)} low-contrast of {total} measured (need {need})')
main()
