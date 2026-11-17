# UZ Drive: Hill Adventure — Technical Architecture

## 1. Technology choice

| Decision | Choice | Why |
|---|---|---|
| Engine | **Godot 4.7.2** (latest stable at time of writing) | Free/MIT, first-class 2D physics and UI, one codebase for Android + iOS, tiny runtime. |
| Language | **GDScript** (typed where it matters) | Fast iteration, no native toolchain needed for gameplay code. |
| Renderer | **GL Compatibility** (OpenGL ES 3 / WebGL2 class) | Widest Android device coverage, lowest memory, fully sufficient for vector 2D. |
| Physics | Godot Physics 2D, 60 Hz, 16 solver iterations | Deterministic enough for QA bots; custom suspension model on top. |
| Orientation | Landscape (sensor) only | A side-scrolling driving game needs horizontal view; two-thumb pedals. Portrait was evaluated and rejected as inappropriate for this genre. |
| Resolution | 1280×720 base, `canvas_items` stretch, `expand` aspect | Pixel-independent UI that adds horizontal space on 19.5:9 / 20:9 phones and tablets; safe-area margins for notches. |

## 2. Repository layout

```
project.godot / export_presets.cfg     Godot project + Android/iOS/Linux export presets
assets/  fonts (OFL), icons (SVG, generated), audio (generated), textures (generated),
         branding (icon/splash, generated), ui/theme.tres (generated design system)
data/    vehicles.json, environments.json, economy.json, missions.json,
         achievements.json, i18n/{uz,ru,en}.json      ← all content & tuning
src/autoload/   global services (see §3)
src/core/       pure logic: constants, utilities, VehicleSpec, UpgradeRules
src/gameplay/   GameScreen (run rules), vehicle/ (physics + art), world/ (terrain,
                backdrop, pickups, props), hud/ (HUD, pedals, pause, results)
src/ui/         widgets/ (design-system components), screens/ (menus)
src/main/       main.tscn + router
tests/          headless automated test-suite (42 tests)
tools/          content generators (vehicles, maps, i18n, audio, art), dev/QA bots
docs/           this documentation
```

## 3. Runtime services (autoloads)

| Autoload | Responsibility |
|---|---|
| `Events` | Global signal bus. Systems never hold references to each other. |
| `DB` | Loads and validates every JSON data file; read-only lookups. Display names respect the licensing block. |
| `Save` | Crash-safe persistence (atomic write, checksum, backup, temp-file recovery, debounced auto-save, flush on pause/close) + cloud snapshot export/validation. |
| `Profile` | The save payload (wallet, garage, maps, stats, missions, settings). Schema migration + integrity repair. |
| `Loc` | Localisation: registers uz/ru/en tables with `TranslationServer`, `Loc.t(key, args)`, locale-aware number formatting. |
| `Economy` | The only code that moves currency. Validates prices, prevents negatives and double-purchases, idempotent reward claims, run payouts, daily login, gem exchange, map unlocks. |
| `Progress` | Daily missions (seeded per date, tiered by player progress), lifetime statistics, tiered achievements. Fed only by `Events.stat`. |
| `Audio` | Buses (Master → Music, Master → SFX → Engine), cross-faded music, pooled SFX, looping engine samples, haptics. |
| `Services` | Ads / cosmetic store / cloud save / leaderboards provider interfaces. Shipped as *null* providers that report "unavailable" (no fake buttons). |
| `UI` | Design tokens, fonts, theme builder, icons, transitions, toasts, modal dialogs, safe-area helper. |

Screens are created by the router in `src/main/main.gd` (`UI.go("garage")`) with a fade transition; every screen is a script so it can be built and tested headlessly.

## 4. Gameplay

