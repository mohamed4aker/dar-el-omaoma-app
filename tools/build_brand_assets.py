#!/usr/bin/env python3
"""Builds every logo asset the app needs from the hospital's logo file.

The supplied logo is a 225 px JPEG-quality PNG, far too small for a launcher
icon (Android wants 192 px for the mark alone, iOS 1024 px). The mark is two
flat colours — a pink pin and a white mother-and-child glyph — so it is traced
to curves and re-rendered at any size, sharp. The brand pink is sampled from
the logo itself.

    python3 tools/build_brand_assets.py path/to/logo.png

Requires: pip install pillow potracer numpy
"""
import os
import sys

import numpy as np
import potrace
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = os.path.join(ROOT, 'app')
PINK = (0xEE, 0x65, 0x91)
SS = 4  # supersampling for anti-aliased edges


def trace(mask: np.ndarray):
    bm = potrace.Bitmap(mask)
    return bm.trace(turdsize=40, alphamax=1.2, opticurve=True, opttolerance=0.5)


def flatten(curve, scale, ox, oy, steps=24):
    pts = []
    x0, y0 = curve.start_point.x, curve.start_point.y
    pts.append((ox + x0 * scale, oy + y0 * scale))
    for seg in curve.segments:
        if seg.is_corner:
            for p in (seg.c, seg.end_point):
                pts.append((ox + p.x * scale, oy + p.y * scale))
            x0, y0 = seg.end_point.x, seg.end_point.y
        else:
            c1, c2, e = seg.c1, seg.c2, seg.end_point
            for i in range(1, steps + 1):
                t = i / steps
                mt = 1 - t
                x = mt**3 * x0 + 3 * mt * mt * t * c1.x + 3 * mt * t * t * c2.x + t**3 * e.x
                y = mt**3 * y0 + 3 * mt * mt * t * c1.y + 3 * mt * t * t * c2.y + t**3 * e.y
                pts.append((ox + x * scale, oy + y * scale))
            x0, y0 = e.x, e.y
    return pts


def render_mark(src: Image.Image, size: int, pad: float = 0.0,
                background=None, foreground_only: bool = False) -> Image.Image:
    """The pink pin with its white glyph, centred in a size×size square."""
    rgb = np.asarray(src.convert('RGB')).astype(int)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    pink = (r > 190) & (g < 170) & (b > 100) & (r - g > 60)

    ys, xs = np.nonzero(pink)
    # The pin only: everything above the hospital name.
    top, bottom = ys.min(), ys.max()
    rows = np.nonzero(pink.any(axis=1))[0]
    gap = np.nonzero(np.diff(rows) > 3)[0]
    if len(gap):
        bottom = rows[gap[0]]
    sel = pink[top:bottom + 1]
    cols = np.nonzero(sel.any(axis=0))[0]
    left, right = cols.min(), cols.max()
    sel = sel[:, left:right + 1]

    # Trace a *soft* pinkness map rather than the hard mask: the logo's own
    # anti-aliased edge pixels carry sub-pixel position, which a threshold
    # throws away (and which is what made the first traces wobble).
    soft = np.clip((r - g) / float(PINK[0] - PINK[1]), 0, 1)
    soft = soft[top:bottom + 1, left:right + 1] * sel.any()
    h, w = soft.shape
    up = Image.fromarray((soft * 255).astype('uint8')).resize((w * 8, h * 8), Image.BICUBIC)
    up = up.filter(ImageFilter.GaussianBlur(2))
    hi = np.asarray(up) > 127
    # A clear margin, so the pin's outline is a closed curve of its own.
    hi = np.pad(hi, 16, constant_values=False)

    # potracer traces the *zero* pixels as ink, so hand it the inverse.
    path = trace(~hi)
    big = size * SS
    inner = big * (1 - 2 * pad)
    scale = inner / max(hi.shape)
    ox = (big - hi.shape[1] * scale) / 2
    oy = (big - hi.shape[0] * scale) / 2

    # Even-odd fill: XOR every traced curve, so the glyph becomes a hole in
    # the pin; the largest curve is the pin's own outline.
    polys = [flatten(c, scale, ox, oy) for c in path.curves]
    xor = np.zeros((big, big), dtype=bool)
    filled = []
    for poly in polys:
        m = Image.new('1', (big, big), 0)
        ImageDraw.Draw(m).polygon(poly, fill=1)
        arr = np.asarray(m, dtype=bool)
        xor ^= arr
        filled.append(arr)
    filled.sort(key=lambda a: a.sum(), reverse=True)
    outline = filled[0]                 # the pink disc
    glyph = outline & ~xor              # the white pin

    if foreground_only:
        # Adaptive-icon foreground: the white pin and the pink figure in it,
        # on transparency; the launcher supplies the pink disc as background.
        pin = filled[1]
        canvas = np.zeros((big, big, 4), dtype=np.uint8)
        canvas[pin] = (255, 255, 255, 255)
        canvas[pin & xor] = PINK + (255,)
        return Image.fromarray(canvas, 'RGBA').resize((size, size), Image.LANCZOS)

    canvas = np.zeros((big, big, 4), dtype=np.uint8)
    if background:
        canvas[...] = background
    canvas[outline] = PINK + (255,)
    canvas[glyph] = (255, 255, 255, 255)
    canvas = Image.fromarray(canvas, 'RGBA')
    return canvas.resize((size, size), Image.LANCZOS)


