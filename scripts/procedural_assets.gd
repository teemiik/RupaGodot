class_name ProceduralAssets
extends RefCounted

static func solid(color: Color) -> ImageTexture:
	var img= Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var tex= ImageTexture.create_from_image(img)
	tex.set_image(img)
	return tex

static func circle(diameter: int, color: Color) -> ImageTexture:
	if diameter < 2:
		diameter = 2
	var img= Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var r= max(1.0, diameter / 2.0 - 0.5)
	for y in range(diameter):
		for x in range(diameter):
			var dx= x + 0.5 - r
			var dy= y + 0.5 - r
			var edge= r - sqrt(dx * dx + dy * dy)
			var a= 0.0
			if edge >= 1.0:
				a = 1.0
			elif edge > 0.0:
				a = edge
			img.set_pixel(x, y, Color(color.r, color.g, color.b, a * color.a))
	var tex= ImageTexture.create_from_image(img)
	return tex

static func ball_tex(diameter: int, base: Color) -> ImageTexture:
	if diameter < 2:
		diameter = 2
	var img= Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var r= max(1.0, diameter / 2.0 - 0.5)
	var cx= diameter / 2.0
	var cy= diameter / 2.0
	var hx= diameter * 0.36
	var hy= diameter * 0.34
	var hr= diameter * 0.6
	for y in range(diameter):
		for x in range(diameter):
			var dx= x + 0.5 - cx
			var dy= y + 0.5 - cy
			var alpha= r - sqrt(dx * dx + dy * dy)
			if alpha <= 0.0:
				img.set_pixel(x, y, Color.TRANSPARENT)
				continue
			if alpha > 1.0:
				alpha = 1.0
			var hdx= x + 0.5 - hx
			var hdy= y + 0.5 - hy
			var hl= (1.0 - sqrt(hdx * hdx + hdy * hdy) / hr)
			if hl < 0.0:
				hl = 0.0
			hl *= 0.45
			img.set_pixel(x, y, Color(
				clamp(base.r + hl, 0, 1),
				clamp(base.g + hl, 0, 1),
				clamp(base.b + hl, 0, 1),
				alpha * base.a))
	return ImageTexture.create_from_image(img)

static func hole_tex(diameter: int, base: Color) -> ImageTexture:
	if diameter < 2:
		diameter = 2
	var img= Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var r= max(1.0, diameter / 2.0 - 0.5)
	var cx= diameter / 2.0
	var cy= diameter / 2.0
	for y in range(diameter):
		for x in range(diameter):
			var dx= x + 0.5 - cx
			var dy= y + 0.5 - cy
			var dist= sqrt(dx * dx + dy * dy)
			var alpha= r - dist
			if alpha <= 0.0:
				img.set_pixel(x, y, Color.TRANSPARENT)
				continue
			if alpha > 1.0:
				alpha = 1.0
			var shade= (dist / r - 0.5) * 0.22
			img.set_pixel(x, y, Color(
				clamp(base.r + shade, 0, 1),
				clamp(base.g + shade, 0, 1),
				clamp(base.b + shade, 0, 1),
				alpha * base.a))
	return ImageTexture.create_from_image(img)

static func gradient_circle(diameter: int, top: Color, bottom: Color) -> ImageTexture:
	if diameter < 2:
		diameter = 2
	var img= Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var r= diameter / 2.0
	for y in range(diameter):
		var ty= float(y) / max(1, diameter - 1)
		var cr= lerp(top.r, bottom.r, ty)
		var cg= lerp(top.g, bottom.g, ty)
		var cb= lerp(top.b, bottom.b, ty)
		var ca= lerp(top.a, bottom.a, ty)
		for x in range(diameter):
			var dx= x + 0.5 - r
			var dy= y + 0.5 - r
			var edge= r - sqrt(dx * dx + dy * dy)
			if edge <= 0.0:
				img.set_pixel(x, y, Color.TRANSPARENT)
				continue
			var a= min(1.0, edge)
			img.set_pixel(x, y, Color(cr, cg, cb, a * ca))
	return ImageTexture.create_from_image(img)

