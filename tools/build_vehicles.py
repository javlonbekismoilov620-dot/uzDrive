#!/usr/bin/env python3
"""Generates data/vehicles.json from the compact roster table below.

The JSON file is the runtime source of truth (designers may edit it directly);
this script exists so pricing tiers and handling defaults stay consistent when
the roster is rebuilt.  Run:  python3 tools/build_vehicles.py

Branding policy: every vehicle uses an ORIGINAL fictional name and maker.
`inspired_by` is an internal design reference only and is never shown in the
UI.  The `license` block lets officially licensed branding be switched on per
vehicle later (licensed=true + brand/model/logo asset) without code changes.
"""
import json, os

OUT = os.path.join(os.path.dirname(__file__), "..", "data", "vehicles.json")

# Handling defaults per body archetype.
ARCH = {
    "micro":        dict(grip=1.00, suspension=0.9, travel=0.22, com_h=0.46, front_bias=0.60, air_control=1.05, desc="city"),
    "hatch":        dict(grip=1.05, suspension=1.0, travel=0.22, com_h=0.46, front_bias=0.58, air_control=1.0, desc="hatch"),
    "sedan":        dict(grip=1.05, suspension=1.0, travel=0.22, com_h=0.46, front_bias=0.58, air_control=1.0, desc="sedan"),
    "coupe":        dict(grip=1.20, suspension=1.1, travel=0.19, com_h=0.40, front_bias=0.48, air_control=1.1, desc="sports"),
    "muscle":       dict(grip=1.10, suspension=1.0, travel=0.20, com_h=0.43, front_bias=0.55, air_control=1.0, desc="muscle"),
    "super":        dict(grip=1.30, suspension=1.2, travel=0.17, com_h=0.37, front_bias=0.45, air_control=1.15, desc="super"),
    "crossover":    dict(grip=1.10, suspension=1.15, travel=0.28, com_h=0.56, front_bias=0.55, air_control=0.95, desc="crossover"),
    "suv":          dict(grip=1.15, suspension=1.2, travel=0.32, com_h=0.64, front_bias=0.52, air_control=0.85, desc="suv"),
    "mpv":          dict(grip=1.05, suspension=1.05, travel=0.24, com_h=0.56, front_bias=0.56, air_control=0.9, desc="mpv"),
    "microvan":     dict(grip=0.95, suspension=0.9, travel=0.22, com_h=0.62, front_bias=0.50, air_control=0.95, desc="van"),
    "van":          dict(grip=1.00, suspension=1.0, travel=0.26, com_h=0.72, front_bias=0.50, air_control=0.8, desc="van"),
    "bus":          dict(grip=1.00, suspension=1.0, travel=0.26, com_h=0.85, front_bias=0.45, air_control=0.7, desc="bus"),
    "pickup":       dict(grip=1.15, suspension=1.2, travel=0.32, com_h=0.62, front_bias=0.58, air_control=0.85, desc="pickup"),
    "micro_pickup": dict(grip=0.95, suspension=0.9, travel=0.22, com_h=0.58, front_bias=0.55, air_control=0.95, desc="pickup"),
    "beetle":       dict(grip=0.98, suspension=0.95, travel=0.25, com_h=0.48, front_bias=0.42, air_control=1.0, desc="classic"),
    "classic":      dict(grip=0.95, suspension=0.95, travel=0.25, com_h=0.50, front_bias=0.55, air_control=0.95, desc="classic"),
    "finned":       dict(grip=0.95, suspension=0.9, travel=0.26, com_h=0.48, front_bias=0.55, air_control=0.9, desc="classic"),
    "boxy4x4":      dict(grip=1.25, suspension=1.25, travel=0.36, com_h=0.60, front_bias=0.55, air_control=1.0, desc="offroad"),
    "crawler":      dict(grip=1.55, suspension=1.4, travel=0.46, com_h=0.78, front_bias=0.52, air_control=0.95, desc="crawler"),
    "trophy":       dict(grip=1.35, suspension=1.6, travel=0.55, com_h=0.70, front_bias=0.50, air_control=1.1, desc="trophy"),
    "monster":      dict(grip=1.40, suspension=1.5, travel=0.60, com_h=1.35, front_bias=0.50, air_control=1.2, desc="monster"),
    "buggy":        dict(grip=1.30, suspension=1.5, travel=0.45, com_h=0.50, front_bias=0.42, air_control=1.3, desc="buggy"),
    "kart":         dict(grip=1.40, suspension=0.7, travel=0.07, com_h=0.26, front_bias=0.42, air_control=1.4, desc="kart"),
    "tractor":      dict(grip=1.60, suspension=0.9, travel=0.18, com_h=0.85, front_bias=0.38, air_control=0.7, desc="tractor"),
    "rover":        dict(grip=1.25, suspension=1.4, travel=0.38, com_h=0.55, front_bias=0.50, air_control=1.5, desc="rover"),
}

