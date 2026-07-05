# Store assets — Google Play (стиль A1)

Маркетинговые ассеты для листинга Google Play. Сгенерированы скриптом
`tools/generate_store_assets.py` (Pillow/numpy) — макеты экранов воссозданы по
реальным данным игры (`assets/levels/*.json`, `assets/strings*.properties`) и
палитре A1. Текст — английский (`strings_en.properties`).

Пересборка одной командой:

```bash
python3 tools/generate_store_assets.py
```

## Файлы

| Файл | Размер | Куда грузить в Play Console |
|---|---|---|
| `play_icon_512.png` | 512×512 | Store listing → App icon |
| `feature_graphic_1024x500.png` | 1024×500 | Store listing → Feature graphic |
| `screenshots/*.png` | 1080×1920 (9:16) | Store listing → Phone screenshots — **в репозитории их нет** (делаете сами) |

## Состав 8 скриншотов

1. `01_menu` — главное меню (Rupa, Play, Levels/Exit)
2. `02_level_select` — выбор уровня (Select Level, сетка 1-10)
3. `03_gameplay_l1` — геймплей уровня 1 (тёплая тема, отверстия + шар + руки)
4. `04_gameplay_l2` — геймплей уровня 2 (тёплая оранжевая тема)
5. `05_victory_l1` — победа (Victory! + время + рекорд)
6. `06_pause_l1` — пауза (Pause / Continue / Restart / Levels / Menu)
7. `07_gameplay_l6` — геймплей уровня 6 (синяя тема + барьеры)
8. `08_victory_l6` — победа уровня 6 (синяя тема)

## Замечания

- **Скриншоты (`screenshots/`) в репозиторий не коммитятся** — их делает автор
  (напр. живые кадры из Godot). Скрипт `generate_store_assets.py` может
  сгенерировать программные макеты локально как референс.
- Это **программные макеты**, а не живые кадры: точно представляют экраны игры,
  но не являются снимками реального рантайма. При желании получить живые кадры —
  запустите проект в Godot (`/Applications/Godot.app`) и снимите экраны.
- Палитра/композиция иконки общая с `assets/icon.svg` (вариант A1).
