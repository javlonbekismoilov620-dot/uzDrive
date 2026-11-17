#!/usr/bin/env python3
"""Generates original raster art:
  * assets/textures/ground_*.png  seamless near-white detail tiles (tinted in-engine
    by the terrain vertex colours, so one tile works for any palette)
  * assets/branding/icon.png (1024), icon.svg, adaptive icon fg/bg (432), splash.png
Run: python3 tools/build_textures.py
"""
import os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..")
TEX = os.path.join(ROOT, "assets", "textures")
BR = os.path.join(ROOT, "assets", "branding")
os.makedirs(TEX, exist_ok=True)
os.makedirs(BR, exist_ok=True)
S = 256


def periodic_noise(size, freqs, seed):
    r = np.random.default_rng(seed)
    y, x = np.mgrid[0:size, 0:size] / size
    out = np.zeros((size, size))
    for f, a in freqs:
        for _ in range(3):
            fx, fy = r.integers(1, f + 1), r.integers(1, f + 1)
            ph = r.uniform(0, 2 * np.pi, 2)
            out += a * np.sin(2 * np.pi * (fx * x) + ph[0]) * np.sin(2 * np.pi * (fy * y) + ph[1])
    out = (out - out.min()) / (out.max() - out.min() + 1e-9)
    return out


def blobs(img, n, rmin, rmax, lo, hi, seed, alpha=1.0):
    r = np.random.default_rng(seed)
    d = ImageDraw.Draw(img, "RGBA")
    for _ in range(n):
        cx, cy = r.uniform(0, S), r.uniform(0, S)
        rad = r.uniform(rmin, rmax)
        v = int(r.uniform(lo, hi))
        for ox in (-S, 0, S):
            for oy in (-S, 0, S):
                d.ellipse([cx - rad + ox, cy - rad * 0.75 + oy, cx + rad + ox, cy + rad * 0.75 + oy], fill=(v, v, v, int(255 * alpha)))


def base(noise, lo, hi):
    a = (lo + (hi - lo) * noise).astype(np.uint8)
    return Image.fromarray(np.stack([a, a, a], -1), "RGB")


def strata(img, count, seed, dark=200, thickness=(2, 5)):
    r = np.random.default_rng(seed)
    d = ImageDraw.Draw(img, "RGBA")
    for _ in range(count):
        y0 = r.uniform(0, S)
        amp = r.uniform(2, 8)
        ph = r.uniform(0, 6.28)
        th = r.uniform(*thickness)
        pts = [(x, y0 + amp * math.sin(2 * math.pi * x / S * 2 + ph)) for x in range(0, S + 1, 4)]
        d.line(pts, fill=(dark, dark, dark, 120), width=int(th))


def save(img, name):
    img.save(os.path.join(TEX, name + ".png"))