RARITY = {
    "common":    dict(max=8,  fuel_time=46),
    "rare":      dict(max=10, fuel_time=50),
    "epic":      dict(max=12, fuel_time=54),
    "legendary": dict(max=15, fuel_time=58),
}

# id, name, maker, category, rarity, price, inspired_by, type, hp, kg, kmh, fuel, drive, engine, pitch, style, extra
R = []
def v(id, name, maker, cat, rar, price, insp, typ, hp, kg, kmh, fuel, drive, eng, pitch, style, body=None, **extra):
    R.append(dict(id=id, name=name, maker=maker, cat=cat, rar=rar, price=price, insp=insp, typ=typ, hp=hp, kg=kg,
                  kmh=kmh, fuel=fuel, drive=drive, eng=eng, pitch=pitch, style=style, body=body or {}, extra=extra))

# ---------------- GM-inspired lineup ("Road Legends", category gm) ----------------
v("sarbon_mitti", "Mitti", "Sarbon", "gm", "common", 0, "Chevrolet Matiz", "micro", 52, 820, 144, 35, "fwd", "i3", 1.15,
  {"color": "#f9c80e", "rims": "steel", "doors": 4, "helmet": "#ffffff"}, fuel_time=50, unlock="default")
v("sarbon_uchqun", "Uchqun", "Sarbon", "gm", "common", 6000, "Chevrolet Spark", "micro", 85, 960, 165, 35, "fwd", "i4", 1.2,
  {"color": "#3ccf91", "rims": "alloy5", "doors": 4, "stripe": {"type": "lower", "color": "#2b2d42"}}, {"L": 3.65, "H": 1.52, "r_roof": 0.5})
v("sarbon_dastyor", "Dastyor", "Sarbon", "gm", "common", 4000, "Chevrolet Damas", "microvan", 38, 910, 115, 37, "rwd", "i3", 1.25,
  {"color": "#f4f6f8", "rims": "steel", "stripe": {"type": "side", "color": "#1f8ef1"}}, fuel_time=60, grip=0.92)
v("sarbon_mehnat", "Mehnat", "Sarbon", "gm", "common", 5000, "Chevrolet Labo", "micro_pickup", 38, 860, 115, 37, "rwd", "i3", 1.22,
  {"color": "#2e86de", "rims": "steel", "acc": ["cargo_crates"]}, fuel_time=58)
v("sarbon_nafis", "Nafis", "Sarbon", "gm", "common", 9000, "Chevrolet Nexia", "sedan", 86, 1060, 175, 50, "fwd", "i4", 1.0,
  {"color": "#f1f3f5", "rims": "steel", "doors": 4, "stripe": {"type": "side", "color": "#c9d1d9"}}, {"L": 4.48, "H": 1.42, "r_roof": 0.3, "r_nose": 0.18, "belt": 0.84, "trunk": 0.75})
v("sarbon_lola", "Lola", "Sarbon", "gm", "common", 12000, "Chevrolet Lacetti (hatchback)", "hatch", 107, 1180, 187, 60, "fwd", "i4", 0.98,
  {"color": "#c1121f", "rims": "alloy5", "doors": 4}, {"L": 4.3, "rw": 0.5})
v("sarbon_jasur", "Jasur", "Sarbon", "gm", "common", 15000, "Chevrolet Gentra", "sedan", 107, 1200, 187, 60, "fwd", "i4", 0.97,
  {"color": "#aeb8c2", "rims": "multi", "doors": 4}, {"L": 4.52, "r_roof": 0.55})
