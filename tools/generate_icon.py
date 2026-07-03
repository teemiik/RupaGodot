#!/usr/bin/env python3
"""Генератор иконки приложения «Rupa» (вариант A1 — мягкий тёплый градиент).

Рисует все растровые иконки средствами Pillow+numpy из единого набора
параметров композиции (поле 200x200). Палитра взята из scripts/game.gd
(bg_warm_*, hole_color, ball_color).

Артефакты:
  assets/icon.png                 1024  squircle   (project.godot + Android main_192)
  assets/icons/ios_1024.png       1024  full-bleed (export_presets icon_1024x1024)
  assets/icons/android_bg_432.png  432  full-bleed градиент (adaptive background)
  assets/icons/android_fg_432.png  432  transparent, мотив в safe-zone (adaptive foreground)

Запуск:  python3 tools/generate_icon.py
"""

import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

# ---------------------------------------------------------------------------
# Палитра (из scripts/game.gd)
# ---------------------------------------------------------------------------
GRAD_TOP = np.array([0xCC, 0xC2, 0xAD], dtype=float)   # bg_warm_top
GRAD_BOT = np.array([0x85, 0x21, 0x2E], dtype=float)   # bg_warm_bottom
GLOW     = np.array([0xF5, 0xE6, 0xC7], dtype=float)   # bg_warm_glow
HOLE_IN  = np.array([0x0C, 0x0C, 0x0E], dtype=float)
HOLE_OUT = np.array([0x22, 0x13, 0x18], dtype=float)
RIM      = np.array([0xF5, 0xE6, 0xC7], dtype=float)
BALL_C0  = np.array([255, 255, 255], dtype=float)
BALL_C1  = np.array([0xCC, 0xCC, 0xD4], dtype=float)   # ball_color
BALL_C2  = np.array([0x8F, 0x8F, 0x97], dtype=float)
BLACK    = np.array([0, 0, 0], dtype=float)

# ---------------------------------------------------------------------------
# Композиция в нормализованном поле 200x200
# ---------------------------------------------------------------------------
TILE_PAD, TILE_RX = 6, 44                       # скруглённая плитка
GLOW_CX, GLOW_CY, GLOW_RX, GLOW_RY = 100, 70, 92, 46
GLOW_STR = 0.22
HOLE_CX, HOLE_CY, HOLE_R = 100, 108, 46
RIM_R, RIM_W, RIM_STR = 48, 2.5, 0.5
INNER_CX, INNER_CY, INNER_RX, INNER_RY = 100, 98, 44, 15
INNER_STR = 0.45
BSH_CX, BSH_CY, BSH_RX, BSH_RY = 132, 94, 17, 6
BSH_STR = 0.28
BALL_CX, BALL_CY, BALL_R = 132, 75, 16

# SVG-faithful градиенты (objectBoundingBox -> userSpace, поле 200x200):
HOLE_GCX, HOLE_GCY, HOLE_GR = 100, 100.64, 57.04   # radialGradient cx=.5 cy=.42 r=.62 (bbox 92)
BALL_GCX, BALL_GCY, BALL_GR = 126.88, 68.6, 27.2    # radialGradient cx=.34 cy=.3 r=.85 (bbox 32)
SVG_BLUR = 3.5                                      # feGaussianBlur stdDeviation из icon.svg

# Адаптивная иконка: мотив вписываем в центральную safe-zone (~60% поля)
GC = np.array([100.5, 107.5])   # центр группы «отверстие+шар» в 200-пространстве
GROUP_EXT = 97.0                # макс. габарит группы
ADAP_TARGET = 120.0             # целевой габарит в 200-пространстве (~60%)
ADAP_SCALE = ADAP_TARGET / GROUP_EXT
ADAP_CENTER = np.array([100.0, 100.0])

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


# ---------------------------------------------------------------------------
# Примитивы
# ---------------------------------------------------------------------------
def grid(size):
    ax = np.arange(size, dtype=float)
    X, Y = np.meshgrid(ax, ax)
    return X, Y


def vgradient(size):
    """Вертикальный градиент top->bottom, форма (size,size,3)."""
    t = np.linspace(0, 1, size)[:, None]
    col = np.empty((size, size, 3), dtype=float)
    for c in range(3):
        col[:, :, c] = GRAD_TOP[c] * (1 - t) + GRAD_BOT[c] * t
    return col