def save(img: Image.Image, *parts):
    path = os.path.join(*parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    return path


def main(logo_path: str):
    src = Image.open(logo_path)
    white = (255, 255, 255, 255)

    # In-app assets.
    save(render_mark(src, 1024), APP, 'assets', 'brand', 'mark.png')
    full = src.convert('RGBA')
    save(full, APP, 'assets', 'brand', 'logo_full.png')

    # Android legacy launcher icons: the pin on white, full bleed.
    res = os.path.join(APP, 'android', 'app', 'src', 'main', 'res')
    for density, px in (('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                        ('xxhdpi', 144), ('xxxhdpi', 192)):
        save(render_mark(src, px, pad=0.10, background=white).convert('RGB'),
             res, f'mipmap-{density}', 'ic_launcher.png')
        # Adaptive foreground on a 108dp canvas. Launchers show the middle
        # 72dp; sizing the disc to exactly that keeps the logo's proportions.
        fg = px * 108 // 48
        save(render_mark(src, fg, pad=0.167, foreground_only=True), res,
             f'mipmap-{density}', 'ic_launcher_foreground.png')

    anydpi = os.path.join(res, 'mipmap-anydpi-v26')
    os.makedirs(anydpi, exist_ok=True)
    with open(os.path.join(anydpi, 'ic_launcher.xml'), 'w') as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n'
                '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '    <background android:drawable="@color/ic_launcher_background"/>\n'
                '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
                '</adaptive-icon>\n')
    values = os.path.join(res, 'values')
    with open(os.path.join(values, 'ic_launcher_background.xml'), 'w') as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
                '    <color name="ic_launcher_background">#%02X%02X%02X</color>\n'
                '</resources>\n' % PINK)

    # iOS: a single 1024 marketing icon plus the sizes Xcode asks for.
    ios = os.path.join(APP, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    if os.path.isdir(ios):
        for name in os.listdir(ios):
            if name.endswith('.png'):
                w, _ = Image.open(os.path.join(ios, name)).size
                save(render_mark(src, w, pad=0.10, background=white).convert('RGB'), ios, name)

    # Web favicon / PWA icons, used by the hot-reload preview.
    web = os.path.join(APP, 'web')
    if os.path.isdir(web):
        save(render_mark(src, 32, pad=0.04), web, 'favicon.png')
        for name, px in (('Icon-192.png', 192), ('Icon-512.png', 512),
                         ('Icon-maskable-192.png', 192), ('Icon-maskable-512.png', 512)):
            pad = 0.2 if 'maskable' in name else 0.08
            save(render_mark(src, px, pad=pad, background=white).convert('RGB'), web, 'icons', name)
    print('brand assets written')


if __name__ == '__main__':
    main(sys.argv[1])
