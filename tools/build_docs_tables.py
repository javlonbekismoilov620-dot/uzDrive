#!/usr/bin/env python3
"""Regenerates docs/VEHICLES.md (catalogue) and the numeric tables used in
docs/ECONOMY.md from the live data files. Run: python3 tools/build_docs_tables.py [coincurve.json]"""
import json, os, sys, math

ROOT = os.path.join(os.path.dirname(__file__), "..")
V = json.load(open(os.path.join(ROOT, "data/vehicles.json"), encoding="utf-8"))["vehicles"]
E = json.load(open(os.path.join(ROOT, "data/environments.json"), encoding="utf-8"))["environments"]
EN = json.load(open(os.path.join(ROOT, "data/i18n/en.json"), encoding="utf-8"))
ECO = json.load(open(os.path.join(ROOT, "data/economy.json"), encoding="utf-8"))
TYPE_MULT = {"engine": 1.25, "suspension": 1.0, "tires": 0.95, "fuel": 0.8}


def nice(v):
    if v < 1000: return int(round(v / 10) * 10)
    if v < 10000: return int(round(v / 50) * 50)
    if v < 100000: return int(round(v / 250) * 250)
    return int(round(v / 1000) * 1000)


def upg_total(v):
    mx = v["upgrades"]["max"]
    g = 12 ** (1 / max(mx - 1, 1))
    return sum(nice(v["upgrades"]["cost_base"] * TYPE_MULT[t] * g ** l) for t in TYPE_MULT for l in range(mx))


def vehicles_md():
    lines = ["# Vehicle catalogue", "",
             "Generated from `data/vehicles.json` by `tools/build_docs_tables.py`. All names, makers and artwork are original.",
             "`Inspired by` is an internal design reference only - it is never shown in the game (see ARCHITECTURE.md, Licensing).", "",
             "| # | Name | Maker | Category | Rarity | Price | hp | kg | km/h | Drive | Upg. max | Upgrade total | Inspired by (internal) |",
             "|---|------|-------|----------|--------|------:|---:|---:|-----:|-------|---------:|--------------:|------------------------|"]
    for i, v in enumerate(V, 1):
        cur = "💎" if v["currency"] == "gems" else ""
        lines.append(f"| {i} | {v['name']} | {v['maker']} | {EN['cat_' + v['category']]} | {v['rarity']} | {cur}{v['price']:,} | {v['specs']['power_hp']} | {v['specs']['weight_kg']} | {v['specs']['top_kmh']} | {v['specs']['drive'].upper()} | {v['upgrades']['max']} | {upg_total(v):,} | {v['inspired_by']} |")
    cats = {}
    for v in V:
        cats[v["category"]] = cats.get(v["category"], 0) + 1
    lines += ["", "**Totals:** %d vehicles - " % len(V) + ", ".join(f"{EN['cat_' + k]} {n}" for k, n in cats.items())]
    open(os.path.join(ROOT, "docs/VEHICLES.md"), "w", encoding="utf-8").write("\n".join(lines) + "\n")


def economy_tables(curve_path):
    out = []
    out.append("### Price ladder by rarity (coins)\n")
    out.append("| Rarity | Count | Cheapest | Median | Most expensive | Upgrade max level | Avg. cost to max all upgrades |")
    out.append("|---|---:|---:|---:|---:|---:|---:|")
    for r in ["common", "rare", "epic", "legendary"]:
        vs = [v for v in V if v["rarity"] == r and v["currency"] == "coins"]
        ps = sorted(v["price"] for v in vs)
        med = ps[len(ps) // 2]
        avg_up = sum(upg_total(v) for v in vs) // max(len(vs), 1)
        out.append(f"| {r} | {len(vs)} | {ps[0]:,} | {med:,} | {ps[-1]:,} | {vs[0]['upgrades']['max']} | {avg_up:,} |")
    if curve_path and os.path.exists(curve_path):
        cc = json.load(open(curve_path))
        out.append("\n### Coins available on the track (from the real generator)\n")
        out.append("Collectible coin value placed before a given distance. A run's payout adds the distance bonus (0.5 coin/m x map multiplier), checkpoint bonuses (150 x n, cumulative) and trick bonuses.\n")
        out.append("| Map | x reward | 500 m | 1000 m | 1500 m | 2000 m | 3000 m | 5000 m |")
        out.append("|---|---:|---:|---:|---:|---:|---:|---:|")
        for e in E:
            row = cc[e["id"]]
            out.append(f"| {EN[e['name_key']]} | {e['reward_mult']} | " + " | ".join(f"{row[m]['coins']:,}" for m in ["500", "1000", "1500", "2000", "3000", "5000"]) + " |")
        out.append("\n### Estimated payout per run (Green Hills, pickups collected ~70%, typical tricks)\n")
        out.append("| Run distance | Coins collected | Distance bonus | Checkpoints | Tricks | Total |")
        out.append("|---:|---:|---:|---:|---:|---:|")
        for d in [500, 1000, 1500, 2000, 3000]:
            col = int(cc["green_hills"][str(d)]["coins"] * 0.7)
            db = int(d * 0.5)
            cps = d // 500
            cpb = sum(150 * (i + 1) for i in range(cps))
            tr = int(d * 0.3)
            out.append(f"| {d:,} m | {col:,} | {db:,} | {cpb:,} | {tr:,} | {col + db + cpb + tr:,} |")
    return "\n".join(out)


if __name__ == "__main__":
    vehicles_md()
    tables = economy_tables(sys.argv[1] if len(sys.argv) > 1 else "")
    print(tables)
    print("docs tables written")