def rounded_mask(size):
    k = size / 200.0
    img = Image.new('L', (size, size), 0)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(
        (TILE_PAD * k, TILE_PAD * k, size - TILE_PAD * k, size - TILE_PAD * k),
        radius=TILE_RX * k, fill=255)
    return np.array(img, dtype=float)


def ellipse_alpha(X, Y, cx, cy, rx, ry):
    """Сплошной эллипс с антиалиасингом ~1px (как заливка в SVG)."""
    rn = np.sqrt(((X - cx) / rx) ** 2 + ((Y - cy) / ry) ** 2)   # 0 в центре, 1 на границе
    w = 1.0 / min(rx, ry)                                       # 1px в нормированных единицах
    return np.clip((1.0 - rn) / w + 0.5, 0, 1)


def circle_alpha(X, Y, cx, cy, r):
    """Сплошной круг с антиалиасингом ~1px."""
    d = np.sqrt((X - cx) ** 2 + (Y - cy) ** 2)
    return np.clip(r - d + 0.5, 0, 1)


def ring_alpha(X, Y, cx, cy, r, w):
    """Кольцо-обводка шириной w (как SVG stroke), 1px AA."""
    dist = np.sqrt((X - cx) ** 2 + (Y - cy) ** 2)
    return np.clip(w / 2.0 - np.abs(dist - r) + 0.5, 0, 1)


def blur(a, px):
    if px <= 0.2:
        return a
    im = Image.fromarray((a * 255).clip(0, 255).astype(np.uint8), 'L')
    im = im.filter(ImageFilter.GaussianBlur(px))
    return np.array(im, dtype=float) / 255.0


def radial_stops(X, Y, cx, cy, r, stops):
    """Радиальный градиент с произвольными стопами (один-в-один как в SVG).
    stops: [(pos, np.array rgb), ...] отсортированы по pos."""
    dist = np.sqrt((X - cx) ** 2 + (Y - cy) ** 2)
    t = np.clip(dist / r, 0, 1)
    pos = np.array([s[0] for s in stops])
    cols = np.array([s[1] for s in stops])
    result = np.broadcast_to(cols[0], t.shape + (3,)).copy()
    for i in range(len(stops) - 1):
        p0, p1 = pos[i], pos[i + 1]
        seg = (t >= p0) & (t <= p1)
        tt = ((t - p0) / (p1 - p0))[..., None]
        chan = cols[i] * (1 - tt) + cols[i + 1] * tt
        result = np.where(seg[..., None], chan, result)
    return result


def over_rgba(acc_rgb, acc_a, top_rgb, top_a):
    """Alpha-compositing: слой `top` поверх аккумулятора `acc` (straight alpha)."""
    top_a = top_a[..., None]
    acc_a_ = acc_a[..., None]
    out_a = top_a + acc_a_ * (1 - top_a)
    safe = np.where(out_a > 1e-6, out_a, 1.0)
    out_rgb = (top_rgb * top_a + acc_rgb * acc_a_ * (1 - top_a)) / safe
    return out_rgb, out_a[..., 0]


# ---------------------------------------------------------------------------
# Слои
# ---------------------------------------------------------------------------
def render_bg(size, rounded):
    """Градиент + верхнее свечение. Возвращает (rgb, alpha 0..255)."""
    k = size / 200.0
    X, Y = grid(size)
    img = vgradient(size)
    g = ellipse_alpha(X, Y, GLOW_CX * k, GLOW_CY * k, GLOW_RX * k, GLOW_RY * k)
    g = blur(g, SVG_BLUR * k)   # SVG: feGaussianBlur stdDeviation=3.5
    img = over_rgba(img, np.ones((size, size)), GLOW[None, None, :] *
                    np.ones((size, size, 1)), g * GLOW_STR)[0]
    alpha = rounded_mask(size) if rounded else np.full((size, size), 255.0)
    return img, alpha