v("sarbon_feruza", "Feruza", "Sarbon", "gm", "common", 18000, "Chevrolet Cobalt", "sedan", 106, 1150, 170, 46, "fwd", "i4", 1.02,
  {"color": "#2f6fd6", "rims": "alloy5", "doors": 4}, {"L": 4.48, "H": 1.51, "hood": 0.95, "trunk": 0.72, "belt": 0.9})
v("sarbon_zumrad", "Zumrad", "Sarbon", "gm", "rare", 32000, "Chevrolet Onix", "sedan", 116, 1120, 190, 44, "fwd", "i4", 1.05,
  {"color": "#ff7b29", "rims": "sport", "doors": 4, "two_tone": "#1d2128"}, {"L": 4.47, "ws": 0.9, "rw": 0.7, "trunk": 0.5}, grip=1.1)
v("sarbon_izchi", "Izchi", "Sarbon", "gm", "rare", 45000, "Chevrolet Tracker", "crossover", 132, 1310, 190, 48, "awd", "i4", 0.95,
  {"color": "#0fa3b1", "rims": "alloy5", "doors": 4, "two_tone": "#20262e", "acc": ["roof_rack"]}, {"L": 4.27})
v("sarbon_sohil", "Sohil", "Sarbon", "gm", "rare", 55000, "Chevrolet Malibu", "sedan", 160, 1450, 210, 62, "fwd", "i4", 0.9,
  {"color": "#1b263b", "rims": "chrome", "doors": 4, "stripe": {"type": "side", "color": "#c9d1d9"}}, {"L": 4.93, "H": 1.46, "ws": 1.0, "rw": 0.85, "trunk": 0.6, "hood": 1.15}, grip=1.12)
v("sarbon_karvon", "Karvon", "Sarbon", "gm", "rare", 62000, "Chevrolet Captiva", "suv", 167, 1750, 190, 65, "awd", "i4_turbo", 0.9,
  {"color": "#6c757d", "rims": "multi", "doors": 4, "acc": ["roof_rack"]}, {"L": 4.67, "H": 1.76, "r_roof": 0.35})
v("sarbon_tengkun", "Tengkun", "Sarbon", "gm", "rare", 70000, "Chevrolet Equinox", "crossover", 170, 1600, 200, 59, "awd", "i4_turbo", 0.92,
  {"color": "#9d0208", "rims": "sport", "doors": 4}, {"L": 4.65, "H": 1.69})
v("sarbon_oila", "Oila", "Sarbon", "gm", "rare", 38000, "Chevrolet Orlando", "mpv", 141, 1530, 185, 64, "fwd", "i4", 0.95,
  {"color": "#d4a373", "rims": "alloy5", "doors": 4, "acc": ["roof_rack"]}, fuel_time=56)
v("sarbon_yolchi", "Yoʻlchi", "Sarbon", "gm", "rare", 85000, "Chevrolet Trailblazer", "suv", 200, 2000, 180, 76, "awd", "diesel", 1.0,
  {"color": "#386641", "rims": "offroad", "tire": "offroad", "doors": 4, "acc": ["roof_rack", "bull_bar"]}, {"L": 4.88})
v("sarbon_qoya", "Qoya", "Sarbon", "gm", "rare", 90000, "Chevrolet Colorado", "pickup", 200, 1950, 175, 80, "awd", "v6", 1.05,
  {"color": "#f77f00", "rims": "offroad", "tire": "offroad", "doors": 4, "acc": ["light_bar", "spare_bed"]}, {"L": 5.36, "H": 1.8})
v("sarbon_chimgan", "Chimgan", "Sarbon", "gm", "epic", 160000, "Chevrolet Tahoe", "suv", 355, 2550, 180, 98, "awd", "v8", 0.95,
  {"color": "#14181f", "rims": "chrome", "doors": 4, "chrome": False, "acc": ["roof_rack"]}, {"L": 5.35, "H": 1.93})