static func background_pixel(top: Color, bottom: Color, glow: Color) -> ImageTexture:
	var w = 128
	var h = 220
	var img= Image.create(w, h, false, Image.FORMAT_RGBA8)
	var seed_val= int(top.r * 1000) ^ (int(top.g * 1000) << 10) ^ (int(top.b * 1000) << 20)
	var rng= RandomNumberGenerator.new()
	rng.set_seed(absi(seed_val) % 2147483647)

	var terrain= []
	terrain.resize(w)
	var base_h= 16.0 + rng.randf() * 20.0
	for x in range(w):
		var n= sin(x * 0.18 + seed_val * 0.01) * 0.5 \
			+ sin(x * 0.07 + seed_val * 0.02) * 0.3 \
			+ sin(x * 0.03 + seed_val * 0.03) * 0.2
		terrain[x] = base_h + (n + 1.0) * 0.5 * base_h * 0.8

	var cloud_y= int(h * (0.12 + rng.randf() * 0.25))
	var cloud_w= 10 + rng.randi() % 18
	var cloud_x= 5 + rng.randi() % maxi(1, w - cloud_w - 10)
	var cloud= []
	cloud.resize(cloud_w * 8)
	for cy2 in range(8):
		for cx2 in range(cloud_w):
			cloud[cy2 * cloud_w + cx2] = sin(cx2 * 0.7 + cy2 * 1.2 + seed_val * 0.005) * 0.5 + 0.5 > 0.45

	var cloud_y2= int(h * (0.30 + rng.randf() * 0.15))
	var cloud_w2= 7 + rng.randi() % 14
	var cloud_x2= 30 + rng.randi() % maxi(1, w - cloud_w2 - 40)
	var cloud2= []
	cloud2.resize(cloud_w2 * 6)
	for cy3 in range(6):
		for cx3 in range(cloud_w2):
			cloud2[cy3 * cloud_w2 + cx3] = sin(cx3 * 0.6 + cy3 * 1.4 + seed_val * 0.007 + 50) * 0.5 + 0.5 > 0.5

	for y in range(h):
		var ty= float(y) / max(1, h - 1)
		for x in range(w):
			var tx= float(x) / max(1, w - 1)
			var cr= lerp(top.r, bottom.r, ty)
			var cg= lerp(top.g, bottom.g, ty)
			var cb= lerp(top.b, bottom.b, ty)

			var gdx= tx - 0.5
			var gdy= ty - 0.3
			var g_a= 1.0 - sqrt(gdx * gdx + gdy * gdy) / 0.55
			if g_a > 0.0:
				g_a *= g_a * 0.22
				cr += (glow.r - cr) * g_a
				cg += (glow.g - cg) * g_a
				cb += (glow.b - cb) * g_a

			var vdx= tx - 0.5
			var vdy= ty - 0.5
			var vig= (sqrt(vdx * vdx + vdy * vdy) - 0.4) / 0.4
			if vig > 0.0:
				vig = min(1.0, vig)
				var darken= 1.0 - vig * vig * 0.4
				cr *= darken
				cg *= darken
				cb *= darken

			var t_h= int(terrain[x])
			if y >= h - t_h:
				var t2= float(y - (h - t_h)) / max(1, t_h)
				cr *= 0.30 + t2 * 0.15
				cg *= 0.30 + t2 * 0.15
				cb *= 0.30 + t2 * 0.15

			if x >= cloud_x and x < cloud_x + cloud_w and y >= cloud_y and y < cloud_y + 8:
				if cloud[(y - cloud_y) * cloud_w + (x - cloud_x)]:
					cr += (1.0 - cr) * 0.35
					cg += (1.0 - cg) * 0.35
					cb += (1.0 - cb) * 0.35

			if x >= cloud_x2 and x < cloud_x2 + cloud_w2 and y >= cloud_y2 and y < cloud_y2 + 6:
				if cloud2[(y - cloud_y2) * cloud_w2 + (x - cloud_x2)]:
					cr += (1.0 - cr) * 0.30
					cg += (1.0 - cg) * 0.30
					cb += (1.0 - cb) * 0.30

			cr = round(cr * 15.0) / 15.0
			cg = round(cg * 15.0) / 15.0
			cb = round(cb * 15.0) / 15.0
			img.set_pixel(x, y, Color(clamp(cr, 0, 1), clamp(cg, 0, 1), clamp(cb, 0, 1), 1.0))

	for i in range(40 + rng.randi() % 35):
		var sx= rng.randi() % w
		var sy= rng.randi() % int(h * 0.55)
		var bright= 0.5 + rng.randf() * 0.5
		img.set_pixel(sx, sy, Color(bright, bright, bright, 1.0))
		if rng.randf() < 0.12 and sx + 1 < w and sy + 1 < int(h * 0.55):
			img.set_pixel(sx + 1, sy, Color(bright, bright, bright, 1.0))
			img.set_pixel(sx, sy + 1, Color(bright, bright, bright, 1.0))
			img.set_pixel(sx + 1, sy + 1, Color(bright, bright, bright, 1.0))

	_draw_scenery(img, w, h, terrain, rng)

	return ImageTexture.create_from_image(img)

