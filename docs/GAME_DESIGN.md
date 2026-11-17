# UZ Drive: Hill Adventure — Game Design

## Core loop
**Drive** as far as possible on a map → **collect** coins, fuel, gems, boost → run ends (out of fuel / crash) → **earn** payout (coins collected + distance bonus + checkpoint bonuses + trick bonuses) → **upgrade** or **buy** vehicles, **unlock** maps → drive further.

Easy to understand (two pedals), hard to master (momentum, balance in the air, fuel planning, choosing the right car per map).

## Controls (two thumbs, landscape)
| Control | Position | Action |
|---|---|---|
| Brake / reverse pedal | bottom-left | Slow down; reverse when stopped; in the air: tilt forward |
| Gas pedal | bottom-right | Accelerate; in the air: tilt back; while balancing on one axle: lean back |
| Boost | bottom-centre (right of tachometer) | 2.5 s burst (+45 % acceleration, +25 % top speed, ×1.5 fuel use) |
| Pause | top-right | Pause menu |
Keyboard (desktop/QA): →/D gas, ←/A brake, Space/Shift boost, Esc/P pause.

## HUD
Top-left: fuel/battery gauge (warning blink < 22 %), run coins, run gems. Top-centre: distance, progress bar (to the map goal, then to the next checkpoint), best and goal. Top-right: pause. Bottom-centre: tachometer with gear and km/h, boost button with energy ring and cooldown sweep. Trick pop-ups, checkpoint / map-complete banners, tutorial hints with pointing arrows.

## Vehicles — 61 total (`docs/VEHICLES.md`)
| Category | Count | Notes |
|---|---:|---|
| Road Legends (GM-inspired, primary) | 25 | Original designs inspired by GM / Chevrolet models popular in Uzbekistan (micro cars, sedans, vans, SUVs, pickups, muscle, sports) |
| Sports | 6 | Coupés, hot hatch, rally, track car |
| SUVs | 4 | Compact to expedition |
| Pickups | 4 | Farm pickup to 3-axle heavy duty |
| Off-road | 5 | 4x4, buggy, rally-raid, rock crawler, trophy truck |
| Classics | 5 | 1950s–70s |
| Special | 7 | Go-kart, tractor, city bus, ambulance, ice-cream van, monster truck, lunar rover (low gravity, gem-priced) |
| Premium (fictional) | 5 | Luxury GT/SUV, electric and combustion hypercars, concept |

Rarity: Common (16), Rare (16), Epic (17), Legendary (12). Each car has its own silhouette archetype + proportions, paint/two-tone/stripes, accessories (spoilers, wings, roof racks, light bars, snorkels, spare wheels, bull bars, cargo, beacons, fins, dish…), rim style and tyre type, engine sound profile and pitch, and individual stats: power, weight, top speed, fuel capacity (or battery), drivetrain, grip, suspension quality and travel, centre-of-mass height, weight distribution, air control, fuel efficiency and upgrade potential (max level 8/10/12/15).

## Upgrades (4 tracks per vehicle)
| Track | Per level | Physics effect |
|---|---|---|
| Engine | +6 % acceleration & horsepower, +4 % top speed | Faster launches, more climbing power |
| Suspension | +0.05 damping ratio, +2.5 % travel, + landing stabilisation | Fewer bounces, safer landings |
| Tires | +5 % grip | Better climbing and braking, less wheel spin, better on ice/mud |
| Fuel tank | +10 % capacity | Longer between fuel cans |
Costs grow geometrically so the last level costs ~12× the first; the garage shows current level, price, current value → next value, and the stat bars preview the change. Purchase requires a second tap ("Sure?") within 3 s.

## Fuel & boost
Full tank ≈ 46–70 s of full throttle (vehicle- and upgrade-dependent); idling burns 22 %. Fuel cans refill to 100 %; spacing starts at ~200 m and grows with distance (to ~420–520 m). Boost energy (0–100, start 50): +0.15/m driven, +30 per flip, +12 per big air/wheelie, +40 per boost canister; costs 50 per burst, then 3 s cooldown.

## Tricks
Flip (back/front) 150 coins, multi-flip 450 per extra rotation, Big air (≥1.4 s) 100, Huge air (≥2.4 s) 250, Wheelie (every 2 s) 75. Paid only if the landing is survived.

## Maps (8)
| # | Map | Goal | Character | Unlock |
|---|---|---:|---|---|
| 1 | Green Hills | 1,500 m | Rolling hills, logs, small rocks, mud patches | Free |
| 2 | Countryside | 2,000 m | Poplars, hay bales, bridges over streams, fields | Complete map 1 or 8,000 |
| 3 | Desert Road | 2,500 m | Dunes, deep-sand patches, long jumps, scarce fuel, dust storm | 25,000 |
| 4 | Forest Adventure | 2,500 m | Pines, roots, mud, steps, water bridges, falling leaves | 50,000 |
| 5 | City Roads | 3,000 m | Asphalt (high grip), metal ramps, speed bumps, pallets, skyline | 90,000 |
| 6 | Snow Mountains | 3,000 m | Snow (low grip), ice patches, climbs, snowfall | 150,000 |
| 7 | Rocky Mountains | 3,500 m | Steep rock, boulders, deep gorges, upward trend | 250,000 |
| 8 | Night Highway | 4,000 m | Darkness with headlights & street lights, ramps, wet asphalt | 400,000 |
Completing a map's goal (first time) pays a reward and unlocks the next map for free. Harder maps multiply distance/checkpoint payouts (×1.0 → ×2.3) and reach high-value coins sooner.

## Missions, achievements, login
* **Daily missions:** 3 per day from 12 templates (drive total, single-run distance without running out of fuel, coins, jumps, flips, air time, fuel cans, boosts, checkpoints, wheelie, runs, upgrades), difficulty tier from player progress; +5 gems for completing all three. Reset at local midnight.
* **Achievements:** 15 tiered (distance, best run, coins, vehicles owned incl. "own 5", Road Legends collection, engine level incl. "level 5", fully tuned cars, legendary cars, maps completed, flips, jumps, air time, fuel, runs, daily missions).
* **Daily login:** 7-day cycle (500 → 6,000 coins + 10 gems), streak resets after a missed day; protected against clock rollback.

## Tutorial
First run: Gas → Brake → Air control → Fuel → Boost, with arrows pointing at the controls; progresses on player actions.

## Settings
Language (Oʻzbekcha / Русский / English), sound on/off + volume, music on/off + volume, vibration, graphics quality, privacy policy, about/credits, reset progress (double confirmation).