v("sarbon_mahalla", "Mahalla", "Sarbon", "gm", "epic", 175000, "Chevrolet Suburban", "suv", 355, 2650, 180, 106, "awd", "v8", 0.93,
  {"color": "#f8f9fa", "two_tone": "#2b2d42", "rims": "chrome", "doors": 4, "acc": ["roof_rack"]}, {"L": 5.75, "H": 1.93}, fuel_time=60)
v("sarbon_arslon", "Arslon", "Sarbon", "gm", "epic", 220000, "Chevrolet Camaro", "muscle", 455, 1700, 290, 72, "rwd", "v8_muscle", 0.95,
  {"color": "#ffc300", "rims": "sport", "rim_color": "#2b2d42", "doors": 2, "stripe": {"type": "double", "color": "#111111"}, "acc": ["spoiler", "hood_scoop"]})
v("sarbon_kumush", "Kumush", "Sarbon", "gm", "epic", 190000, "Chevrolet Silverado", "pickup", 420, 2350, 185, 91, "awd", "v8", 0.9,
  {"color": "#c0c7cf", "rims": "chrome", "tire": "offroad", "doors": 4, "acc": ["cargo_crates"]}, {"L": 5.85, "H": 1.92})
v("sarbon_burgut", "Burgut", "Sarbon", "gm", "legendary", 650000, "Chevrolet Corvette (C8)", "super", 495, 1530, 312, 70, "rwd", "v8_muscle", 1.12,
  {"color": "#d00000", "rims": "sport", "rim_color": "#1d1d1d", "doors": 2, "acc": ["spoiler"], "stripe": {"type": "swoosh", "color": "#1d1d1d"}})
v("granit_tizma", "Tizma", "Granit", "gm", "epic", 240000, "GMC Sierra", "pickup", 420, 2400, 185, 91, "awd", "v8", 0.88,
  {"color": "#7f1d1d", "rims": "offroad", "tire": "offroad", "doors": 4, "chrome": True, "acc": ["light_bar", "bull_bar"]}, {"L": 5.9, "H": 1.95, "nose": 1.05})
v("granit_chaqmoq", "Chaqmoq EV", "Granit", "gm", "legendary", 900000, "GMC Hummer EV", "pickup", 1000, 4100, 170, 212, "awd", "electric", 1.0,
  {"color": "#e9ecef", "rims": "offroad", "rim_color": "#3a86ff", "tire": "mud", "doors": 4, "two_tone": "#212529", "acc": ["light_bar", "spare_bed"], "headlight": "#bde0fe"},
  {"L": 5.5, "H": 2.0, "trunk": 1.5, "wr": 0.46, "clear": 0.32, "r_nose": 0.12}, travel=0.42, fuel_unit="kWh", grip=1.3)
v("oltin_saroy", "Saroy", "Oltin", "gm", "legendary", 750000, "Cadillac Escalade", "suv", 420, 2700, 200, 91, "awd", "v8", 0.88,
  {"color": "#0b0c10", "rims": "chrome", "doors": 4, "chrome": True, "stripe": {"type": "side", "color": "#c9a227"}}, {"L": 5.38, "H": 1.94, "nose": 1.02})
v("bunyod_qorgon", "Qoʻrgʻon", "Bunyod", "gm", "epic", 140000, "Buick Enclave", "suv", 310, 2100, 210, 82, "awd", "v6", 0.95,
  {"color": "#b08968", "rims": "chrome", "doors": 4, "acc": ["roof_rack"]}, {"L": 5.2, "H": 1.78, "r_roof": 0.4, "rw": 0.3})

# ---------------- Sports ----------------
v("kometa_rs", "Kometa RS", "Kometa", "sports", "rare", 75000, "original hot hatch", "hatch", 230, 1350, 245, 50, "fwd", "i4_turbo", 1.1,
  {"color": "#4361ee", "rims": "sport", "doors": 2, "stripe": {"type": "rally", "color": "#ffffff", "number": 7}, "acc": ["spoiler"]}, {"H": 1.38, "L": 4.1}, grip=1.2)
v("strela_roadster", "Strela", "Strela", "sports", "rare", 95000, "original roadster", "coupe", 180, 1050, 225, 45, "rwd", "i4", 1.15,
  {"color": "#06d6a0", "rims": "sport", "doors": 2, "open": True, "helmet": "#ef476f"}, {"L": 4.0, "H": 1.2})