### 4.1 Vehicle physics (`src/gameplay/vehicle/vehicle.gd`)
* Chassis = `RigidBody2D` with custom centre of mass (from data: `com_h`, `front_bias`), convex collider with ~38° approach/departure chamfers, continuous collision detection.
* **Shape-cast suspension:** each wheel sweeps a circle (the tyre) along the suspension axis. The sweep starts above the mount because Godot ignores shapes a cast starts inside — this keeps contact detection working at full compression. Spring stiffness is derived from sprung mass so every car sits at ~45 % sag; damping ratio comes from the suspension stat.
* **Traction:** drive/brake force at the contact patch, clamped to `grip × surface_grip × normal_load`. Because forces act below the centre of mass, acceleration pitches the nose up naturally (wheelies), braking dips it. FWD / RWD / AWD distribute torque to the driven wheels in contact.
* **Engine:** power-to-weight → peak acceleration; torque curve fades toward top speed; 5-gear RPM model for HUD and audio pitch.
* **Air control:** gas = lean back, brake = lean forward (also usable on the ground while balancing on one axle). Flip counting, air time, landing impact.
* **Crash rules:** roof sensor (`Area2D`) touching terrain, or resting upside-down > 1.2 s.
* **Upgrades** change `VehicleSpec` values that the physics reads directly (engine → acceleration/top speed, suspension → damping/travel/landing stability, tyres → grip, fuel → tank time). The garage shows the same `VehicleSpec` numbers.

### 4.2 Terrain (`src/gameplay/world/`)
* `TerrainGenerator` (pure logic, fully tested): append-only height profile sampled every 0.5 m, seeded per map → every map is learnable and identical each run. Segment grammar: hills, flat, bumps, jumps (filleted kicker + rounded crest), bridges (with optional water), trenches, climbs, valleys, steps, dunes. Difficulty (amplitude, slope limit, feature frequency) rises with distance; the first ~220 m are a gentle warm-up. Surface patches (mud, ice, deep sand, wet asphalt, gravel) change grip and rolling resistance.
* Pickups are placed by the generator: coin groups with value tiers by distance (5…500), fuel cans with spacing that grows with distance (the core tension), gems, boost canisters, checkpoints every 500 m.
* `TerrainManager` streams 64 m `TerrainChunk`s (collision segments, textured ground polygon, surface bands, lane markings, props, rollable obstacles, bridges, ramps, checkpoint flags) around the camera and frees old ones.
* `Backdrop`: gradient sky, sun/moon/stars, drifting clouds, three `Parallax2D` scenery layers per map (mountains, hills, dunes, mesas, city skylines, rocks, fields), weather particles (snow, dust, leaves). Night map uses `CanvasModulate` + `PointLight2D` headlights; pickups live on a separate canvas layer so they stay visible at night.
* `PickupLayer` collects pickups with distance checks in vehicle space (no per-coin nodes), with a coin magnet.

### 4.3 Run rules (`GameScreen`)
Fuel burn (idle 22 % + throttle, ×1.5 while boosting), boost energy/cooldown, wheelie/flip/air tricks (paid only after a safe landing), checkpoints, map goal (unlocks next map + one-time reward), out-of-fuel and crash endings, gem revive (5/10/20), pause, tutorial. Rewards are computed by `Economy.compute_run_payout` and committed **once** with a unique run id. A running run is snapshotted into the save (`pending_run`) on pause/backgrounding/checkpoints, so if the OS kills the app the run is paid on next launch.

## 5. UI system
* `UI.build_theme()` defines the whole design system in code (colour tokens, Exo 2 / Nunito variable fonts, button variants, cards, dialogs, sliders, scroll bars). `tools/dev/build_theme.gd` saves it to `assets/ui/theme.tres`, registered as the project theme, so every Control (including ones under CanvasLayers) is styled consistently.
* Reusable widgets: `UIButton` (variants, press animation, SFX), `UIDialog` (modal confirm), `CurrencyChip`, `StatBar` (with upgrade/compare preview), `VehicleCard`, `VehiclePreview` (showroom turntable, rev on tap), `UIToggle`, `Badge`, `MapThumb`, `Showcase` (live attract-mode scenery in the main menu).
* In-run controls use `TouchButton`, which tracks its own finger index so gas, brake and boost can be pressed simultaneously (standard GUI buttons only see the first touch).