static func _draw_scenery(img: Image, w: int, h: int, terrain: Array, rng: RandomNumberGenerator) -> void:
	var tree_greens= [
		Color(45 / 255.0, 90 / 255.0, 39 / 255.0),
		Color(61 / 255.0, 122 / 255.0, 55 / 255.0),
		Color(77 / 255.0, 138 / 255.0, 71 / 255.0),
		Color(29 / 255.0, 74 / 255.0, 23 / 255.0),
		Color(93 / 255.0, 154 / 255.0, 87 / 255.0),
		Color(58 / 255.0, 107 / 255.0, 53 / 255.0),
	]
	var trunk_col= Color(74 / 255.0, 53 / 255.0, 32 / 255.0)
	var hw= [0, 1, 2, 2, 1, 0]
	var num_trees= (1 + rng.randi() % 5) if rng.randf() < 0.9 else 0
	for _t in range(num_trees):
		var tx= 6 + rng.randi() % (w - 12)
		var ground_y= h - int(round(terrain[tx]))
		if ground_y < 6:
			continue
		for ty in range(3):
			var py= ground_y - 1 - ty
			if py >= 0:
				img.set_pixel(tx, py, trunk_col)
		var canopy= tree_greens[rng.randi() % tree_greens.size()]
		var canopy_base= ground_y - 3
		for row in range(hw.size()):
			var py2= canopy_base - row
			if py2 < 0:
				break
			for dx in range(-hw[row], hw[row] + 1):
				var px= tx + dx
				if px >= 0 and px < w:
					img.set_pixel(px, py2, canopy)

	var wall_cols= [
		Color(196 / 255.0, 168 / 255.0, 130 / 255.0),
		Color(212 / 255.0, 184 / 255.0, 146 / 255.0),
		Color(180 / 255.0, 152 / 255.0, 114 / 255.0),
		Color(139 / 255.0, 115 / 255.0, 85 / 255.0),
	]
	var roof_cols= [
		Color(139 / 255.0, 69 / 255.0, 19 / 255.0),
		Color(160 / 255.0, 82 / 255.0, 45 / 255.0),
		Color(107 / 255.0, 52 / 255.0, 16 / 255.0),
		Color(123 / 255.0, 68 / 255.0, 35 / 255.0),
	]
	var window_col= Color(1.0, 204 / 255.0, 136 / 255.0)
	var door_col= Color(42 / 255.0, 26 / 255.0, 16 / 255.0)
	var num_houses= (rng.randi() % 3) if rng.randf() < 0.7 else 0
	for _hi in range(num_houses):
		var hx= 10 + rng.randi() % (w - 20)
		var ground_y2= h - int(round(terrain[hx]))
		if ground_y2 < 10:
			continue
		var half_w= 3 + rng.randi() % 2
		var house_h= 5 + rng.randi() % 2
		var wall= wall_cols[rng.randi() % wall_cols.size()]
		for dy in range(house_h):
			for dx in range(-half_w, half_w + 1):
				var px= hx + dx
				var py= ground_y2 - 1 - dy
				if px >= 0 and px < w and py >= 0:
					img.set_pixel(px, py, wall)
		var roof= roof_cols[rng.randi() % roof_cols.size()]
		for row in range(3):
			var half_roof= half_w + 1 - row
			var py3= ground_y2 - 1 - house_h - row
			if py3 < 0:
				break
			for dx in range(-half_roof, half_roof + 1):
				var px= hx + dx
				if px >= 0 and px < w:
					img.set_pixel(px, py3, roof)
		img.set_pixel(hx, ground_y2 - 1, door_col)
		img.set_pixel(hx, ground_y2 - 2, door_col)
		img.set_pixel(hx - 2, ground_y2 - 3, window_col)
		img.set_pixel(hx + 2, ground_y2 - 3, window_col)

	var bird_col= Color(0.13, 0.13, 0.18)
	var num_birds= 1 + rng.randi() % 3
	for _b in range(num_birds):
		var bx= 8 + rng.randi() % (w - 16)
		var by= int(h * (0.25 + rng.randf() * 0.25))
		if bx - 2 >= 0:
			img.set_pixel(bx - 2, by, bird_col)
		if bx + 2 < w:
			img.set_pixel(bx + 2, by, bird_col)
		for dx in range(-1, 2):
			var px= bx + dx
			if px >= 0 and px < w:
				img.set_pixel(px, by + 1, bird_col)