v("shamol_gt", "Shamol GT", "Shamol", "sports", "epic", 260000, "original GT coupe", "coupe", 330, 1500, 265, 60, "rwd", "v6", 1.05,
  {"color": "#3a0ca3", "rims": "sport", "doors": 2, "stripe": {"type": "swoosh", "color": "#f72585"}, "acc": ["wing"]})
v("samum_rally", "Samum", "Samum", "sports", "epic", 300000, "original rally car", "hatch", 300, 1300, 230, 60, "awd", "i4_turbo", 1.15,
  {"color": "#f1faee", "rims": "offroad", "tire": "offroad", "doors": 4, "stripe": {"type": "rally", "color": "#e63946", "number": 21}, "acc": ["wing", "roof_rack"]}, {"H": 1.48, "clear": 0.22, "wr": 0.33}, travel=0.3, grip=1.3)
v("tulpor_v8", "Tulpor V8", "Tulpor", "sports", "epic", 380000, "original grand tourer", "coupe", 520, 1750, 300, 75, "rwd", "v8_muscle", 1.0,
  {"color": "#0b3d91", "rims": "chrome", "doors": 2, "stripe": {"type": "double", "color": "#ffd166"}}, {"L": 4.75, "hood": 1.6})
v("boron_r", "Boʻron R", "Boʻron", "sports", "legendary", 1100000, "original track car", "super", 600, 1400, 320, 65, "rwd", "v12", 1.1,
  {"color": "#ff006e", "rims": "turbine", "rim_color": "#ffffff", "doors": 2, "stripe": {"type": "rally", "color": "#111111", "number": 1}, "acc": ["wing"]}, grip=1.4)

# ---------------- SUV ----------------
v("yaylov", "Yaylov", "Yaylov", "suv", "common", 22000, "original compact SUV", "crossover", 120, 1300, 175, 50, "awd", "i4", 1.02,
  {"color": "#80b918", "rims": "alloy5", "doors": 4, "acc": ["roof_rack"]}, {"L": 4.15})
v("bulut", "Bulut", "Bulut", "suv", "rare", 98000, "original luxury crossover", "crossover", 250, 1800, 220, 65, "awd", "v6", 0.95,
  {"color": "#e0e1dd", "two_tone": "#1b263b", "rims": "chrome", "doors": 4, "sunroof": True}, {"L": 4.75, "rw": 0.55, "H": 1.6})
v("pomir", "Pomir", "Pomir", "suv", "epic", 210000, "original off-road SUV", "suv", 280, 2200, 185, 90, "awd", "diesel", 0.95,
  {"color": "#bc6c25", "rims": "offroad", "tire": "offroad", "doors": 4, "acc": ["roof_rack", "spare", "snorkel", "bull_bar"]}, {"L": 4.7, "clear": 0.32, "wr": 0.44}, travel=0.4, grip=1.3)
v("tyanshan_pro", "Tyan-Shan Pro", "Pomir", "suv", "legendary", 820000, "original expedition SUV", "suv", 450, 2450, 210, 100, "awd", "v8", 0.9,
  {"color": "#283618", "rims": "offroad", "tire": "mud", "doors": 4, "acc": ["light_bar", "spare", "snorkel", "ladder", "cargo_box"]}, {"L": 5.0, "H": 2.0, "clear": 0.38, "wr": 0.48}, travel=0.48, grip=1.4)

# ---------------- Pickups ----------------
v("dehqon", "Dehqon", "Dehqon", "pickup", "common", 10000, "original classic farm pickup", "pickup", 75, 1250, 130, 55, "rwd", "i4", 0.85,
  {"color": "#8ecae6", "rims": "steel", "doors": 2, "acc": ["cargo_hay"], "rim_color": "#e9ecef"}, {"L": 4.9, "H": 1.75, "r_nose": 0.35, "r_roof": 0.35}, fuel_time=52)
v("ishchi", "Ishchi", "Ishchi", "pickup", "common", 25000, "original work pickup", "pickup", 150, 1700, 165, 70, "awd", "diesel", 1.05,
  {"color": "#ffb703", "rims": "steel", "tire": "offroad", "doors": 2, "acc": ["ladder", "beacon"]})
