# CLAUDE.md

> **Canonical agent instructions live in [`AGENTS.md`](./AGENTS.md). Read it first.**
> This file is a thin pointer for Claude Code sessions. Detailed project facts (architecture, conventions, the Android renderer/`.properties` gotchas, level schema, CI secrets) are kept in `AGENTS.md` — keep it that way so there is a single source of truth. Do not duplicate that content here.

## What this is

**RupaGodot** — the [Godot 4.6](https://godotengine.org/) / GDScript port of the libGDX game **Rupa** ("circles and holes", package `com.circlesandholes.game`). Tilt a board to roll a ball up past holes; reach the top to win. Data‑driven levels (JSON), runtime‑generated art. Intended to **replace** the original libGDX project (`../Rupa`).

## Quick commands

- **Desktop dev:** open in Godot editor, run `scenes/menu.tscn`.
- **GUT tests (headless):** `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit -glog=2`
- **Android export:** `godot --path . --export-debug "Android" build/Rupa-debug.apk`
- **Install on emulator:** `adb uninstall com.circlesandholes.game && adb install build/Rupa-debug.apk`

## Don't break these (silent, already fixed in‑repo)

- `project.godot` must keep **`renderer/rendering_method.mobile="gl_compatibility"`** — without it Android uses Vulkan and the screen goes black on emulators.
- The Android export preset must keep **`include_filter="*.properties"`** — without it the i18n `.properties` files aren't exported and the UI shows raw keys.

For architecture, scripts/scenes, level schema, CI/CD secrets and everything else, see [`AGENTS.md`](./AGENTS.md).