def ground_textures():
    n = periodic_noise(S, [(2, 1.0), (5, 0.5), (11, 0.25)], 1)
    img = base(n, 205, 255)
    blobs(img, 70, 2, 6, 150, 200, 2)   # pebbles
    blobs(img, 30, 1, 3, 245, 255, 3)
    save(img.filter(ImageFilter.SMOOTH), "ground_soil")

    img = base(periodic_noise(S, [(3, 1.0), (8, 0.4)], 4), 210, 255)
    strata(img, 9, 5, 185)
    blobs(img, 40, 2, 5, 160, 205, 6)
    save(img.filter(ImageFilter.SMOOTH), "ground_farm")

    n = periodic_noise(S, [(4, 1.0), (9, 0.3)], 7)
    img = base(n, 225, 255)
    d = ImageDraw.Draw(img, "RGBA")
    for i in range(14):  # ripples
        y0 = i * S / 14
        pts = [(x, y0 + 4 * math.sin(2 * math.pi * x / S * 3 + i)) for x in range(0, S + 1, 4)]
        d.line(pts, fill=(205, 205, 205, 140), width=3)
    blobs(img, 25, 1, 2, 180, 210, 8)
    save(img.filter(ImageFilter.SMOOTH), "ground_sand")

    img = base(periodic_noise(S, [(2, 1.0), (6, 0.6), (14, 0.3)], 9), 185, 245)
    blobs(img, 50, 2, 7, 140, 185, 10)
    d = ImageDraw.Draw(img, "RGBA")
    r = np.random.default_rng(11)
    for _ in range(18):  # roots
        x, y = r.uniform(0, S), r.uniform(0, S)
        pts = [(x, y)]
        for k in range(6):
            x += r.uniform(-14, 14)
            y += r.uniform(4, 14)
            pts.append((x, y))
        d.line(pts, fill=(150, 150, 150, 160), width=2)
    save(img.filter(ImageFilter.SMOOTH), "ground_forest")

    img = base(periodic_noise(S, [(3, 1.0), (7, 0.5)], 12), 200, 245)
    d = ImageDraw.Draw(img, "RGBA")
    for row in range(8):  # stone blocks / foundations
        y = row * 32
        off = 0 if row % 2 == 0 else 32
        for col in range(-1, 5):
            x = col * 64 + off
            d.rectangle([x + 2, y + 2, x + 62, y + 30], outline=(170, 170, 170, 170), width=2)
    save(img.filter(ImageFilter.SMOOTH), "ground_city")

    img = base(periodic_noise(S, [(2, 1.0), (5, 0.4)], 13), 228, 255)
    blobs(img, 40, 1, 2, 255, 255, 14)
    blobs(img, 20, 3, 8, 215, 235, 15, 0.5)
    save(img.filter(ImageFilter.SMOOTH), "ground_snow")

    img = base(periodic_noise(S, [(2, 1.0), (4, 0.8), (9, 0.4)], 16), 175, 245)
    strata(img, 12, 17, 150, (2, 6))
    d = ImageDraw.Draw(img, "RGBA")
    r = np.random.default_rng(18)
    for _ in range(14):  # cracks
        x, y = r.uniform(0, S), r.uniform(0, S)
        pts = [(x, y)]
        for k in range(4):
            x += r.uniform(-18, 18)
            y += r.uniform(-18, 18)
            pts.append((x, y))
        d.line(pts, fill=(120, 120, 120, 170), width=2)
    save(img.filter(ImageFilter.SMOOTH), "ground_rock")

    img = base(periodic_noise(S, [(3, 1.0), (9, 0.5)], 19), 190, 240)
    blobs(img, 80, 1, 3, 150, 200, 20)
    save(img.filter(ImageFilter.SMOOTH), "ground_night")


# ------------------------------------------------------------------ branding
def find_font(bold=True):
    p = os.path.join(ROOT, "assets", "fonts", "Exo2-Italic-Variable.ttf")
    try:
        f = ImageFont.truetype(p, 100)
        try:
            f.set_variation_by_axes([900])
        except Exception:
            pass
        return p
    except Exception:
        return None