v("bars", "Bars", "Bars", "pickup", "epic", 330000, "original sport pickup", "pickup", 450, 2300, 200, 100, "awd", "v8", 0.92,
  {"color": "#1d3557", "rims": "offroad", "tire": "offroad", "doors": 4, "stripe": {"type": "swoosh", "color": "#a8dadc"}, "acc": ["light_bar", "spare_bed"]}, {"clear": 0.36, "wr": 0.45}, travel=0.45, grip=1.3)
v("pahlavon", "Pahlavon", "Pahlavon", "pickup", "epic", 280000, "original heavy-duty pickup", "pickup", 445, 3500, 160, 136, "awd", "diesel", 0.8,
  {"color": "#495057", "rims": "chrome", "tire": "offroad", "doors": 4, "chrome": True, "acc": ["cargo_crates", "exhaust_stack"]}, {"L": 6.4, "H": 2.0, "axles": 3, "trunk": 2.4}, fuel_time=52, grip=1.3)

# ---------------- Off-road ----------------
v("echki", "Echki 4x4", "Echki", "offroad", "common", 14000, "original classic small 4x4", "boxy4x4", 80, 1250, 140, 42, "awd", "i4", 0.92,
  {"color": "#588157", "rims": "steel", "tire": "offroad", "doors": 2, "acc": ["spare", "roof_rack"]})
v("qumloq", "Qumloq", "Qumloq", "offroad", "rare", 65000, "original dune buggy", "buggy", 170, 750, 160, 40, "rwd", "flat4", 1.15,
  {"color": "#ff6b35", "rims": "offroad", "tire": "offroad", "helmet": "#ffd166"})
v("jayron", "Jayron", "Jayron", "offroad", "epic", 290000, "original rally-raid truck", "trophy", 380, 1900, 190, 120, "awd", "v6", 1.0,
  {"color": "#f4a261", "rims": "offroad", "tire": "offroad", "doors": 2, "stripe": {"type": "rally", "color": "#264653", "number": 33}, "acc": ["light_bar", "spare_bed"]}, {"L": 4.9})
v("ayiq", "Ayiq", "Ayiq", "offroad", "epic", 250000, "original rock crawler", "crawler", 300, 2100, 120, 80, "awd", "v8", 0.8,
  {"color": "#2a9d8f", "rims": "offroad", "tire": "mud", "doors": 2, "acc": ["light_bar", "bull_bar", "spare"]}, fuel_time=60)
v("chayon", "Chayon", "Chayon", "offroad", "legendary", 1300000, "original trophy truck", "trophy", 850, 2700, 220, 200, "rwd", "v8_muscle", 0.85,
  {"color": "#111111", "rims": "offroad", "tire": "offroad", "doors": 2, "stripe": {"type": "swoosh", "color": "#ffd60a"}, "acc": ["light_bar", "spare_bed"]}, grip=1.45)

# ---------------- Classic ----------------
v("qongiz", "Qoʻngʻiz", "Retro", "classic", "common", 8000, "original 1950s round compact", "beetle", 50, 820, 120, 40, "rwd", "flat4", 1.2,
  {"color": "#8fd0dc", "rims": "classic", "tire": "whitewall", "doors": 2, "rim_color": "#f1f3f5"}, fuel_time=52)
v("poytaxt", "Poytaxt", "Retro", "classic", "common", 11000, "original 1970s boxy sedan", "classic", 75, 1050, 145, 46, "rwd", "i4", 0.95,
  {"color": "#e9c46a", "rims": "steel", "doors": 4, "chrome": True}, {"L": 4.2, "H": 1.45})
v("oqqush", "Oqqush", "Retro", "classic", "rare", 42000, "original 1960s saloon", "classic", 95, 1450, 145, 55, "rwd", "i4", 0.85,
  {"color": "#f8f9fa", "two_tone": "#264653", "rims": "classic", "tire": "whitewall", "doors": 4, "chrome": True}, {"L": 4.85, "r_roof": 0.4})
