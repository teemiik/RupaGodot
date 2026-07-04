#!/usr/bin/env python3
"""Генератор store-ассетов Google Play для «Rupa» (стиль A1).

Артефакты:
  assets/store/play_icon_512.png            512x512   (App icon для листинга)
  assets/store/feature_graphic_1024x500.png 1024x500  (Feature graphic)
  assets/store/screenshots/01_menu.png … 8  1080x1920 (Phone screenshots, 9:16, EN)

Текст — английский (грузим strings.properties + override strings_en.properties,
как I18N в en-локали). Позиции отверстий/барьеров — из assets/levels/*.json.
Запуск:  python3 tools/generate_store_assets.py
"""

import os
import json
import colorsys
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

import generate_icon as gi   # переиспользуем рендер иконки A1 и хелперы

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, 'assets')
STORE = os.path.join(ASSETS, 'store')
SHOTS = os.path.join(STORE, 'screenshots')
FONT_PATH = os.path.join(ASSETS, 'fonts', '10771.ttf')

# Разрешение phone-скриншота (9:16)
W, H = 1080, 1920

# Палитра из scripts/game.gd
BALL = np.array([0.80, 0.80, 0.83]) * 255        # #CCCCD4
HOLE = np.array([0.10, 0.10, 0.12]) * 255        # #1A1A1F
BOARD = np.array([0.62, 0.30, 0.28]) * 255       # #9E4D47
BARRIER = np.array([0.12, 0.12, 0.13]) * 255     # #1F1F21
WHITE = np.array([255, 255, 255])

# grid один раз
_X, _Y = np.meshgrid(np.arange(W, dtype=float), np.arange(H, dtype=float))

_FONT_CACHE = {}
def font(size):
    size = max(4, int(round(size)))
    if size not in _FONT_CACHE:
        _FONT_CACHE[size] = ImageFont.truetype(FONT_PATH, size)
    return _FONT_CACHE[size]


