# QA Report — build 1.0.0 (1)

Environment: Godot 4.7.2 (official), Linux x86_64 container, headless + Xvfb/Mesa llvmpipe for rendering checks. **Not yet tested on physical Android/iOS devices** (see "Open items").

## 1. Automated test-suite — `tests/run_tests.gd`
`godot --headless --fixed-fps 60 --path . -s tests/run_tests.gd` → **45 tests, ~10,970 checks, 0 failures.**

| File | Covers |
|---|---|
| `test_data` | ≥50 vehicles (61), all categories & rarities, GM-inspired category largest, no real brand names displayed, licensing block, price ladder by rarity, art/physics geometry builds for every car, every design unique, 8 maps & unlock chain |
| `test_economy` | no negative balances, no overspend, buy/duplicate/invalid purchases, gem-priced car, upgrade cost growth & max level, idempotent rewards, run payout formula, pay-once runs, harder maps pay more, daily login streak/reset/clock-rollback, map unlock/complete rewards once, gem exchange |
| `test_save` | round-trip incl. 7-digit balances, tampered & truncated files rejected → backup used, interrupted write recovered from temp file, schema migration & integrity repair, cloud snapshot validation & conflict resolution |
| `test_localization` | identical key sets uz/ru/en, no empty strings, placeholder parity, Uzbek ʻ/ʼ orthography, no Cyrillic in Uzbek, no stray Latin in Russian, every key referenced by code & data exists, language switching & number formatting |
| `test_progression` | deterministic daily missions per date, tiers, progress (add/max), claim once, achievements tiers & claims, derived metrics |
| `test_physics` | upgrades raise acceleration/top speed/damping/travel/grip/fuel time; car drives forward; maxed engine is measurably faster; engine+tyres climb a 27° slope much further; AWD out-climbs FWD on a slippery slope; landing on the roof triggers a crash; an air backflip is counted on landing |
| `test_terrain` | deterministic generation for all 8 maps, slope limits, gentle warm-up, fuel-can spacing, valid coin values, bounded obstacles, all 7 coin values appear within 4.6 km |
| `test_gameplay` | full run: driving, fuel use, out-of-fuel ending, results, payout exactly once, pending-run snapshot cleared, stats recorded, best distance saved; crash + gem revive (and refusal without gems); pause/resume; pickups & boost rules; crash-recovery payout of an interrupted run (once); **multi-touch** (gas held while boost and brake are pressed by other fingers) |
| `test_ui` | all 8 menu screens build in uz/ru/en without raw keys or unformatted placeholders; tapping *Buy* alone never purchases (confirmation required) |

## 2. Physics fleet QA — `tools/dev/fleet_sim.gd`
A bot (full throttle, simple air balancing, no momentum tactics) drives every vehicle for 45 s.

| Map | Upgrades | Vehicles | Broken (NaN / fell through) | Stalled | Avg distance |
|---|---|---:|---:|---:|---:|
| Green Hills | none | 61 | 0 | 0 | 795 m |
| Countryside | none | 61 | 0 | 0 | 722 m |
| Desert Road | none | 61 | 0 | 0 | 695 m |
| Forest Adventure | none | 61 | 0 | 0 | 715 m |
| City Roads | none | 61 | 0 | 1 | 771 m |
| Snow Mountains | none | 61 | 0 | 0 | 741 m |
| Rocky Mountains | none | 61 | 0 | 0 | 632 m |
| Night Highway | none | 61 | 0 | 0 | 758 m |
| Desert Road | max | 61 | 0 | 0 | 843 m |
| Snow Mountains | max | 61 | 0 | 0 | 933 m |
| Rocky Mountains | max | 61 | 0 | 0 | 816 m |
| Night Highway | max | 61 | 0 | 1 | 1,029 m |

Bugs found and fixed through this process: wheel contact lost at full suspension compression (Godot `cast_motion` ignores start overlaps), bumpers snagging ramps (added approach/departure angles), wall-like obstacles (now rollable mounds), V-trenches bridging long cars (widened), cars high-centring on sharp ramp crests (rounded), FWD traction collapse from lean torque (now only while balancing), kart suspension too short.

## 3. Visual / UX verification (rendered screenshots)
Every screen captured at 1280×720 and 1920×1080 in all three languages (`store/screenshots/`): language picker, main menu (live scenery), daily reward, map select, garage, upgrades, dealership, gem exchange, missions, achievements, settings, gameplay on all 8 maps (incl. night lighting), tricks pop-ups, pause, results with revive. Issues found and fixed: theme not applied under CanvasLayers (now project theme), dialogs not full-screen (anchors), menu showcase framing, parallax too high (sky hidden), coin icons tinted on gold buttons, shop panel overflow, map cards clipped, glyphs missing from fonts (✓ ★ ↑ ↓ removed), night map too dark, missing lane markings, dialogs persisting across screens.

## 4. Export & packaging
* Linux QA export built from `export_presets.cfg` with official 4.7.2 templates; the exported release binary boots into a fully working main menu (data JSON, i18n, fonts, theme, icons, audio, art all packaged). Android/iOS presets are configured (ids, icons, adaptive icons, splash, permissions, version); building them requires the Android SDK/JDK and macOS/Xcode respectively (not available in this environment, see RELEASE.md).

## 5. Performance (CPU, headless, x86_64 server core)
`tools/dev/perf_probe.gd`: physics + game logic **0.60–0.75 ms per frame** on average; worst frame ~6 ms when a new 64 m terrain chunk is generated (roughly every 3–5 s while driving). ~180–215 nodes alive during a run. Expect 3–5× slower CPUs on mid-range phones (≈3 ms average) — comfortably inside a 16.7 ms frame; the chunk spike is the main optimisation candidate (spread chunk building over two frames).

## 6. Open items (honest status)
* **Physical device testing** (Android low/mid/high-end, iPhone, iPad) for frame rate, touch feel, safe areas, audio latency and haptics — not possible in this environment.
* Android AAB / iOS IPA builds require the Android SDK + keystore and macOS + Xcode + Apple account.
* Audio was verified by generation/inspection only (no audio device here); a listening pass on devices is recommended.
* Store submission and approval have **not** happened.