v("afsona_69", "Afsona '69", "Retro", "classic", "epic", 200000, "original 1969 muscle car", "muscle", 375, 1600, 220, 76, "rwd", "v8_muscle", 0.9,
  {"color": "#2d6a4f", "rims": "chrome", "doors": 2, "chrome": True, "stripe": {"type": "rally", "color": "#ffffff"}, "acc": ["hood_scoop"]}, {"r_roof": 0.25, "r_nose": 0.1})
v("oltin_davr", "Oltin Davr", "Retro", "classic", "epic", 150000, "original 1950s finned cruiser", "finned", 315, 2000, 190, 80, "rwd", "v8", 0.85,
  {"color": "#e56b6f", "two_tone": "#fff5e1", "rims": "chrome", "tire": "whitewall", "doors": 2, "chrome": True, "acc": ["fins"]})

# ---------------- Special ----------------
v("chaqqon_kart", "Chaqqon Kart", "Chaqqon", "special", "common", 7500, "original go-kart", "kart", 15, 170, 90, 8, "rwd", "kart", 1.0,
  {"color": "#00b4d8", "rims": "kart", "tire": "slick", "helmet": "#ffd60a", "suit": "#ef233c"}, fuel_time=48)
v("bogbon", "Bogʻbon", "Bogʻbon", "special", "rare", 35000, "original farm tractor", "tractor", 80, 3000, 40, 120, "awd", "tractor", 1.0,
  {"color": "#2b9348", "rims": "steel", "rim_color": "#ffd60a", "tire": "mud", "acc": ["exhaust_stack"], "suit": "#3a5a40"}, fuel_time=70, accel_mult=1.45)
v("yolovchi", "Yoʻlovchi", "Karvon", "special", "rare", 60000, "original city bus", "bus", 250, 9000, 100, 200, "rwd", "diesel", 0.75,
  {"color": "#ffd23f", "rims": "steel", "stripe": {"type": "lower", "color": "#3a86ff"}}, fuel_time=62, accel_mult=1.15)
v("tez_yordam", "Tez Yordam", "Karvon", "special", "rare", 50000, "original ambulance van", "van", 190, 2600, 160, 80, "rwd", "v6", 1.0,
  {"color": "#ffffff", "rims": "steel", "stripe": {"type": "cross", "color": "#e63946"}, "acc": ["beacon"]})
v("muzqaymoq", "Muzqaymoq", "Sarbon", "special", "common", 9500, "original ice-cream microvan", "microvan", 60, 1100, 120, 45, "rwd", "i3", 1.2,
  {"color": "#ffc8dd", "rims": "steel", "stripe": {"type": "lower", "color": "#a2d2ff"}, "acc": ["ice_cream"]}, fuel_time=58)
v("dev_monster", "Dev", "Dev", "special", "epic", 450000, "original monster truck", "monster", 1500, 4500, 110, 150, "awd", "v8_muscle", 0.7,
  {"color": "#7b2ff7", "rims": "offroad", "tire": "mud", "doors": 2, "stripe": {"type": "swoosh", "color": "#3ef2c2"}, "acc": ["roll_bar"]})
v("oy_rover", "Oy Rover", "Kosmos", "special", "legendary", 180, "original lunar rover", "rover", 60, 700, 60, 50, "awd", "electric", 1.3,
  {"color": "#d9d9d9", "color2": "#c9a227", "rims": "turbine", "helmet": "#f8f9fa", "suit": "#e9ecef", "acc": ["dish"]},
  currency="gems", gravity_scale=0.78, fuel_unit="kWh", fuel_time=70)

# ---------------- Fictional premium ----------------
v("shohona_gt", "Shohona GT", "Shohona", "premium", "legendary", 1200000, "original luxury grand tourer", "coupe", 610, 2200, 310, 90, "awd", "v12", 0.92,
  {"color": "#0d1b2a", "rims": "chrome", "doors": 2, "chrome": True, "stripe": {"type": "side", "color": "#c9a227"}}, {"L": 4.95, "hood": 1.7, "H": 1.32})
