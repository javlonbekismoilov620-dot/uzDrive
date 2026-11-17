#!/usr/bin/env python3
"""Generates the original SVG icon set in assets/icons/.
Monochrome icons are white (tinted in-engine via modulate); currency/pickup
icons are full colour. Run: python3 tools/build_icons.py
"""
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "icons")
os.makedirs(OUT, exist_ok=True)

W = 'fill="none" stroke="#ffffff" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"'
F = 'fill="#ffffff"'

ICONS = {
    # ---- colour icons ----
    "coin": '''<circle cx="32" cy="34" r="26" fill="#c8961a"/><circle cx="32" cy="31" r="26" fill="#ffd23f"/>
<circle cx="32" cy="31" r="19" fill="#ffc21a"/><path d="M27 20h10M32 20v22M25 42h14" stroke="#c8861a" stroke-width="5" stroke-linecap="round"/>
<circle cx="22" cy="20" r="4" fill="#fff6c7"/>''',
    "gem": '''<path d="M16 10h32l12 16-28 32L4 26z" fill="#1aa6c8"/><path d="M16 10h32l12 16H4z" fill="#38d9f5"/>
<path d="M24 26h16l-8 32z" fill="#7be8fb"/><path d="M16 10l8 16 8-16 8 16 8-16" fill="none" stroke="#a5f3ff" stroke-width="2.5"/>''',
    "fuel": '''<rect x="12" y="14" width="34" height="44" rx="6" fill="#e63946"/><rect x="17" y="19" width="9" height="34" rx="3" fill="#ff7b84"/>
<path d="M20 14V7h14v7" fill="none" stroke="#2b2d42" stroke-width="5"/><path d="M46 22l8 6v22a4 4 0 0 1-8 0V36" fill="none" stroke="#2b2d42" stroke-width="5" stroke-linecap="round"/>
<path d="M30 30l7 9h-5l2 9-8-11h5z" fill="#ffffff"/>''',
    "boost": '''<circle cx="32" cy="32" r="28" fill="#2f6bff"/><path d="M36 8L18 36h12l-4 20 20-30H34z" fill="#fff36b"/>''',
    "gift": '''<rect x="8" y="26" width="48" height="32" rx="5" fill="#ff5d73"/><rect x="5" y="18" width="54" height="12" rx="4" fill="#ff8597"/>
<rect x="28" y="18" width="8" height="40" fill="#ffd23f"/><path d="M32 18c-6-12-20-12-16-2 2 4 10 2 16 2 6 0 14 2 16-2 4-10-10-10-16 2z" fill="#ffd23f"/>''',
    "trophy_gold": '''<path d="M18 8h28v16a14 14 0 0 1-28 0z" fill="#ffc93c"/><path d="M18 12H8v6a10 10 0 0 0 12 8M46 12h10v6a10 10 0 0 1-12 8" fill="none" stroke="#ffc93c" stroke-width="5"/>
<rect x="28" y="36" width="8" height="10" fill="#e0a21f"/><rect x="18" y="46" width="28" height="10" rx="3" fill="#e0a21f"/>''',
    "star_gold": '''<path d="M32 4l8.6 17.6 19.4 2.8-14 13.6 3.3 19.3L32 48.2 14.7 57.3 18 38 4 24.4l19.4-2.8z" fill="#ffc93c"/>''',
    # ---- monochrome icons ----
    "pause": f'<rect x="14" y="10" width="12" height="44" rx="4" {F}/><rect x="38" y="10" width="12" height="44" rx="4" {F}/>',
    "play": f'<path d="M18 8l38 24-38 24z" {F}/>',
    "settings": f'''<path d="M32 4l5 7 8-2 2 8 8 3-3 8 5 6-6 5 1 8-8 1-3 8-7-4-7 4-3-8-8-1 1-8-6-5 5-6-3-8 8-3 2-8 8 2z" {F}/><circle cx="32" cy="32" r="9" fill="#000" fill-opacity="0.45"/>''',
    "garage": f'<path d="M6 28L32 8l26 20v28H6z" {W}/><path d="M16 56V36h32v20M16 44h32" {W}/>',
    "shop": f'<path d="M6 10h8l6 30h30l6-22H17" {W}/><circle cx="24" cy="52" r="4" {F}/><circle cx="46" cy="52" r="4" {F}/>',
    "missions": f'<rect x="12" y="10" width="40" height="48" rx="6" {W}/><path d="M24 10V6h16v4M20 30l6 6 12-12M20 46h24" {W}/>',
    "trophy": f'<path d="M18 8h28v16a14 14 0 0 1-28 0z" {F}/><path d="M18 12H8v6a10 10 0 0 0 12 8M46 12h10v6a10 10 0 0 1-12 8" {W}/><path d="M32 38v10M20 54h24" {W}/>',
    "back": f'<path d="M40 10L18 32l22 22" {W} stroke-width="8"/>',
    "forward": f'<path d="M24 10l22 22-22 22" {W} stroke-width="8"/>',
    "close": f'<path d="M14 14l36 36M50 14L14 50" {W} stroke-width="8"/>',
    "lock": f'<rect x="12" y="28" width="40" height="30" rx="6" {F}/><path d="M20 28v-8a12 12 0 0 1 24 0v8" {W}/>',
    "check": f'<path d="M10 34l14 14 30-30" {W} stroke-width="8"/>',
    "wrench": f'<path d="M40 6a14 14 0 0 0-12 20L8 46a6 6 0 0 0 10 10l20-20a14 14 0 0 0 20-12l-8 6-8-2-2-8z" {F}/>',
    "engine": f'<path d="M10 24h8v-6h18v6h8l6 6h6v16h-6l-6 6H18l-4-6h-4z" {F}/><path d="M24 12h12" {W}/>',
    "suspension": f'<path d="M32 4v8M18 12h28M18 52h28M32 52v8" {W}/><path d="M20 18l24 6-24 6 24 6-24 6 24 6" {W} stroke-width="5"/>',
    "tire": f'<circle cx="32" cy="32" r="26" {W} stroke-width="8"/><circle cx="32" cy="32" r="9" {F}/><path d="M32 6v12M32 46v12M6 32h12M46 32h12" {W} stroke-width="4"/>',
    "tank": f'<rect x="10" y="12" width="36" height="44" rx="6" {W}/><path d="M46 20l8 6v22a4 4 0 0 1-8 0V36" {W}/><path d="M18 40h20" {W}/>',
    "speed": f'<path d="M8 46a24 24 0 1 1 48 0" {W}/><path d="M32 46l12-18" {W}/><circle cx="32" cy="46" r="5" {F}/>',
    "weight": f'<path d="M14 24h36l6 32H8z" {F}/><circle cx="32" cy="16" r="8" {W}/>',
    "grip": f'<path d="M8 50c8-30 40-30 48 0" {W}/><path d="M14 56l6-8M26 58l4-9M38 58l-4-9M50 56l-6-8" {W} stroke-width="5"/>',
    "star": f'<path d="M32 4l8.6 17.6 19.4 2.8-14 13.6 3.3 19.3L32 48.2 14.7 57.3 18 38 4 24.4l19.4-2.8z" {F}/>',
    "map": f'<path d="M32 58S12 36 12 24a20 20 0 0 1 40 0c0 12-20 34-20 34z" {F}/><circle cx="32" cy="24" r="7" fill="#000" fill-opacity="0.45"/>',
    "restart": f'<path d="M52 32a20 20 0 1 1-6-14" {W}/><path d="M50 6v14H36" {W}/>',
    "home": f'<path d="M6 30L32 8l26 22" {W}/><path d="M14 26v30h36V26" {W}/><rect x="26" y="40" width="12" height="16" {F}/>',
    "sound_on": f'<path d="M8 24h12l14-12v40L20 40H8z" {F}/><path d="M42 22a14 14 0 0 1 0 20M48 14a24 24 0 0 1 0 36" {W} stroke-width="5"/>',
    "sound_off": f'<path d="M8 24h12l14-12v40L20 40H8z" {F}/><path d="M42 24l16 16M58 24L42 40" {W} stroke-width="5"/>',
    "music_on": f'<path d="M24 46V12l30-6v34" {W}/><circle cx="16" cy="46" r="8" {F}/><circle cx="46" cy="40" r="8" {F}/>',
    "music_off": f'<path d="M24 46V12l30-6v34" {W}/><circle cx="16" cy="46" r="8" {F}/><circle cx="46" cy="40" r="8" {F}/><path d="M6 6l52 52" {W} stroke-width="5"/>',
    "globe": f'<circle cx="32" cy="32" r="26" {W} stroke-width="5"/><path d="M6 32h52M32 6c-14 14-14 38 0 52M32 6c14 14 14 38 0 52" {W} stroke-width="4"/>',
    "calendar": f'<rect x="8" y="12" width="48" height="44" rx="6" {W}/><path d="M8 26h48M20 6v12M44 6v12" {W}/><rect x="16" y="34" width="8" height="8" {F}/><rect x="28" y="34" width="8" height="8" {F}/><rect x="40" y="34" width="8" height="8" {F}/>',
    "info": f'<circle cx="32" cy="32" r="26" {W} stroke-width="5"/><path d="M32 30v16" {W}/><circle cx="32" cy="19" r="4" {F}/>',
    "vibration": f'<rect x="20" y="8" width="24" height="48" rx="5" {W} stroke-width="5"/><path d="M8 20v24M56 20v24M12 26v12M52 26v12" {W} stroke-width="4"/>',
    "plus": f'<path d="M32 10v44M10 32h44" {W} stroke-width="8"/>',
    "flag": f'<path d="M12 60V6" {W}/><path d="M14 8h36l-8 12 8 12H14z" {F}/>',
    "sort": f'<path d="M18 8v48M8 46l10 10 10-10M46 56V8M36 18l10-10 10 10" {W} stroke-width="5"/>',
    "car": f'<path d="M6 40v-8l8-2 8-12h20l10 12 6 2v8z" {F}/><circle cx="18" cy="42" r="7" fill="#000" fill-opacity="0.6"/><circle cx="46" cy="42" r="7" fill="#000" fill-opacity="0.6"/><circle cx="18" cy="42" r="4" {F}/><circle cx="46" cy="42" r="4" {F}/>',
    "compare": f'<rect x="8" y="30" width="10" height="26" rx="2" {F}/><rect x="27" y="14" width="10" height="42" rx="2" {F}/><rect x="46" y="22" width="10" height="34" rx="2" {F}/>',
    "brake_pedal": f'<rect x="10" y="6" width="44" height="52" rx="10" {W} stroke-width="5"/><path d="M20 20h24M20 32h24M20 44h24" {W} stroke-width="5"/>',
    "gas_pedal": f'<rect x="14" y="4" width="36" height="56" rx="10" {W} stroke-width="5"/><path d="M24 16v32M32 16v32M40 16v32" {W} stroke-width="4"/>',
    "exchange": f'<path d="M10 22h40l-10-10M54 42H14l10 10" {W}/>',
    "reset": f'<path d="M14 16h36M24 16V8h16v8M18 16l3 40h22l3-40" {W}/>',
    "privacy": f'<path d="M32 4l22 8v16c0 14-10 26-22 32C20 54 10 42 10 28V12z" {W} stroke-width="5"/><path d="M22 32l7 7 13-13" {W} stroke-width="5"/>',
    "quality": f'<path d="M8 50l14-18 10 10 10-16 14 24z" {F}/><circle cx="20" cy="16" r="6" {F}/>',
}

for name, body in ICONS.items():
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">{body}</svg>\n'
    with open(os.path.join(OUT, name + ".svg"), "w") as f:
        f.write(svg)
print("wrote", len(ICONS), "icons")