static func round_rect_gradient(w: int, h: int, radius: float, top: Color, bottom: Color) -> ImageTexture:
	if w < 2: w = 2
	if h < 2: h = 2
	if radius < 0.0: radius = 0.0
	var img= Image.create(w, h, false, Image.FORMAT_RGBA8)
	var hw= w / 2.0
	var hh= h / 2.0
	for y in range(h):
		var ty= float(y) / max(1, h - 1)
		var cr= lerp(top.r, bottom.r, ty)
		var cg= lerp(top.g, bottom.g, ty)
		var cb= lerp(top.b, bottom.b, ty)
		for x in range(w):
			var qx= abs(x + 0.5 - hw) - (hw - radius)
			var qy= abs(y + 0.5 - hh) - (hh - radius)
			var mx= max(qx, 0.0)
			var my= max(qy, 0.0)
			var d= sqrt(mx * mx + my * my) + min(max(qx, qy), 0.0) - radius
			var a= 0.5 - d
			if a <= 0.0:
				img.set_pixel(x, y, Color.TRANSPARENT)
				continue
			if a > 1.0: a = 1.0
			img.set_pixel(x, y, Color(cr, cg, cb, a))
	return ImageTexture.create_from_image(img)

static func round_rect(w: int, h: int, radius: float, color: Color) -> ImageTexture:
	if w < 2: w = 2
	if h < 2: h = 2
	if radius < 0.0: radius = 0.0
	var img= Image.create(w, h, false, Image.FORMAT_RGBA8)
	var hw= w / 2.0
	var hh= h / 2.0
	for y in range(h):
		for x in range(w):
			var qx= abs(x + 0.5 - hw) - (hw - radius)
			var qy= abs(y + 0.5 - hh) - (hh - radius)
			var mx= max(qx, 0.0)
			var my= max(qy, 0.0)
			var d= sqrt(mx * mx + my * my) + min(max(qx, qy), 0.0) - radius
			var a= 0.5 - d
			if a <= 0.0:
				img.set_pixel(x, y, Color.TRANSPARENT)
				continue
			if a > 1.0: a = 1.0
			img.set_pixel(x, y, Color(color.r, color.g, color.b, a * color.a))
	return ImageTexture.create_from_image(img)