v("zarafshon_royale", "Zarafshon Royale", "Shohona", "premium", "legendary", 950000, "original luxury SUV", "suv", 560, 2600, 250, 100, "awd", "v12", 0.85,
  {"color": "#5a189a", "two_tone": "#e0aaff", "rims": "chrome", "doors": 4, "chrome": True}, {"L": 5.3, "H": 1.85, "r_roof": 0.3})
v("aurora_ev", "Aurora EV", "Aurora", "premium", "legendary", 1600000, "original electric hypercar", "super", 1200, 2000, 350, 120, "awd", "electric", 1.15,
  {"color": "#caf0f8", "rims": "turbine", "rim_color": "#00b4d8", "doors": 2, "stripe": {"type": "swoosh", "color": "#00b4d8"}, "headlight": "#90e0ef"}, fuel_unit="kWh", grip=1.45)
v("simurg_x", "Simurg X", "Simurg", "premium", "legendary", 2000000, "original hypercar", "super", 1100, 1450, 380, 80, "rwd", "v12", 1.2,
  {"color": "#ff9f1c", "rims": "sport", "rim_color": "#111111", "doors": 2, "stripe": {"type": "double", "color": "#111111"}, "acc": ["wing"]}, {"H": 1.08, "L": 4.7}, grip=1.45)
v("nebula_r", "Nebula R", "Nebula", "premium", "legendary", 1800000, "original concept car", "super", 900, 1200, 340, 70, "awd", "electric", 1.35,
  {"color": "#240046", "rims": "turbine", "rim_color": "#c77dff", "doors": 2, "stripe": {"type": "swoosh", "color": "#c77dff"}, "headlight": "#e0aaff", "glass": "#3c096c"},
  {"H": 1.1, "ws": 1.25, "rw": 1.5, "hood": 0.85}, fuel_unit="kWh", grip=1.5)


def build():
    out = []
    order = 0
    for r in R:
        order += 1
        a = dict(ARCH[r["typ"]])
        desc = a.pop("desc")
        rar = RARITY[r["rar"]]
        ex = r["extra"]
        handling = {k: a[k] for k in ["grip", "suspension", "travel", "com_h", "front_bias", "air_control"]}
        for k in ["grip", "suspension", "travel", "com_h", "front_bias", "air_control", "gravity_scale", "accel_mult"]:
            if k in ex:
                handling[k] = ex[k]
        handling["fuel_time"] = ex.get("fuel_time", rar["fuel_time"])
        price = r["price"]
        currency = ex.get("currency", "coins")
        max_lv = ex.get("max_level", rar["max"])
        coin_equiv = price * 6000 if currency == "gems" else price
        cost_base = int(round((140 + coin_equiv * 0.011) / 10.0) * 10)
        body = {"type": r["typ"]}
        body.update(r["body"])
        out.append({
            "id": r["id"],
            "name": r["name"],
            "maker": r["maker"],
            "category": r["cat"],
            "rarity": r["rar"],
            "price": price,
            "currency": currency,
            "unlock": ex.get("unlock", "purchase"),
            "order": order,
            "desc_key": "veh_desc_" + desc,
            "inspired_by": r["insp"],
            "license": {"licensed": False, "brand": "", "model": "", "logo": ""},
            "specs": {"power_hp": r["hp"], "weight_kg": r["kg"], "top_kmh": r["kmh"], "fuel_l": r["fuel"],
                      "fuel_unit": ex.get("fuel_unit", "L"), "drive": r["drive"]},
            "handling": handling,
            "upgrades": {"max": max_lv, "cost_base": cost_base},
            "engine_sound": {"profile": r["eng"], "pitch": r["pitch"]},
            "body": body,
            "style": r["style"],
        })
    return out


if __name__ == "__main__":
    vs = build()
    ids = [v["id"] for v in vs]
    assert len(ids) == len(set(ids)), "duplicate ids"
    doc = {
        "_comment": "Generated by tools/build_vehicles.py - original fictional vehicles. 'inspired_by' is internal only and never displayed. Set license.licensed=true with brand/model/logo once official licensing is obtained.",
        "version": 1,
        "vehicles": vs,
    }
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, indent=1)
    by = {}
    for x in vs:
        by.setdefault(x["category"], 0)
        by[x["category"]] += 1
    print("wrote", len(vs), "vehicles", by)
