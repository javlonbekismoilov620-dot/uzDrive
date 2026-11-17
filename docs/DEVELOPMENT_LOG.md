# Development log (phase reports)

## Phase 1 — Inspection & architecture ✅
* Repository was empty (README only) → new Godot 4 project as requested. Chose Godot **4.7.2** (latest stable), GDScript, GL Compatibility renderer, landscape-only, 1280×720 expand-aspect layout.
* Autoload service architecture, data-driven JSON content, headless tooling (script checker, screenshot capture under Xvfb).
* Fonts chosen after glyph-coverage checks: Exo 2 + Nunito (OFL) — full Latin Extended, Cyrillic and Uzbek ʻ/ʼ.

## Phase 2 — Driving physics ✅
* Rigid-body chassis + shape-cast suspension, traction model, engine/gears, brakes/reverse, air control, flips, landing, crash sensor.
* Headless drive simulator + fleet bot → found and fixed: lost wheel contact at full compression, bumper snagging (approach angles), FWD traction collapse, kart suspension.

## Phase 3 — Vehicles ✅
* 61 vehicles (25 GM-inspired "Road Legends") generated from `tools/build_vehicles.py` → `data/vehicles.json`; original names/makers; `inspired_by` internal only; `license` block for future licensed branding.
* Parametric procedural artwork (archetype silhouettes, glass, pillars, lights, trims, stripes, two-tone, accessories, rims/tyres, driver) shared by gameplay and menus.

## Phase 4 — Garage, shop, upgrades ✅
* Garage with live preview, stat bars, four upgrade rows (current → next values, two-tap confirm).
* Dealership with category filters, sorting, comparison against the equipped car, modal purchase confirmation, gem exchange tab.

## Phase 5 — Coins, fuel, economy ✅
* Economy service (validation, idempotent rewards, run payouts, daily login, map unlocks), fuel & boost systems, coin tiers 5–500, distance/checkpoint/trick bonuses. Balancing documented in ECONOMY.md with numbers from the real generator.

## Phase 6 — Maps ✅
* 8 environments from `tools/build_environments.py`; deterministic streaming terrain generator with feature grammar and difficulty curve; parallax art, weather, night lighting, surfaces, rollable obstacles, bridges, ramps, checkpoints.

## Phase 7 — UI & localisation ✅
* Design system (tokens, theme saved as project theme), widgets, router with transitions, HUD (multi-touch pedals/boost/pause), pause and results overlays, all menus.
* 237 strings × 3 languages from a single source table with automated checks.

## Phase 8 — Missions & progression ✅
* Daily missions (seeded, tiered, bonus), 15 tiered achievements, lifetime stats, daily login, save system with crash recovery.

## Phase 9 — Audio & polish ✅
* Generated engine loops (12 profiles), 22 SFX, 3 music tracks; particles (dust, exhaust, boost flame, bursts), camera look-ahead/zoom/shake, trick pop-ups, banners, tutorial with arrows, animated buttons, count-up currencies, turntable previews, live menu scenery.

## Phase 10 — QA & release prep ✅ (device testing pending)
* 45 automated tests; fleet QA over 61 cars × 8 maps; rendered screenshot review of every screen in 3 languages; Linux release export verified.
* Export presets (Android AAB, iOS, Linux QA), icons/adaptive icons/splash/feature graphic, version tool, store texts, privacy policy, release guide.

## Remaining before store submission
1. Test on real Android/iOS devices (performance, touch, safe areas, audio).
2. Create signing keys / Apple team, build AAB and IPA (RELEASE.md).
3. Host the privacy policy, fill Play Console / App Store Connect forms, upload screenshots per language.
4. Optional next features prepared in the architecture: cloud saves, rewarded ads (opt-in, never required), cosmetic paints, leaderboards, seasonal challenges, more maps/vehicles (pure data additions).
