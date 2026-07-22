# AGENTS.md

Compact instructions for agent sessions working on the RupaGodot game. Collects the high‑signal facts an agent is most likely to miss.

## What this is

**RupaGodot** is the [Godot 4.6](https://godotengine.org/) / GDScript port of the libGDX game **Rupa** ("circles and holes" — package `com.circlesandholes.game`). Gameplay: tilt a board left/right to roll a ball up the screen past holes to the top. Falling into a hole or off the bottom = fail; reaching the top = win. Levels are data‑driven (JSON); art is generated at runtime. This port is intended to **replace** the original libGDX version (same package, same Play Store listing). The original libGDX project lives in the sibling repo `../Rupa`.

## Build & Run

- Engine: **Godot 4.6** (developed against 4.6.3 stable). Open the project in the editor to run/debug, or use the CLI binary.
- **Desktop dev:** run `scenes/menu.tscn` from the editor (480×640 portrait).
- **GUT tests (headless):**
  ```sh
  /Applications/Godot.app/Contents/MacOS/Godot --headless --import   # fresh checkout only
  /Applications/Godot.app/Contents/MacOS/Godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit -glog=2
  ```
  Autoloads (e.g. `Game`) are **not registered** in GUT `--script` mode, so tests cover pure logic/formulas only — not scenes or `Game.build_level_theme`.
- **Android export (CLI):**
  ```sh
  /Applications/Godot.app/Contents/MacOS/Godot --path . --export-debug "Android" build/Rupa-debug.apk
  ```
  Requires Android export templates (`4.6.3.stable`) and an Android SDK + build‑tools (Godot calls `apksigner` to sign). The debug keystore path is configured in the "Android" export preset.
- **Run on emulator:**
  ```sh
  adb -s emulator-5554 uninstall com.circlesandholes.game && adb -s emulator-5554 install build/Rupa-debug.apk
  adb -s emulator-5554 shell monkey -p com.circlesandholes.game -c android.intent.category.LAUNCHER 1
  ```
  **Uninstall first** — an existing install with a different debug signature fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.

## CRITICAL — Android black‑screen + missing strings

These two are easy to break and silent; both are already fixed in‑repo, do not revert:

- **Renderer:** Godot resolves the renderer **per platform**. `project.godot` sets BOTH
  `renderer/rendering_method="gl_compatibility"` (desktop) **and** `renderer/rendering_method.mobile="gl_compatibility"`.
  Without the `.mobile` override, Android uses the default **mobile/Vulkan** renderer, which fails `QueuePresentKHR` on most emulators → solid black screen (process alive, no crash). Keep the `.mobile` line.
- **i18n export:** Translations are Java `.properties` files (`assets/strings.properties` = Russian default, `assets/strings_en.properties` = English). Godot does **not** export `.properties` by default, so the Android preset has `include_filter="*.properties"`. Without it, `_strings` is empty and the UI shows raw keys. Keep the filter.

## Project Structure

- `project.godot` — Godot 4.6 config. Autoload `Game="*res://scripts/game.gd"`. Renderer `gl_compatibility` (both default + mobile). Main scene `scenes/menu.tscn`, 480×640 portrait.
- `scripts/` — GDScript sources:
  - `game.gd` — **autoload `Game`**: central mutable state holder (the port of libGDX `Intro`). Owns world size, tuning, per‑run flags (`failed`, `win`, `the_end`, `paused`, `consume_touch`, `box_din`, `box_hole_din_sign`), procedural theme generation (`build_level_theme`), and scene routing (`go_to_level`, `show_menu`, `show_level_select`, `show_result`). Note the deliberate field‑name spellings `failed`/`box_din`/`box_hole_din_sign` (parity with the original's public API, which had `faild`/`box_din`).
  - `i18n.gd` — **`class_name I18N`** (not an autoload). `init()` loads the default `.properties` then the locale override (`strings_en.properties` when `OS.get_locale_language() != "ru"`). `get_s(key)` falls back to the key; `fmt(key, arg)` substitutes `{0}`.
  - `level_data.gd` / `level_loader.gd` — a level is `assets/levels/levelN.json`, parsed with `JSON`. `LevelLoader.count()` walks contiguous files (currently 10).
  - `procedural_assets.gd` — **`ProceduralAssets`**: generates all art at runtime (ball, hole, gradient backgrounds, board, pause icon) via `Image`/`ImageTexture`.
  - `progress.gd` — persistence over Godot `ConfigFile`/`FileAccess` (best time per level, completion).
  - `prefs.gd` — `PlayerPrefs` simple key/value store.
  - `menu_screen.gd`, `level_select_screen.gd`, `level_screen.gd`, `result_screen.gd` — the four screens.
- `scenes/` — `menu.tscn`, `level_select.tscn`, `level.tscn`, `result.tscn` (generic, data‑driven; no per‑level scene).
- `assets/` — `levels/level*.json` (data), `fonts/10771.ttf` (FreeType), `Menu/` + `Gestures/` (sprites), `strings*.properties` (i18n), `icon.png` (app icon).
- `tests/` — GUT unit tests; see `tests/README.md`.
- `addons/gut/` — vendored GUT 9.6.0 test framework (committed; needed by CI).
- `android/build/` — Godot Android Gradle template (**gitignored**; regenerated by "Install Android Build Template"). Not used for the standard export (`gradle_build/use_gradle_build=false`).

## Architecture

Four `Screen`s coordinated through one global state holder (`Game`), with **data‑driven levels** and **procedurally generated art** — a direct structural port of the libGDX original.

- **`Game` (autoload)** — entry point and state container. `_ready()` runs `I18N.init()`, computes world size/tuning, generates base textures, loads the font. Scene routing goes through `go_to_level(level)` (resets per‑run state, builds theme, changes to `level.tscn`), `show_menu()`, `show_level_select()`, `show_result(level)`.
- **`level.tscn` / `level_screen.gd`** — the single generic level screen: builds static holes / oscillating holes / barriers / rotating platforms from `LevelData`, runs tilt physics + win/fail + pause overlay.
- **`LevelLoader` / `LevelData`** — `assets/levels/levelN.json` (contiguous, 1‑based). JSON parsed without reflection. `count()` auto‑detects the level count.
- **`ProceduralAssets`** — runtime art via `Image`/`Pixmap`‑equivalents; `Game.build_level_theme(level)` derives a per‑level hue (HSV from the level number) for background + board.
- **`I18N`** — custom translation (not Godot's built‑in `tr()`/Translation system); `.properties`‑based, loaded via `FileAccess`.
- **`Progress`** — best time per level + completion, persisted to `user://`.

## Code Conventions

- **Global mutable state via the `Game` autoload** — screens read/write `Game.*` fields, not DI.
- **Resolution independence is formula‑based** — sizes/tuning computed from world width, calibrated so a ~1080px‑wide screen matches the original art.
- **Renderer is `gl_compatibility`** on every platform (see CRITICAL above) — this is a 2D game; do not switch to `mobile`/`forward_plus`.
- **i18n is custom** — add strings to both `.properties` files; reference via `I18N.get_s("key")` / `I18N.fmt("key", arg)`.
- **Don't add comments** unless asked; terse `#` lines where context is needed.

## Assets

- Most art is generated at runtime by `ProceduralAssets`. Hand‑authored assets that ship: `fonts/10771.ttf` (the FreeType font), `Menu/` and `Gestures/` sprites, `levels/level*.json`, `strings*.properties`.
- `assets/icon.png` is the app icon (copied from the original Rupa project's Android launcher icon); wired into `project.godot` `config/icon` and the Android preset `launcher_icons/main_192x192`.

## Android Notes

- Export preset "Android": package `com.circlesandholes.game`, name "Rupa", `arm64-v8a` only, `use_gradle_build=false` (standard Godot export, not Gradle). Debug keystore configured; release signing is done in CI by re‑signing the exported APK with `apksigner`.
- **`gradle_build/target_sdk="36"`** (Android 16) — Google Play requires API 36 for app updates from 2026-08-31. Godot 4.6.3 templates also default to 36; keep the explicit preset so AAB/Gradle builds cannot silently fall back. CI installs `platforms;android-36`.
- `include_filter="*.properties"` must stay (see CRITICAL).
- The app **icon** is set via `launcher_icons/main_192x192`; Godot generates all densities + adaptive icons from it.

## CI/CD

`.github/workflows/android.yml` mirrors the Rupa pipeline: on push to `master` + PRs; `build` job runs GUT tests (gate) → computes version → exports the APK via the Godot CLI → re‑signs with the release keystore on `master` (debug fallback on PRs) → uploads the artifact; `deploy` job uploads to Google Play internal track on `master`. Required repo secrets (same values as the Rupa repo): `SIGNING_KEYSTORE_BASE64`, `SIGNING_STORE_PASSWORD`, `SIGNING_KEY_ALIAS`, `SIGNING_KEY_PASSWORD`, `PLAY_SERVICE_ACCOUNT_JSON`. Dependabot keeps the GitHub Actions current.