## 6. Persistence
`user://save.json` = `{format, saved_at, checksum: sha256(payload), data}`.
Write: temp file → read back & verify → rotate current to `save.bak.json` → rename. Read order: main → temp → backup; any file failing the checksum is ignored. All numbers are JSON-normalised before hashing, and written with full precision (large coin balances never lose precision). Schema `version` + `Profile.migrate()` (deep merge with defaults) + `ensure_integrity()` (clamps balances/levels, removes unknown cars, guarantees the starter car).

**Cloud-ready:** `Save.export_snapshot()` / `validate_snapshot()` produce/verify a self-checking envelope; `Services.resolve_conflict()` picks the more progressed save. A real `CloudSaveProvider` (Play Games Saved Games / iCloud / Game Center) only needs to upload/download envelopes.

## 7. Localisation
`tools/build_i18n.py` is the single source (one table, three languages, placeholder parity enforced) → `data/i18n/*.json` (UTF-8). Uzbek Latin uses U+02BB (ʻ) and U+02BC (ʼ); bundled fonts cover Latin Extended, Cyrillic and these letters. Language can be switched any time in Settings; screens rebuild text on `Events.language_changed`. Tests verify completeness, placeholders, orthography, no Cyrillic in Uzbek, no stray Latin in Russian, and that every key referenced in code/data exists.

## 8. Licensing structure for vehicles
Every vehicle uses an **original** name, maker and procedurally generated artwork. `inspired_by` is an internal design note and is never rendered. Each entry has:
```json
"license": {"licensed": false, "brand": "", "model": "", "logo": ""}
```
If official licensing is obtained, set `licensed: true` and fill brand/model (and a logo asset path): `DB.vehicle_display_name()` / `vehicle_maker()` switch automatically, no code change. A test fails if any real manufacturer name appears in displayed names while unlicensed.

## 9. Monetisation readiness (not active)
`Services.ads` (rewarded ads), `Services.store` (cosmetic-only products), `Services.cloud`, `Services.leaderboards` are interfaces with null implementations. UI checks `is_available()` before showing anything, so no non-functional buttons exist. Design rules baked in: no loot boxes or gambling, no real-money requirement for progression, gems are earned only by playing. Seasonal challenges: `data/missions.json → seasonal` (schema slot, empty).

## 10. Performance notes
* No per-coin nodes; chunk streaming keeps ~5 chunks alive; props are drawn once per chunk (cached canvas commands).
* CPU particles only (portable). "Low" graphics quality disables weather/clouds.
* Generated audio is small (engine loops 1 s, SFX < 1 s, music OGG ~1 MB total).
* GL Compatibility renderer, ETC2/ASTC texture import enabled for mobile.

## 11. Tooling
| Tool | Purpose |
|---|---|
| `tools/build_vehicles.py`, `build_environments.py`, `build_i18n.py` | Regenerate data JSON from readable tables |
| `tools/build_audio.py`, `build_textures.py`, `build_icons.py` | Generate original audio, textures, branding, icons |
| `tools/dev/build_theme.gd` | Save the design-system theme |
| `tools/dev/fleet_sim.gd` | Bot-drive every vehicle on a map; reports distance, stalls, crashes, physics anomalies |
| `tools/dev/drive_sim.gd`, `shape_gallery.gd`, `screenshot_tour.gd`, `coin_curve.gd` | Physics tracing, art gallery, screenshot capture, economy probe |
| `tools/dev/check_scripts.gd` | Compile every script |
| `tools/bump_version.py` | Version management across project + export presets |
| `tests/run_tests.gd` | Automated test-suite |