# ---------------------------------------------------------------------------
# i18n (как в игре: RU + EN override)
# ---------------------------------------------------------------------------
def load_strings():
    s = {}

    def load(path):
        if not os.path.exists(path):
            return
        with open(path, encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#') or '=' not in line:
                    continue
                k, v = line.split('=', 1)
                s[k.strip()] = v.strip().encode().decode('unicode_escape')

    load(os.path.join(ASSETS, 'strings.properties'))
    load(os.path.join(ASSETS, 'strings_en.properties'))   # EN override
    return s


STR = load_strings()
def t(key, arg=None):
    v = STR.get(key, key)
    if arg is not None:
        v = v.replace('{0}', arg)
    return v


# ---------------------------------------------------------------------------
# геометрия/тема как в game.gd / level_screen.gd
# ---------------------------------------------------------------------------
def fy(ratio):
    """game _fy: y от низа -> пиксели сверху."""
    return H * (1.0 - ratio)


def fx(ratio):
    return W * ratio


def hsv(h_deg, s, v):
    r, g, b = colorsys.hsv_to_rgb((h_deg % 360) / 360.0, s, v)
    return np.array([r, g, b]) * 255


def level_theme(level):
    """build_level_theme: hue=(level-1)*47."""
    hue = ((level - 1) * 47.0) % 360.0
    top = hsv(hue, 0.30, 0.82)
    bot = hsv(hue, 0.65, 0.38)
    glow = hsv(hue, 0.18, 0.95)
    return top, bot, glow


def load_level(level):
    with open(os.path.join(ASSETS, 'levels', f'level{level}.json'), encoding='utf-8') as f:
        return json.load(f)


# ---------------------------------------------------------------------------
# фон (чистый A1: градиент + свечение + виньетка)
# ---------------------------------------------------------------------------
def make_bg(top, bot, glow):
    ty = _Y / (H - 1)
    img = np.empty((H, W, 3))
    for c in range(3):
        img[:, :, c] = top[c] * (1 - ty) + bot[c] * ty
    # центральное свечение (как background_pixel: центр 0.5,0.3; r 0.55)
    gdx = _X / (W - 1) - 0.5
    gdy = _Y / (H - 1) - 0.3
    g = 1.0 - np.sqrt(gdx * gdx + gdy * gdy) / 0.55
    g = np.clip(g, 0, None) ** 2 * 0.22
    img = img * (1 - g[..., None]) + glow[None, None, :] * g[..., None]
    # виньетка
    vdx = _X / (W - 1) - 0.5
    vdy = _Y / (H - 1) - 0.5
    vig = np.clip((np.sqrt(vdx * vdx + vdy * vdy) - 0.4) / 0.4, 0, 1)
    img *= (1 - vig[..., None] ** 2 * 0.4)
    return img


# ---------------------------------------------------------------------------
# фигуры (numpy, AA)
# ---------------------------------------------------------------------------
def draw_circle(rgb, cx, cy, r, color, alpha=1.0):
    a = np.clip(r - np.sqrt((_X - cx) ** 2 + (_Y - cy) ** 2) + 0.5, 0, 1) * alpha
    rgb[:] = rgb * (1 - a[..., None]) + color[None, None, :] * a[..., None]


def draw_hole(rgb, cx, cy, r):
    """hole_tex: тёмный круг с лёгким высветлением к краю."""
    dist = np.sqrt((_X - cx) ** 2 + (_Y - cy) ** 2)
    a = np.clip(r - dist + 0.5, 0, 1)
    shade = (dist / r - 0.5) * 0.22
    col = np.clip(HOLE[None, None, :] + shade[..., None] * 255, 0, 255)
    rgb[:] = rgb * (1 - a[..., None]) + col * a[..., None]


def draw_ball(rgb, cx, cy, r):
    """ball_tex: светлая сфера со смещённым бликом."""
    dist = np.sqrt((_X - cx) ** 2 + (_Y - cy) ** 2)
    a = np.clip(r - dist + 0.5, 0, 1)
    hx, hy, hr = cx - r * 0.28, cy - r * 0.32, r * 1.2
    hl = np.clip(1.0 - np.sqrt((_X - hx) ** 2 + (_Y - hy) ** 2) / hr, 0, 1) * 0.45
    col = np.clip(BALL[None, None, :] + hl[..., None] * 255, 0, 255)
    rgb[:] = rgb * (1 - a[..., None]) + col * a[..., None]


# ---------------------------------------------------------------------------
# текст (PIL, с тенью как _draw_shadowed)
# ---------------------------------------------------------------------------
def text_centered(img, text, cx, y, size, shadow=True):
    d = ImageDraw.Draw(img)
    o = max(1.0, W * 0.004)
    if shadow:
        d.text((cx + o, y - o), text, font=font(size), fill=(0, 0, 0, 140), anchor='ms')
    d.text((cx, y), text, font=font(size), fill=(255, 255, 255, 255), anchor='ms')


# ---------------------------------------------------------------------------
# общие элементы экранов
# ---------------------------------------------------------------------------
def paste_img(img, path, cx, cy, scale=1.0):
    im = Image.open(path).convert('RGBA')
    if scale != 1.0:
        im = im.resize((max(1, int(im.width * scale)), max(1, int(im.height * scale))))
    img.alpha_composite(im, (int(cx - im.width / 2), int(cy - im.height / 2)))


def rounded_panel(img, x, y, w, h, radius, top, bot, alpha_mul=1.0, shadow=True):
    """Полупрозрачная панель как round_rect_gradient."""
    ov = Image.new('RGBA', (int(w), int(h)), (0, 0, 0, 0))
    od = ImageDraw.Draw(ov)
    od.rounded_rectangle((0, 0, w - 1, h - 1), radius=radius,
                         fill=(int(bot[0]), int(bot[1]), int(bot[2]), int(150 * alpha_mul)))
    # лёгкий вертикальный градиент сверху
    grad = Image.new('RGBA', (1, int(h)), (0, 0, 0, 0))
    for yy in range(int(h)):
        tt = yy / max(1, h - 1)
        a = int((40 + (150 - 40) * (1 - tt)) * alpha_mul)
        grad.putpixel((0, yy), (int(top[0]), int(top[1]), int(top[2]), a))
    grad = grad.resize((int(w), int(h)))
    ov = Image.alpha_composite(ov, grad)
    od2 = ImageDraw.Draw(ov)
    od2.rounded_rectangle((0, 0, w - 1, h - 1), radius=radius, outline=None)
    if shadow:
        sh = Image.new('RGBA', img.size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(sh)
        off = max(1, int(W * 0.007))
        sd.rounded_rectangle((x + off, y + off, x + w + off, y + h + off), radius=radius,
                             fill=(0, 0, 0, 64))
        sh = sh.filter(ImageFilter.GaussianBlur(2))
        img.alpha_composite(sh)
    img.alpha_composite(ov, (int(x), int(y)))


def draw_board_bar(img):
    """Доска: тонкая бордовая плашка внизу."""
    bw = W - W * 0.25
    bh = W * 0.04
    bx = W * 0.125
    by = fy(0.06) - bh
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((bx, by, bx + bw, by + bh), radius=bh / 2,
                        fill=(int(BOARD[0]), int(BOARD[1]), int(BOARD[2]), 255))


def draw_barriers(img, level_data):
    d = ImageDraw.Draw(img, 'RGBA')
    bw0, bh0 = W * 0.015, W * 0.03   # толщина барьера (визуально)
    for bar in level_data.get('barriers', []):
        w = W * bar['w']
        h = H * bar['h']
        cx = W * bar['x'] + w / 2.0
        cy = fy(bar['y']) - H * bar['h'] / 2.0   # bar.y от низа (как _fy(bar.y+bh/2))
        import math
        ang = math.radians(-bar.get('rotation', 0))
        ca, sa = math.cos(ang), math.sin(ang)
        pts = []
        for (ex, ey) in [(-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2)]:
            px = cx + ex * ca - ey * sa
            py = cy + ex * sa + ey * ca
            pts.append((px, py))
        d.polygon(pts, fill=(int(BARRIER[0]), int(BARRIER[1]), int(BARRIER[2]), 255))


def draw_hud(img, level):
    d = ImageDraw.Draw(img)
    o = max(1.0, W * 0.004)
    d.text((W * 0.05 + o, H * 0.05 - o), '00:00', font=font(49), fill=(0, 0, 0, 140), anchor='ls')
    d.text((W * 0.05, H * 0.05), '00:00', font=font(49), fill=(255, 255, 255, 255), anchor='ls')
    # pause icon (две полосы) сверху-справа
    ps = W * 0.07
    px = W - ps - W * 0.05
    py = H * 0.03
    bar_w = ps * 0.22
    gap = ps * 0.16
    d.rounded_rectangle((px, py + ps * 0.15, px + bar_w, py + ps * 0.85), radius=bar_w / 2, fill=(255, 255, 255, 230))
    d.rounded_rectangle((px + bar_w + gap, py + ps * 0.15, px + 2 * bar_w + gap, py + ps * 0.85),
                        radius=bar_w / 2, fill=(255, 255, 255, 230))


# ---------------------------------------------------------------------------
# экраны
# ---------------------------------------------------------------------------
def base_image(top, bot, glow):
    arr = make_bg(top, bot, glow).clip(0, 255).astype(np.uint8)
    return Image.fromarray(arr, 'RGB').convert('RGBA')


def render_menu():
    img = base_image(gi.GRAD_TOP, gi.GRAD_BOT, gi.GLOW)
    title = t('app_name')                       # Rupa
    text_centered(img, title, W / 2, fy(0.82), 74 * 1.6)
    # play
    paste_img(img, os.path.join(ASSETS, 'Menu', 'play.png'), W / 2, fy(0.56), scale=(W * 0.24) / 256)
    text_centered(img, t('menu_levels'), W / 2, fy(0.34), 74)
    text_centered(img, t('menu_exit'), W / 2, fy(0.23), 74)
    return img


def render_level_select():
    img = base_image(gi.GRAD_TOP, gi.GRAD_BOT, gi.GLOW)
    cols, tile = 3, W * 0.17
    gap_x, gap_y = tile * 0.5, tile * 0.7
    grid_w = cols * tile + (cols - 1) * gap_x
    start_x = (W - grid_w) / 2
    text_size = 49
    arrow_y = fy(0.88)
    title_y = arrow_y + (W * 0.07) / 2 + text_size / 2
    text_centered(img, t('level_select_title'), W / 2, title_y, text_size)
    # back arrow (треугольник) сверху-слева
    ar = W * 0.07
    ax, ay = W * 0.05, arrow_y
    d = ImageDraw.Draw(img)
    import math
    d.polygon([(ax + ar * 0.3, ay + ar / 2), (ax + ar * 0.75, ay + ar * 0.28),
               (ax + ar * 0.75, ay + ar * 0.72)], fill=(255, 255, 255, 230))
    d.line([(ax + ar * 0.5, ay + ar / 2), (ax + ar, ay + ar / 2)], fill=(255, 255, 255, 230), width=max(3, int(ar * 0.08)))
    # плитки
    count = 10
    rows = (count + cols - 1) // cols
    grid_h = rows * tile + (rows - 1) * gap_y
    base_top = max((H - grid_h) / 2, title_y + text_size * 1.5 + tile * 0.5)
    top_c = hsv(265, 0.30, 0.50); bot_c = hsv(265, 0.55, 0.22)   # фиолетовые плитки
    for i in range(count):
        c = i % cols; r = i // cols
        bx = start_x + c * (tile + gap_x)
        by = base_top + r * (tile + gap_y)
        ov = Image.new('RGBA', (int(tile) + 2, int(tile) + 2), (0, 0, 0, 0))
        od = ImageDraw.Draw(ov)
        ty2 = np.linspace(0, 1, int(tile))
        for yy in range(int(tile)):
            tt = yy / max(1, int(tile) - 1)
            col = (top_c * (1 - tt) + bot_c * tt)
            od.line([(1, yy + 1), (int(tile), yy + 1)], fill=(int(col[0]), int(col[1]), int(col[2]), 255))
        mask = Image.new('L', ov.size, 0)
        ImageDraw.Draw(mask).ellipse((1, 1, int(tile), int(tile)), fill=255)
        ov.putalpha(mask)
        img.alpha_composite(ov, (int(bx), int(by)))
        td = ImageDraw.Draw(img)
        num = str(i + 1)
        ns = 74
        bbox = td.textbbox((0, 0), num, font=font(ns), anchor='mm')
        td.text((bx + tile / 2, by + tile / 2), num, font=font(ns), fill=(255, 255, 255, 255), anchor='mm')
    return img


def render_gameplay(level, paused=False):
    top, bot, glow = level_theme(level)
    img = base_image(top, bot, glow)
    data = load_level(level)
    # отверстия
    arr = np.array(img)               # HxWx4
    rgb = arr[:, :, :3].astype(float)
    hr = (W * 0.0695) / 2
    for h in data.get('holes', []):
        draw_hole(rgb, W * h['x'], fy(h['y']), hr)
    for dh in data.get('dynamicHoles', []):
        draw_hole(rgb, W * dh['x'], fy(dh['y']), hr)
    # шар (по центру-низу, как стартовая позиция)
    draw_ball(rgb, W * 0.5, fy(0.5), (W * 0.06) / 2)
    arr[:, :, :3] = rgb.clip(0, 255).astype(np.uint8)
    img = Image.fromarray(arr, 'RGBA')
    draw_board_bar(img)
    draw_barriers(img, data)
    # руки-подсказки
    if data.get('showHints', False):
        hand = os.path.join(ASSETS, 'Gestures', 'training_right_74.png')
        hand_l = os.path.join(ASSETS, 'Gestures', 'training_left_74.png')
        hy = fy(0.1)
        paste_img(img, hand, W * 0.8, hy, scale=2.0)
        paste_img(img, hand_l, W * 0.2, hy, scale=2.0)
    draw_hud(img, level)
    if paused:
        d = ImageDraw.Draw(img, 'RGBA')
        d.rectangle((0, 0, W, H), fill=(0, 0, 0, 77))
        pw, ph = min(W * 0.92, 700), H * 0.46
        px, py = (W - pw) / 2, (H - ph) / 2
        rounded_panel(img, px, py, pw, ph, W * 0.05, hsv(250, 0.30, 0.40), hsv(250, 0.55, 0.18))
        fnt = 74
        cy = H / 2 - fnt * 2.4
        opts = [t('pause_title'), t('pause_continue'), t('pause_restart'), t('pause_levels'), t('pause_menu')]
        for i, s in enumerate(opts):
            sz = fnt * 1.35 if i == 0 else fnt
            text_centered(img, s, W / 2, cy, sz)
            cy += fnt * 1.6
    return img


def render_result(level, won):
    top, bot, glow = level_theme(level)
    img = base_image(top, bot, glow)
    fnt = 74
    if won:
        rows = [t('result_win_title'), t('result_time', '00:42'), t('result_record', '00:38'),
                t('result_next_level'), t('result_restart'), t('result_levels'), t('result_menu')]
        sizes = [round(fnt * 1.35), 49, 49, fnt, fnt, fnt, fnt]
    else:
        rows = [t('result_lose_title'), t('result_restart'), t('result_levels'), t('result_menu')]
        sizes = [round(fnt * 1.35), fnt, fnt, fnt]
    lh = fnt * 1.6
    ph = lh * (len(rows) + 1.0)
    pw = min(W * 0.92, 760)
    px, py = (W - pw) / 2, (H - ph) / 2
    rounded_panel(img, px, py, pw, ph, W * 0.06, hsv(265, 0.30, 0.40), hsv(265, 0.55, 0.18))
    cy = py + lh * 0.9
    for s, sz in zip(rows, sizes):
        text_centered(img, s, W / 2, cy, sz)
        cy += lh
    return img


# ---------------------------------------------------------------------------
# feature graphic + play icon
# ---------------------------------------------------------------------------
def render_feature_graphic():
    FW, FH = 1024, 500
    X, Y = np.meshgrid(np.arange(FW, dtype=float), np.arange(FH, dtype=float))
    ty = Y / (FH - 1)
    img = np.empty((FH, FW, 3))
    for c in range(3):
        img[:, :, c] = gi.GRAD_TOP[c] * (1 - ty) + gi.GRAD_BOT[c] * ty
    gdx = X / (FW - 1) - 0.5
    gdy = Y / (FH - 1) - 0.3
    g = np.clip(1.0 - np.sqrt(gdx * gdx + gdy * gdy) / 0.6, 0, None) ** 2 * 0.22
    img = img * (1 - g[..., None]) + gi.GLOW[None, None, :] * g[..., None]
    pil = Image.fromarray(img.clip(0, 255).astype(np.uint8), 'RGB').convert('RGBA')
    # иконка-тайл слева
    tile = 320
    icon_arr = gi.compose(tile, rounded=True, motif='standalone', bg=True)
    icon_img = Image.fromarray(np.ascontiguousarray(icon_arr.clip(0, 255).astype(np.uint8)), 'RGBA')
    pil.alpha_composite(icon_img, (70, (FH - tile) // 2))
    # wordmark "Rupa" — подбираем размер, чтобы влез в оставшееся место
    d = ImageDraw.Draw(pil)
    txt = 'Rupa'
    x_text = 70 + tile + 50
    max_w = FW - x_text - 40
    for fsize in (230, 210, 190, 170):
        fnt = ImageFont.truetype(FONT_PATH, fsize)
        if fnt.getlength(txt) <= max_w:
            break
    o = 4
    d.text((x_text + o, FH // 2 + 6 - o), txt, font=fnt, fill=(0, 0, 0, 120), anchor='lm')
    d.text((x_text, FH // 2 + 6), txt, font=fnt, fill=(255, 255, 255, 255), anchor='lm')
    return pil


def render_play_icon_512():
    arr = gi.compose(512, rounded=False, motif='standalone', bg=True)
    img = Image.fromarray(np.ascontiguousarray(arr.clip(0, 255).astype(np.uint8)), 'RGBA').convert('RGB')
    return img


def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(f"  wrote {os.path.relpath(path, ROOT)}  {img.size[0]}x{img.size[1]}")


def main():
    print("Generating Google Play store assets (style A1)…")
    save(render_play_icon_512(), os.path.join(STORE, 'play_icon_512.png'))
    save(render_feature_graphic(), os.path.join(STORE, 'feature_graphic_1024x500.png'))
    screens = [
        ('01_menu.png', render_menu()),
        ('02_level_select.png', render_level_select()),
        ('03_gameplay_l1.png', render_gameplay(1)),
        ('04_gameplay_l2.png', render_gameplay(2)),
        ('05_victory_l1.png', render_result(1, won=True)),
        ('06_pause_l1.png', render_gameplay(1, paused=True)),
        ('07_gameplay_l6.png', render_gameplay(6)),
        ('08_victory_l6.png', render_result(6, won=True)),
    ]
    for name, img in screens:
        save(img, os.path.join(SHOTS, name))
    print("Done.")


if __name__ == '__main__':
    main()
