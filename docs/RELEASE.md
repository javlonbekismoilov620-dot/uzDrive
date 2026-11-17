# Release & Store Preparation

> **Status:** the project is build-ready but **not published**. Nothing has been submitted to Google Play or the App Store. Publication happens only after the steps below are completed by the account owner and the stores approve the app.

## App identity
| Item | Value |
|---|---|
| Application name | UZ Drive: Hill Adventure (launcher label: "UZ Drive") |
| Application / bundle id | `uz.uzdrive.hilladventure` (change in `export_presets.cfg` before the first upload if you own a different domain — it cannot be changed after publishing) |
| Version | `1.0.0` (build 1) |
| Category | Games → Racing |
| Orientation | Landscape (sensor) |
| Min OS | Android 7.0+ (Godot 4.7 default min SDK 24), iOS 14+ |
| Permissions | Android: `VIBRATE` only (haptics; can be disabled in Settings). No internet, no storage, no location, no camera/mic. iOS: none. |
| Icon / splash | `assets/branding/` (icon_1024/512/192, adaptive foreground/background/monochrome 432, splash) |

## Version management
```
python3 tools/bump_version.py 1.0.1          # name 1.0.1, build code +1
python3 tools/bump_version.py 1.1.0 --code 10
```
Updates `project.godot` and both store presets together. Always increase the build code for every store upload.

## Before every release
```
python3 tools/build_vehicles.py && python3 tools/build_environments.py && python3 tools/build_i18n.py   # only if tables changed
godot --headless --path . --import
godot --headless --path . -s tools/dev/build_theme.gd
godot --headless --path . -s tools/dev/check_scripts.gd
godot --headless --fixed-fps 60 --path . -s tests/run_tests.gd        # must print 0 failures
godot --headless --fixed-fps 60 --path . -s tools/dev/fleet_sim.gd -- green_hills 40 0   # physics QA (repeat per map)
```

## Android (Google Play)
1. Install **Godot 4.7.2** + export templates (Editor → Manage Export Templates), **JDK 17**, **Android SDK** (platform-tools, build-tools 35+, platform android-35 or the level Google Play currently requires). Set paths in *Editor Settings → Export → Android*.
2. *Project → Install Android Build Template* (the preset uses Gradle builds and exports an **AAB**).
3. Create an upload keystore (keep it safe and **never commit it**):
   ```
   keytool -genkey -v -keystore uzdrive-upload.keystore -alias uzdrive -keyalg RSA -keysize 2048 -validity 10000
   ```
   Provide it via environment variables (CI-friendly) or in `export_credentials.cfg` (git-ignored):
   `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`.
4. Build: `godot --headless --path . --export-release "Android" build/android/UZDrive.aab`
   (for a sideload test APK switch *gradle_build/export_format* to APK or use `--export-debug`).
5. Test on at least: one low-end device (2–3 GB RAM, Mali/Adreno 5xx), one mid-range, one tall 20:9 phone with a notch, one tablet. Checklist: 60 FPS on Green Hills & Night Highway, multitouch (gas + boost + brake together), back button (pause in-game, close dialogs, quit confirm on main menu), app switch / kill during a run (run is paid on relaunch), language switch, rotation 180°.
6. Play Console: create app → Internal testing track → upload AAB → enable **Play App Signing**.
   * **Data safety:** "No data collected", "No data shared".
   * **Content rating (IARC):** no violence/gambling/user interaction → expected *Everyone / PEGI 3*.
   * **Ads:** "No ads". **Target audience:** 13+ recommended (avoids Families-policy requirements; the content itself is suitable for all ages).
   * **Privacy policy URL:** host `docs/PRIVACY_POLICY.md` (e.g. GitHub Pages) and paste the URL.
   * Store listing texts: `docs/STORE_LISTING.md`; screenshots: see below; feature graphic 1024×500: `assets/branding/feature_graphic.png`.
7. Internal → Closed testing → Production rollout (staged 10 % → 100 %).

## iOS (App Store)
1. macOS with Xcode (current version required by App Store Connect), Apple Developer Program membership, Godot 4.7.2 + templates.
2. In `export_presets.cfg` (or the editor) set *App Store Team ID*; keep the bundle id `uz.uzdrive.hilladventure` registered in the Apple Developer portal.
3. `godot --headless --path . --export-release "iOS" build/ios/UZDrive.ipa` (or export the Xcode project and archive in Xcode → Organizer → Distribute → App Store Connect).
4. Test on iPhone with notch / Dynamic Island (safe areas), an older iPhone (A12 class) and an iPad; verify ProMotion devices stay at 60 FPS cap.
5. App Store Connect: new app → upload via Xcode/Transporter → TestFlight → submit for review.
   * **App Privacy:** "Data Not Collected".
   * **Age rating:** 4+.
   * **Export compliance:** no encryption beyond Apple's OS (answer "No").
   * Screenshots: 6.7"/6.9" iPhone (2796×1290 / 2868×1320 landscape) and 13" iPad (2752×2064) are mandatory sizes; 6.5" (2688×1242) is accepted for older slots.

## Screenshots
`tools/dev/screenshot_tour.gd` captures real in-game screens at any resolution:
```
xvfb-run -a -s "-screen 0 2688x1242x24" godot --path . --rendering-driver opengl3 \
  -s tools/dev/screenshot_tour.gd -- out_dir uz "main_menu,garage,shop,maps,game:green_hills:sarbon_mitti" 2688 1242
```
(arguments: output folder, language, comma-separated steps, width, height). Produce one set per store language (uz, ru, en). `store/screenshots/` in this repository contains a first set at 1920×1080.

## Pre-submission checklist
- [ ] Unique, owned application id; signing keys stored safely (not in git)
- [ ] `tests/run_tests.gd` → 0 failures; fleet QA has no "BROKEN" rows
- [ ] Tested on real low-end Android + iPhone + tablet
- [ ] Privacy policy hosted, URL entered in both consoles
- [ ] Store texts in uz / ru / en, screenshots per language
- [ ] Content rating questionnaires done; data-safety/app-privacy = no data collected
- [ ] Version bumped with `tools/bump_version.py`
- [ ] Legal review of vehicle names/designs (original fictional names; no manufacturer logos; `inspired_by` never displayed)
