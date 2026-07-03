# Rupa — tests (GUT)

Тесты на [GUT 9.6.0](https://github.com/bitwes/Gut). Покрывают чистую логику и
два регрессионных бага, найденных при миграции libGDX→Godot.

## Запуск (headless)

```sh
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
cd /Users/artem/Documents/JavaProject/RupaGodot
"$GODOT" --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit -glog=2
```

Если GUT-классы ещё не импортированы (fresh checkout), сначала:
```sh
"$GODOT" --headless --import
```

## Что покрывается

| Файл | Что проверяет |
|---|---|
| `test_progress.gd` | `Progress.format_time` (int + float-coercion — JSON-float edge), `record_time`/`best_time` roundtrip |
| `test_level_loader.gd` | `count()==10`, парсинг всех уровней, hints/rotating-platforms |
| `test_procedural_assets.gd` | clamps (`diameter<2→2`, `pause_icon<4→4`), non-null |
| `test_i18n.gd` | `get_s` fallback, `fmt` подстановка |
| `test_hue.gd` | **F4 regression:** `Color.from_hsv(hue/360)` — правильный hue; `deg_to_rad(hue)` — ловушка |
| `test_physics_parity.gd` | **F2 regression:** `default_gravity × 1.3 ≈ 2 × (60×0.6)²` (оригинал шагает физику в 36× реального времени) |
| `test_probe.gd` | sanity: GUT подключён |

## Ограничения

- Автозагрузка `Game` **недоступна** в CLI-режиме GUT (`--script`-режим Godot не
  регистрирует автозагрузки). Поэтому `Game.build_level_theme` и сцены тут не
  тестируются — только чистая логика/формулы. Визуальные баги (F1 redraw) и
  «физический feel» (F2 ощущение) требуют живого playtest.
