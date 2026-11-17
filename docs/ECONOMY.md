# Economy & Balancing

## Principles
1. **Earned, not bought.** Every vehicle, upgrade and map is reachable by playing. Gems (premium currency) are only earned in-game. No real-money purchases exist; the store interface is reserved for optional cosmetics only.
2. **No gambling.** No loot boxes, random paid rewards or gacha mechanics. Every reward amount is shown before it is claimed.
3. **Always a next goal.** Common cars cost 1–7 runs, rare cars a session or two, epic cars several days, legendary cars are long-term goals.
4. **Safety.** All currency changes go through `Economy`: no negative balances, prices re-validated at purchase time, duplicate purchases rejected, one-off rewards claimed via unique ids (runs, missions, achievements, map completion, daily login), every transaction saved immediately. Purchases need confirmation (dialog for cars/maps/exchange, two-tap for upgrades).

## Sources
| Source | Amount |
|---|---|
| Coins on the track | 5 / 10 / 25 / 50 / 100 / 250 / 500 — value tier rises with distance; harder maps reach high tiers sooner |
| Distance bonus | 0.5 coin per metre × map multiplier (1.0 → 2.3) |
| Checkpoints (every 500 m) | 150 × n (cumulative: 150, 300, 450 …) × map multiplier |
| Tricks | flip 150, multi-flip 450/extra rotation, big air 100, huge air 250, wheelie 75 |
| Map completion (once per map) | coins = goal × 2 × multiplier, gems 7…21 |
| Daily missions | 350–2,600 coins each; +5 gems for all three |
| Achievements (15 × tiers) | 300–4,000 coins or 10–100 gems per tier |
| Daily login (7-day cycle) | 500, 1000, 3 gems, 2000, 3500, 5 gems, 6000 + 10 gems |
| Gems on the track | ~1 per 560–700 m |
| Start | 500 coins, 5 gems |

## Sinks
| Sink | Cost |
|---|---|
| Vehicles | 4,000 → 2,000,000 coins (one lunar rover: 180 gems) |
| Upgrades | 4 tracks × 8/10/12/15 levels, last level ≈ 12× first; base scales with vehicle price |
| Maps | 8,000 → 400,000 coins (or free by completing the previous map) |
| Revive (continue a run) | 5 / 10 / 20 gems |
| Gem → coin exchange | 10→5,000 · 50→28,000 · 150→95,000 |

### Price ladder by rarity (coins)

| Rarity | Count | Cheapest | Median | Most expensive | Upgrade max level | Avg. cost to max all upgrades |
|---|---:|---:|---:|---:|---:|---:|
| common | 16 | 0 | 10,000 | 25,000 | 8 | 39,425 |
| rare | 16 | 32,000 | 62,000 | 98,000 | 10 | 153,817 |
| epic | 17 | 140,000 | 240,000 | 450,000 | 12 | 636,835 |
| legendary | 11 | 650,000 | 1,100,000 | 2,000,000 | 15 | 3,626,477 |

### Coins available on the track (from the real generator)

Collectible coin value placed before a given distance. A run's payout adds the distance bonus (0.5 coin/m x map multiplier), checkpoint bonuses (150 x n, cumulative) and trick bonuses.

| Map | x reward | 500 m | 1000 m | 1500 m | 2000 m | 3000 m | 5000 m |
|---|---:|---:|---:|---:|---:|---:|---:|
| Green Hills | 1.0 | 1,240 | 3,480 | 6,730 | 12,830 | 29,380 | 121,530 |
| Countryside | 1.15 | 1,155 | 3,685 | 7,860 | 14,160 | 35,610 | 138,660 |
| Desert Road | 1.3 | 965 | 3,675 | 7,125 | 13,225 | 33,825 | 130,425 |
| Forest Adventure | 1.45 | 1,080 | 3,390 | 7,965 | 14,315 | 35,515 | 138,415 |
| City Roads | 1.6 | 1,530 | 4,325 | 9,650 | 16,800 | 38,900 | 139,400 |
| Snow Mountains | 1.8 | 2,115 | 5,190 | 11,090 | 16,540 | 47,790 | 159,590 |
| Rocky Mountains | 2.0 | 2,175 | 5,700 | 12,050 | 17,350 | 41,750 | 155,150 |
| Night Highway | 2.3 | 2,975 | 6,875 | 12,425 | 21,775 | 52,075 | 161,875 |

### Estimated payout per run (Green Hills, pickups collected ~70%, typical tricks)

| Run distance | Coins collected | Distance bonus | Checkpoints | Tricks | Total |
|---:|---:|---:|---:|---:|---:|
| 500 m | 868 | 250 | 150 | 150 | 1,418 |
| 1,000 m | 2,436 | 500 | 450 | 300 | 3,686 |
| 1,500 m | 4,711 | 750 | 900 | 450 | 6,811 |
| 2,000 m | 8,981 | 1,000 | 1,500 | 600 | 12,081 |
| 3,000 m | 20,566 | 1,500 | 3,150 | 900 | 26,116 |


## Progression pacing (target)
| Stage | Typical run | Coins / run | Goals |
|---|---|---|---|
| First session | 300–700 m (starter) | 800–2,000 | First upgrades, first common car (4k–9k), complete Green Hills |
| Day 1–3 | 700–1,500 m | 2,000–7,000 | Starter maxed (~21k), Countryside, Desert, first rare car (32k–98k) |
| Week 1–2 | 1,500–2,500 m, maps 3–5 | 7,000–25,000 | Epic cars (140k–450k), Forest/City/Snow |
| Long term | 3,000–5,000 m, maps 6–8 | 25,000–160,000 | Legendary cars (650k–2M), full collection (61), all maps |

Numbers come from the real terrain generator (`tools/dev/coin_curve.gd`) and the bot fleet runs (`tools/dev/fleet_sim.gd`): with no upgrades a bot averages 630–800 m per 45 s across maps; with full upgrades 820–1,030 m, so upgrades are clearly worth buying.

## Tuning knobs
All in `data/economy.json`, `data/vehicles.json` (`price`, `upgrades.cost_base`, `upgrades.max`), `data/environments.json` (`coin_tiers`, `reward_mult`, `pickups`, `unlock_cost`, `complete_reward`), `src/core/upgrade_rules.gd` (cost curve), `src/core/k.gd` (per-level upgrade effects). Regenerate tables with `python3 tools/build_docs_tables.py`.