def draw_icon(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s = size / 1024.0
    d = ImageDraw.Draw(img)
    # background: sunset sky + hills
    sky = Image.new("RGB", (size, size))
    top = np.array([28, 64, 140])
    bot = np.array([255, 160, 70])
    grad = np.linspace(0, 1, size)[:, None]
    arr = (top * (1 - grad) + bot * grad).astype(np.uint8)
    sky = Image.fromarray(np.repeat(arr[:, None, :], size, axis=1).reshape(size, size, 3), "RGB")
    img.paste(sky, (0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([size * 0.58, size * 0.16, size * 0.88, size * 0.46], fill=(255, 236, 170))
    # far hills
    pts = [(0, size * 0.62)]
    for i in range(0, 41):
        x = i / 40 * size
        pts.append((x, size * (0.6 - 0.07 * math.sin(i / 40 * math.pi * 2.3 + 0.6))))
    pts += [(size, size), (0, size)]
    d.polygon(pts, fill=(64, 140, 90))
    # main hill
    pts = []
    for i in range(0, 41):
        x = i / 40 * size
        pts.append((x, size * (0.78 - 0.16 * math.sin(i / 40 * math.pi * 1.1 + 0.15))))
    d.polygon(pts + [(size, size), (0, size)], fill=(98, 186, 74))
    d.line(pts, fill=(140, 220, 100), width=int(14 * s))
    # car (simple original silhouette) tilted on the hill
    car = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cd = ImageDraw.Draw(car)
    cx, cy = size * 0.47, size * 0.55
    body = [(cx - 250 * s, cy + 40 * s), (cx - 255 * s, cy - 30 * s), (cx - 150 * s, cy - 45 * s), (cx - 90 * s, cy - 130 * s),
            (cx + 90 * s, cy - 130 * s), (cx + 160 * s, cy - 50 * s), (cx + 255 * s, cy - 30 * s), (cx + 260 * s, cy + 40 * s)]
    cd.polygon(body, fill=(255, 138, 31), outline=(120, 50, 0))
    cd.polygon([(cx - 70 * s, cy - 115 * s), (cx + 75 * s, cy - 115 * s), (cx + 130 * s, cy - 55 * s), (cx - 125 * s, cy - 55 * s)], fill=(40, 60, 90))
    cd.rectangle([cx - 5 * s, cy - 115 * s, cx + 8 * s, cy - 55 * s], fill=(255, 138, 31))
    cd.rectangle([cx - 250 * s, cy + 10 * s, cx + 255 * s, cy + 42 * s], fill=(40, 40, 50))
    for wx in (cx - 150 * s, cx + 150 * s):
        cd.ellipse([wx - 72 * s, cy - 10 * s, wx + 72 * s, cy + 134 * s], fill=(25, 25, 30))
        cd.ellipse([wx - 40 * s, cy + 22 * s, wx + 40 * s, cy + 102 * s], fill=(220, 228, 238))
        cd.ellipse([wx - 12 * s, cy + 50 * s, wx + 12 * s, cy + 74 * s], fill=(90, 90, 100))
    car = car.rotate(9, center=(cx, cy), resample=Image.BICUBIC)
    img.alpha_composite(car)
    return img


def text_banner(img, txt, y, size_px, fill):
    fp = find_font()
    d = ImageDraw.Draw(img)
    if fp:
        f = ImageFont.truetype(fp, size_px)
        try:
            f.set_variation_by_axes([900])
        except Exception:
            pass
    else:
        f = ImageFont.load_default()
    w = d.textlength(txt, font=f)
    x = (img.width - w) / 2
    d.text((x + size_px * 0.05, y + size_px * 0.06), txt, font=f, fill=(0, 0, 0, 110))
    d.text((x, y), txt, font=f, fill=fill)


def branding():
    icon = draw_icon(1024)
    text_banner(icon, "UZ DRIVE", 740, 150, (255, 255, 255, 255))
    rounded = Image.new("L", (1024, 1024), 0)
    ImageDraw.Draw(rounded).rounded_rectangle([0, 0, 1023, 1023], radius=0, fill=255)
    icon.putalpha(rounded)
    icon.convert("RGB").save(os.path.join(BR, "icon_1024.png"))
    icon.resize((512, 512), Image.LANCZOS).convert("RGB").save(os.path.join(BR, "icon_512.png"))
    icon.resize((192, 192), Image.LANCZOS).save(os.path.join(BR, "icon_192.png"))
    # Android adaptive icon (432x432; safe zone = inner 264 circle)
    fg_full = draw_icon(1024)
    bg = fg_full.resize((432, 432), Image.LANCZOS).convert("RGB")
    bg.save(os.path.join(BR, "adaptive_background.png"))
    fg = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    text_banner(fg, "UZ", 150, 120, (255, 255, 255, 255))
    fg.save(os.path.join(BR, "adaptive_foreground.png"))
    mono = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    text_banner(mono, "UZ", 150, 120, (255, 255, 255, 255))
    mono.save(os.path.join(BR, "adaptive_monochrome.png"))
    # Splash (landscape)
    sp = Image.new("RGB", (1920, 1080), (15, 23, 41))
    arr = np.array(sp).astype(float)
    yy, xx = np.mgrid[0:1080, 0:1920]
    glow = np.exp(-(((xx - 960) / 700) ** 2 + ((yy - 470) / 380) ** 2))
    arr[..., 0] += glow * 30
    arr[..., 1] += glow * 60
    arr[..., 2] += glow * 120
    sp = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).convert("RGBA")
    ic = draw_icon(420)
    mask = Image.new("L", (420, 420), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, 419, 419], radius=90, fill=255)
    sp.paste(ic, (750, 230), mask)
    text_banner(sp, "UZ DRIVE", 680, 120, (255, 138, 31, 255))
    sp.convert("RGB").save(os.path.join(BR, "splash.png"))
    # Godot project icon (svg wrapper around the png is not needed; ship a png-based svg)
    with open(os.path.join(BR, "icon.svg"), "w") as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">'
                '<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1c408c"/><stop offset="1" stop-color="#ffa046"/></linearGradient></defs>'
                '<rect width="128" height="128" rx="24" fill="url(#g)"/><circle cx="92" cy="38" r="18" fill="#ffecaa"/>'
                '<path d="M0 98 Q40 70 128 84 V128 H0Z" fill="#62ba4a"/>'
                '<path d="M30 78 l2-10 14-2 8-12 h24 l10 11 14 3 v10z" fill="#ff8a1f"/>'
                '<circle cx="44" cy="80" r="9" fill="#19191e"/><circle cx="86" cy="80" r="9" fill="#19191e"/>'
                '<circle cx="44" cy="80" r="4" fill="#dce4ee"/><circle cx="86" cy="80" r="4" fill="#dce4ee"/></svg>')


if __name__ == "__main__":
    ground_textures()
    branding()
    print("textures + branding done")