def render_motif(size, mode):
    """Мотив «отверстие + шар». mode: 'standalone' | 'adaptive'.
    Возвращает (rgb, alpha 0..1) на прозрачном фоне."""
    k = size / 200.0
    X, Y = grid(size)
    if mode == 'standalone':
        P = lambda p: np.array(p, dtype=float) * k
        S = lambda s: s * k
    else:
        P = lambda p: (ADAP_CENTER + (np.array(p, dtype=float) - GC) * ADAP_SCALE) * k
        S = lambda s: s * ADAP_SCALE * k

    rgb = np.zeros((size, size, 3), dtype=float)
    a = np.zeros((size, size), dtype=float)

    hc = P((HOLE_CX, HOLE_CY))
    # рим-лайт (под отверстием — кольцо выглядывает по краю)
    rgb, a = over_rgba(rgb, a, np.broadcast_to(RIM, (size, size, 3)),
                       ring_alpha(X, Y, hc[0], hc[1], S(RIM_R), S(RIM_W)) * RIM_STR)
    # отверстие (SVG radial: смещённый центр + тёмное плато до 0.5)
    ghc = P((HOLE_GCX, HOLE_GCY))
    rgb, a = over_rgba(rgb, a,
                       radial_stops(X, Y, ghc[0], ghc[1], S(HOLE_GR),
                                    [(0, HOLE_IN), (0.5, HOLE_IN), (1, HOLE_OUT)]),
                       circle_alpha(X, Y, hc[0], hc[1], S(HOLE_R)))
    # внутренняя тень (в SVG без размытия)
    ic = P((INNER_CX, INNER_CY))
    ia = ellipse_alpha(X, Y, ic[0], ic[1], S(INNER_RX), S(INNER_RY)) * INNER_STR
    rgb, a = over_rgba(rgb, a, np.broadcast_to(BLACK, (size, size, 3)), ia)
    # тень шара (SVG blur 3.5)
    bsc = P((BSH_CX, BSH_CY))
    ba = blur(ellipse_alpha(X, Y, bsc[0], bsc[1], S(BSH_RX), S(BSH_RY)) * BSH_STR,
              SVG_BLUR * k)
    rgb, a = over_rgba(rgb, a, np.broadcast_to(BLACK, (size, size, 3)), ba)
    # шар (SVG radial со смещённым бликом)
    bll = P((BALL_CX, BALL_CY))
    gbc = P((BALL_GCX, BALL_GCY))
    rgb, a = over_rgba(rgb, a,
                       radial_stops(X, Y, gbc[0], gbc[1], S(BALL_GR),
                                    [(0, BALL_C0), (0.55, BALL_C1), (1, BALL_C2)]),
                       circle_alpha(X, Y, bll[0], bll[1], S(BALL_R)))
    return rgb, a


def compose(size, rounded, motif, bg):
    """Собирает финальное RGBA-изображение (size,size,4) float 0..255."""
    layers_rgb = np.zeros((size, size, 3), dtype=float)
    layers_a = np.zeros((size, size), dtype=float)
    if bg:
        br, ba = render_bg(size, rounded)
        layers_rgb, layers_a = over_rgba(layers_rgb, layers_a, br, ba / 255.0)
    if motif:
        mr, ma = render_motif(size, motif)
        layers_rgb, layers_a = over_rgba(layers_rgb, layers_a, mr, ma)
    out = np.empty((size, size, 4), dtype=float)
    out[:, :, :3] = layers_rgb
    out[:, :, 3] = layers_a * 255.0
    return out


def save(arr, path, flatten=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img = Image.fromarray(np.ascontiguousarray(arr.clip(0, 255).astype(np.uint8)), 'RGBA')
    if flatten:
        # Opaque-варианты (iOS 1024, Android background) — без альфа-канала:
        # App Store требует flattened PNG, фон адаптивной иконки тоже opaque.
        img = img.convert('RGB')
    img.save(path)
    print(f"  wrote {os.path.relpath(path, ROOT)}  {img.size[0]}x{img.size[1]}"
          f"{' (RGB)' if img.mode == 'RGB' else ' (RGBA)'}")


def main():
    print("Generating Rupa app icon (variant A1)…")
    assets = os.path.join(ROOT, 'assets')
    icons = os.path.join(assets, 'icons')

    # Основной значок: squircle, автономная композиция
    save(compose(1024, rounded=True, motif='standalone', bg=True),
         os.path.join(assets, 'icon.png'))
    # iOS: full-bleed квадрат (маску накладывает система), opaque RGB
    save(compose(1024, rounded=False, motif='standalone', bg=True),
         os.path.join(icons, 'ios_1024.png'), flatten=True)
    # Android adaptive: фон (полный градиент, opaque) + передний план (мотив в safe-zone)
    save(compose(432, rounded=False, motif=None, bg=True),
         os.path.join(icons, 'android_bg_432.png'), flatten=True)
    save(compose(432, rounded=False, motif='adaptive', bg=False),
         os.path.join(icons, 'android_fg_432.png'))

    print("Done.")


if __name__ == '__main__':
    main()
