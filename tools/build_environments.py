#!/usr/bin/env python3
"""Generates data/environments.json (8 maps). The JSON is the runtime source of
truth; this script just keeps the long colour/terrain tables readable.
Run: python3 tools/build_environments.py
"""
import json, os

OUT = os.path.join(os.path.dirname(__file__), "..", "data", "environments.json")

BASE_TIERS = [[0, 5, 10], [300, 10, 25], [800, 25, 50], [1500, 50, 100], [2500, 100, 250], [4000, 250, 500]]

def tiers(shift_m):
    """Shift coin tiers earlier on later maps (harder map = richer coins)."""
    return [[max(0, t[0] - shift_m) if i > 0 else 0, t[1], t[2]] for i, t in enumerate(BASE_TIERS)]

ENVS = [
    dict(
        id="green_hills", order=1, goal_m=1500, unlock_cost=0, reward_mult=1.0, music="drive_a",
        surface=dict(grip=1.0, roll=0.016),
        patch=dict(type="mud", chance=0.07, grip=0.72, roll=0.07),
        terrain=dict(seed=1101, start_flat=30, amp=1.8, amp_max=6.0, max_slope=0.42, max_slope_late=0.8, spacing=[9, 17],
                     trend=0.0, difficulty_dist=2600,
                     features=dict(hills=1.0, flat=0.25, bumps=0.2, jump=0.18, bridge=0.08, valley=0.15, climb=0.1)),
        obstacles=dict(chance=0.25, kinds=["rock", "log"], min=0.22, max=0.42),
        pickups=dict(fuel_first=170, fuel_base=200, fuel_growth=0.06, fuel_max=420, gem_every=700, boost_every=260, coin_gap=[26, 42]),
        coin_tiers=tiers(0),
        visual=dict(
            sky=["#4fa9ec", "#d4efff"], sun=dict(color="#fff6c9", x=0.78, y=0.18, r=46), clouds=dict(color="#ffffff", count=7),
            ground="#8a5a35", ground_dark="#3f2414", top="#6cc04a", top_dark="#3d8c2e", top_h=0.34,
            patch_top="#7a5434", patch_top_dark="#4e331d", texture="ground_soil", rock="#9a9ca0",
            bridge="#9b6a3f", water="#3fa7d6", ramp_style="dirt",
            decor_back=[["tree_round", 0.32, "#4fa83d", 0.85, 1.35], ["bush", 0.3, "#5cb648", 0.7, 1.1], ["rock", 0.06, "#9a9ca0", 0.6, 1.0]],
            decor_front=[["grass", 1.1, "#4f9e3a", 0.8, 1.2], ["flowers", 0.35, "#ffffff", 0.8, 1.1]],
            layers=[
                dict(kind="mountains", color="#a8c8e0", y=-150, h=330, scroll=0.06, rough=0.35, snow=True, seed=3),
                dict(kind="hills", color="#93cf74", y=-40, h=230, scroll=0.16, decor="trees", decor_color="#79b960", seed=5),
                dict(kind="hills", color="#74ba59", y=40, h=190, scroll=0.32, decor="trees", decor_color="#5ea347", seed=8),
            ],
            weather="none",
        ),
    ),
    dict(
        id="countryside", order=2, goal_m=2000, unlock_cost=8000, reward_mult=1.15, music="drive_a",
        surface=dict(grip=1.0, roll=0.017),
        patch=dict(type="mud", chance=0.1, grip=0.7, roll=0.08),
        terrain=dict(seed=2207, start_flat=30, amp=2.0, amp_max=6.5, max_slope=0.48, max_slope_late=0.84, spacing=[8, 15],
                     trend=0.0, difficulty_dist=2800, bump_scale=1.1,
                     features=dict(hills=1.0, flat=0.2, bumps=0.3, jump=0.2, bridge=0.16, trench=0.1, valley=0.12)),
        obstacles=dict(chance=0.3, kinds=["bale", "rock"], min=0.25, max=0.45),
        pickups=dict(fuel_first=170, fuel_base=210, fuel_growth=0.06, fuel_max=440, gem_every=680, boost_every=250, coin_gap=[25, 40]),
        coin_tiers=tiers(50), bridge_water=True,
        visual=dict(
            sky=["#5cb7f0", "#fff0cf"], sun=dict(color="#fff1b8", x=0.2, y=0.2, r=52), clouds=dict(color="#ffffff", count=6),
            ground="#9b6b43", ground_dark="#4a2e19", top="#8fcf4f", top_dark="#5b9a2c", top_h=0.32,
            patch_top="#7b5534", patch_top_dark="#523620", texture="ground_farm", rock="#a39a8e",
            bridge="#a0703f", water="#4ab3e0", ramp_style="wood",
            decor_back=[["poplar", 0.3, "#3f8f3a", 0.85, 1.3], ["house", 0.035, "#f2e8cf", 0.9, 1.1], ["fence", 0.22, "#8a6a4a", 0.9, 1.1],
                        ["haystack", 0.08, "#e8c35a", 0.8, 1.1], ["sunflower", 0.3, "#ffffff", 0.8, 1.2]],
            decor_front=[["grass", 1.0, "#6aa83a", 0.8, 1.2], ["flowers", 0.2, "#ffffff", 0.8, 1.0]],
            layers=[
                dict(kind="hills", color="#b9d7a3", y=-120, h=260, scroll=0.06, decor="none", seed=12),
                dict(kind="fields", color="#d9c96a", color2="#bfd56a", y=-30, h=210, scroll=0.16, decor="poplars", decor_color="#5c9e48", seed=14),
                dict(kind="hills", color="#88c25a", y=50, h=170, scroll=0.33, decor="trees", decor_color="#6aa843", seed=17),
            ],
            weather="none",
        ),
    ),
    dict(
        id="desert_road", order=3, goal_m=2500, unlock_cost=25000, reward_mult=1.3, music="drive_a",
        surface=dict(grip=0.92, roll=0.028),
        patch=dict(type="deep_sand", chance=0.15, grip=0.78, roll=0.11),
        terrain=dict(seed=3313, start_flat=30, amp=2.6, amp_max=7.5, max_slope=0.48, max_slope_late=0.86, spacing=[12, 22],
                     trend=0.0, difficulty_dist=3000,
                     features=dict(dunes=1.0, hills=0.4, jump=0.3, climb=0.15, valley=0.2, flat=0.15)),
        obstacles=dict(chance=0.18, kinds=["rock"], min=0.25, max=0.5),
        pickups=dict(fuel_first=180, fuel_base=240, fuel_growth=0.07, fuel_max=480, gem_every=650, boost_every=240, coin_gap=[24, 40]),
        coin_tiers=tiers(100),
        visual=dict(
            sky=["#3d9be0", "#fbe4b6"], sun=dict(color="#fff3d1", x=0.72, y=0.14, r=60), clouds=dict(color="#fff7ea", count=3),
            ground="#d9a45c", ground_dark="#8a5626", top="#f2cf8a", top_dark="#d9a85b", top_h=0.3,
            patch_top="#c98b45", patch_top_dark="#a8712f", texture="ground_sand", rock="#b5835a",
            bridge="#a0703f", water="#3fa7d6", ramp_style="dirt",
            decor_back=[["saxaul", 0.16, "#7f9450", 0.8, 1.2], ["rock", 0.1, "#b5835a", 0.7, 1.3], ["skull", 0.03, "#ffffff", 0.9, 1.1]],
            decor_front=[["grass", 0.3, "#b59a5a", 0.7, 1.0]],
            layers=[
                dict(kind="mesa", color="#e0a370", y=-110, h=260, scroll=0.05, seed=21),
                dict(kind="dunes", color="#efc283", y=-20, h=210, scroll=0.15, seed=23),
                dict(kind="dunes", color="#e7b065", y=60, h=170, scroll=0.3, seed=27),
            ],
            weather="dust",
        ),
    ),
    dict(
        id="forest", order=4, goal_m=2500, unlock_cost=50000, reward_mult=1.45, music="drive_b",
        surface=dict(grip=0.98, roll=0.02),
        patch=dict(type="mud", chance=0.17, grip=0.66, roll=0.1),
        terrain=dict(seed=4421, start_flat=30, amp=2.3, amp_max=7.0, max_slope=0.52, max_slope_late=0.88, spacing=[7, 14],
                     trend=0.0, difficulty_dist=3000, bump_scale=1.2,
                     features=dict(hills=1.0, bumps=0.35, steps=0.2, bridge=0.2, valley=0.2, climb=0.15, jump=0.12)),
        obstacles=dict(chance=0.45, kinds=["log", "rock", "log"], min=0.24, max=0.42),
        pickups=dict(fuel_first=170, fuel_base=210, fuel_growth=0.065, fuel_max=460, gem_every=620, boost_every=240, coin_gap=[24, 38]),
        coin_tiers=tiers(150), bridge_water=True,
        visual=dict(
            sky=["#76b0cf", "#dcefe2"], sun=dict(color="#fffbe6", x=0.3, y=0.12, r=40), clouds=dict(color="#f2fbff", count=5),
            ground="#5a3d28", ground_dark="#22150b", top="#3f8a3a", top_dark="#285f25", top_h=0.32,
            patch_top="#6b4a2b", patch_top_dark="#45301b", texture="ground_forest", rock="#7c8078",
            bridge="#8a5a34", water="#3d8fb5", ramp_style="wood",
            decor_back=[["pine", 0.55, "#2e6b3f", 0.85, 1.45], ["tree_round", 0.15, "#3f8f45", 0.9, 1.3], ["mushroom", 0.18, "#ffffff", 0.8, 1.2], ["fern", 0.3, "#3f8a3a", 0.8, 1.1]],
            decor_front=[["grass", 0.8, "#3f7f35", 0.8, 1.2], ["fern", 0.1, "#4c9a40", 0.6, 0.8]],
            layers=[
                dict(kind="mountains", color="#86aab5", y=-160, h=320, scroll=0.05, rough=0.4, seed=31),
                dict(kind="hills", color="#3f7a5a", y=-60, h=240, scroll=0.15, decor="pines", decor_color="#2f6a4c", seed=33),
                dict(kind="hills", color="#2c6145", y=20, h=200, scroll=0.3, decor="pines", decor_color="#1f4f36", seed=37),
            ],
            weather="leaves",
        ),
    ),
    dict(
        id="city_roads", order=5, goal_m=3000, unlock_cost=90000, reward_mult=1.6, music="drive_a",
        surface=dict(grip=1.12, roll=0.012),
        patch=dict(type="wet", chance=0.07, grip=0.8, roll=0.012),
        terrain=dict(seed=5531, start_flat=30, amp=1.8, amp_max=5.5, max_slope=0.45, max_slope_late=0.8, spacing=[10, 18],
                     trend=0.0, difficulty_dist=3200,
                     features=dict(hills=0.8, flat=0.3, jump=0.4, trench=0.25, bumps=0.2, bridge=0.12, climb=0.1)),
        obstacles=dict(chance=0.35, kinds=["bump", "crate", "bump"], min=0.22, max=0.36),
        pickups=dict(fuel_first=170, fuel_base=220, fuel_growth=0.065, fuel_max=470, gem_every=600, boost_every=220, coin_gap=[24, 38]),
        coin_tiers=tiers(250),
        visual=dict(
            sky=["#4facfe", "#cdeefc"], sun=dict(color="#ffffff", x=0.65, y=0.16, r=42), clouds=dict(color="#ffffff", count=5),
            ground="#7d7266", ground_dark="#2f2a25", top="#41464f", top_dark="#2a2d33", top_h=0.36, lane=True,
            patch_top="#2f4f6b", patch_top_dark="#24384b", texture="ground_city", rock="#8c8c8c",
            bridge="#7a8794", water="#3fa7d6", ramp_style="metal",
            decor_back=[["lamp", 0.2, "#4a5563", 0.9, 1.1], ["sign", 0.06, "#e63946", 0.9, 1.1], ["bench", 0.06, "#8a5a34", 0.9, 1.1],
                        ["tree_round", 0.12, "#5aa04a", 0.7, 1.0], ["hydrant", 0.05, "#ffffff", 0.9, 1.1]],
            decor_front=[["cone", 0.05, "#ffffff", 0.8, 1.0]],
            layers=[
                dict(kind="city", color="#9fb3c8", y=-200, h=360, scroll=0.05, seed=41, windows="#d9e6f2"),
                dict(kind="city", color="#7088a0", y=-90, h=300, scroll=0.14, seed=43, windows="#c3d4e4"),
                dict(kind="hills", color="#5d8c4a", y=60, h=150, scroll=0.3, decor="trees", decor_color="#4c7a3c", seed=47),
            ],
            weather="none",
        ),
    ),
    dict(
        id="snow_mountains", order=6, goal_m=3000, unlock_cost=150000, reward_mult=1.8, music="drive_b",
        surface=dict(grip=0.8, roll=0.026),
        patch=dict(type="ice", chance=0.14, grip=0.38, roll=0.008),
        terrain=dict(seed=6637, start_flat=30, amp=2.6, amp_max=7.5, max_slope=0.48, max_slope_late=0.85, spacing=[9, 18],
                     trend=0.02, difficulty_dist=3200,
                     features=dict(hills=1.0, climb=0.25, valley=0.2, bumps=0.2, jump=0.2, bridge=0.1, flat=0.15)),
        obstacles=dict(chance=0.25, kinds=["ice", "rock"], min=0.25, max=0.45),
        pickups=dict(fuel_first=170, fuel_base=220, fuel_growth=0.07, fuel_max=480, gem_every=600, boost_every=230, coin_gap=[24, 38]),
        coin_tiers=tiers(350),
        visual=dict(
            sky=["#8ec9ff", "#eef8ff"], sun=dict(color="#ffffff", x=0.75, y=0.2, r=38), clouds=dict(color="#ffffff", count=6),
            ground="#8aa2b8", ground_dark="#36475a", top="#f5fbff", top_dark="#c6dcef", top_h=0.4,
            patch_top="#bfe6ff", patch_top_dark="#86c3ec", texture="ground_snow", rock="#8796a5",
            bridge="#8a5a34", water="#9ad7f5", ramp_style="dirt",
            decor_back=[["pine_snow", 0.45, "#2f5d50", 0.85, 1.4], ["snow_mound", 0.12, "#ffffff", 0.8, 1.2], ["snowman", 0.02, "#ffffff", 0.9, 1.0], ["rock", 0.05, "#8796a5", 0.6, 1.0]],
            decor_front=[],
            layers=[
                dict(kind="mountains", color="#dbe8f5", y=-200, h=420, scroll=0.05, rough=0.75, snow=True, seed=51),
                dict(kind="mountains", color="#b7cfe6", y=-80, h=300, scroll=0.13, rough=0.6, snow=True, seed=53),
                dict(kind="hills", color="#e8f2fb", y=40, h=180, scroll=0.3, decor="snowpines", decor_color="#4a7c70", seed=57),
            ],
            weather="snow",
        ),
    ),
    dict(
        id="rocky_mountains", order=7, goal_m=3500, unlock_cost=250000, reward_mult=2.0, music="drive_b",
        surface=dict(grip=1.05, roll=0.02),
        patch=dict(type="gravel", chance=0.12, grip=0.78, roll=0.045),
        terrain=dict(seed=7741, start_flat=30, amp=3.2, amp_max=9.0, max_slope=0.58, max_slope_late=0.98, spacing=[7, 15],
                     trend=0.03, difficulty_dist=3400, bump_scale=1.3,
                     features=dict(hills=1.0, steps=0.4, climb=0.3, bridge=0.2, jump=0.25, bumps=0.3, valley=0.15)),
        obstacles=dict(chance=0.55, kinds=["rock", "rock", "rock"], min=0.28, max=0.6),
        pickups=dict(fuel_first=170, fuel_base=220, fuel_growth=0.07, fuel_max=500, gem_every=580, boost_every=220, coin_gap=[22, 36]),
        coin_tiers=tiers(450),
        visual=dict(
            sky=["#7fb0d6", "#f2e7d6"], sun=dict(color="#fff3dc", x=0.2, y=0.16, r=44), clouds=dict(color="#ffffff", count=4),
            ground="#8a7461", ground_dark="#2e241c", top="#a89580", top_dark="#7c6a58", top_h=0.3,
            patch_top="#9c9488", patch_top_dark="#77706a", texture="ground_rock", rock="#8a7a6c",
            bridge="#7a5230", water="#3fa7d6", ramp_style="dirt",
            decor_back=[["boulder", 0.08, "#8a7a6c", 0.7, 1.2], ["cairn", 0.05, "#9c8c7c", 0.9, 1.1], ["pine", 0.12, "#4a6b4a", 0.8, 1.2], ["rock", 0.22, "#958372", 0.6, 1.1]],
            decor_front=[["grass", 0.3, "#8a8a52", 0.7, 1.0]],
            layers=[
                dict(kind="mountains", color="#a5958a", y=-210, h=440, scroll=0.05, rough=0.95, snow=True, seed=61),
                dict(kind="mountains", color="#8b7b6e", y=-90, h=330, scroll=0.13, rough=0.85, snow=False, seed=63),
                dict(kind="rocks", color="#76675b", y=40, h=200, scroll=0.3, seed=67),
            ],
            weather="none",
        ),
    ),
    dict(
        id="night_highway", order=8, goal_m=4000, unlock_cost=400000, reward_mult=2.3, music="drive_b",
        surface=dict(grip=1.1, roll=0.012),
        patch=dict(type="wet", chance=0.08, grip=0.74, roll=0.012),
        terrain=dict(seed=8853, start_flat=30, amp=2.0, amp_max=6.0, max_slope=0.45, max_slope_late=0.78, spacing=[12, 22],
                     trend=0.0, difficulty_dist=3600,
                     features=dict(hills=0.7, flat=0.35, jump=0.5, trench=0.25, bridge=0.15, climb=0.1)),
        obstacles=dict(chance=0.3, kinds=["bump", "crate"], min=0.22, max=0.36),
        pickups=dict(fuel_first=170, fuel_base=230, fuel_growth=0.07, fuel_max=520, gem_every=560, boost_every=210, coin_gap=[22, 36]),
        coin_tiers=tiers(600), night=True,
        visual=dict(
            sky=["#070b1f", "#2b2f63"], moon=dict(color="#f4f1de", x=0.8, y=0.16, r=34), stars=110, clouds=dict(color="#3a3f73", count=3),
            ground="#2b2b38", ground_dark="#0b0b10", top="#3a3d4d", top_dark="#23252f", top_h=0.36, lane=True,
            patch_top="#2d4a66", patch_top_dark="#1e3247", texture="ground_night", rock="#585c6b",
            bridge="#596273", water="#1f3a5a", ramp_style="metal", ambient="#56628f",
            decor_back=[["lamp_lit", 0.22, "#454b5c", 0.95, 1.1], ["reflector", 0.4, "#ffffff", 0.9, 1.0], ["rail", 0.1, "#8a93a6", 0.9, 1.0], ["billboard", 0.03, "#ff4d6d", 0.9, 1.1]],
            decor_front=[],
            layers=[
                dict(kind="city", color="#161b38", y=-200, h=360, scroll=0.05, seed=71, windows="#ffd166", lit=True),
                dict(kind="hills", color="#11152b", y=-30, h=240, scroll=0.14, decor="none", seed=73),
                dict(kind="hills", color="#0c0f20", y=50, h=170, scroll=0.3, decor="lamps", decor_color="#ffd166", seed=77),
            ],
            weather="none",
        ),
    ),
]

if __name__ == "__main__":
    prev = None
    for e in ENVS:
        e["name_key"] = "map_" + e["id"]
        e["desc_key"] = "map_desc_" + e["id"]
        e["requires"] = prev
        e["checkpoint_every"] = 500
        e["complete_reward"] = {"coins": int(e["goal_m"] * 2 * e["reward_mult"]), "gems": 5 + e["order"] * 2}
        prev = e["id"]
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump({"version": 1, "environments": ENVS}, f, ensure_ascii=False, indent=1)
    print("wrote", len(ENVS), "environments")