static func pixel_bar_texture(base: Color) -> ImageTexture:
	var w= 16
	var h= 6
	var img= Image.create(w, h, false, Image.FORMAT_RGBA8)
	var highlight = Color(clamp(base.r + 0.25, 0, 1), clamp(base.g + 0.25, 0, 1), clamp(base.b + 0.25, 0, 1))
	var shadow = Color(clamp(base.r - 0.15, 0, 1), clamp(base.g - 0.15, 0, 1), clamp(base.b - 0.15, 0, 1))
	var dark_shadow = Color(clamp(base.r - 0.30, 0, 1), clamp(base.g - 0.30, 0, 1), clamp(base.b - 0.30, 0, 1))
	for x in range(w):
		img.set_pixel(x, 0, highlight)
		img.set_pixel(x, 1, base)
		img.set_pixel(x, 2, base)
		img.set_pixel(x, 3, base)
		img.set_pixel(x, h - 2, shadow)
		img.set_pixel(x, h - 1, dark_shadow)
	return ImageTexture.create_from_image(img)

static func pause_icon(size: int, color: Color) -> ImageTexture:
	if size < 4: size = 4
	var img= Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var bar_w= maxi(1, roundi(size * 0.22))
	var bar_h= roundi(size * 0.7)
	var top= roundi(size * 0.15)
	var gap= roundi(size * 0.16)
	var left_x= roundi(size / 2.0 - gap / 2.0 - bar_w)
	var rx= roundi(size / 2.0 + gap / 2.0)
	for y in range(top, top + bar_h):
		for x in range(left_x, left_x + bar_w):
			if x >= 0 and x < size and y >= 0 and y < size:
				img.set_pixel(x, y, color)
		for x2 in range(rx, rx + bar_w):
			if x2 >= 0 and x2 < size and y >= 0 and y < size:
				img.set_pixel(x2, y, color)
	return ImageTexture.create_from_image(img)

static func check_mark(size: int, color: Color) -> ImageTexture:
	if size < 4: size = 4
	var img= Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var ax= size * 0.20; var ay= size * 0.55
	var bx= size * 0.42; var by= size * 0.74
	var cx= size * 0.80; var cy= size * 0.28
	var half= size * 0.09
	for y in range(size):
		for x in range(size):
			var px= x + 0.5; var py= y + 0.5
			var d= min(_dist_to_seg(px, py, ax, ay, bx, by), _dist_to_seg(px, py, bx, by, cx, cy))
			var a= half - d
			if a <= 0.0:
				continue
			if a > 1.0: a = 1.0
			img.set_pixel(x, y, Color(color.r, color.g, color.b, a * color.a))
	return ImageTexture.create_from_image(img)

static func back_arrow(size: int, color: Color) -> ImageTexture:
	if size < 4: size = 4
	var img= Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var pad= size * 0.28
	var tip_x= pad; var tip_y= size / 2.0
	var far_x= size - pad
	var top_y= pad; var bot_y= size - pad
	var half= size * 0.085
	for y in range(size):
		for x in range(size):
			var px= x + 0.5; var py= y + 0.5
			var d= min(_dist_to_seg(px, py, tip_x, tip_y, far_x, top_y), _dist_to_seg(px, py, tip_x, tip_y, far_x, bot_y))
			var a= half - d
			if a <= 0.0:
				continue
			if a > 1.0: a = 1.0
			img.set_pixel(x, y, Color(color.r, color.g, color.b, a * color.a))
	return ImageTexture.create_from_image(img)

static func _dist_to_seg(px: float, py: float, ax: float, ay: float, bx: float, by: float) -> float:
	var dx= bx - ax; var dy= by - ay
	var len2= dx * dx + dy * dy
	var t= 0.0 if len2 <= 0.0 else clamp(((px - ax) * dx + (py - ay) * dy) / len2, 0, 1)
	var cx2= ax + t * dx; var cy2= ay + t * dy
	var ex= px - cx2; var ey= py - cy2
	return sqrt(ex * ex + ey * ey)
