extends Node2D

const _DESIGN_REF_H := 640.0
const _BALL_GRAVITY_SCALE_REF := 1.3

var _level: int
var _data: LevelData

var _ball: RigidBody2D
var _board: StaticBody2D

var _board_base_x: float
var _board_base_y: float
var _board_w: float
var _board_h: float
var _i_right = 0.0
var _i_left = 0.0
var _tilt_side = 0
var _last_pivot_side = 0

var _dynamic_hole_bodies: Array = []
var _rotating_bodies: Array = []
var _rotating_data: Array = []

var _ball_diam: float
var _hole_diam: float
var _hole_phys_r: float
var _fade = 0.7
var _dyn_accum = 0.0
var _exiting = false

var _accent_platform_tex: Texture2D
var _default_platform_tex: Texture2D

var _timer_size: int
var _pause_font_size: int
var _pause_icon_tex: Texture2D
var _panel_tex: Texture2D
var _panel_shadow_tex: Texture2D
var _pause_size: float
var _pause_x: float
var _pause_y: float
var _panel_w: float
var _panel_h: float
var _panel_x: float
var _panel_y: float
var _pause_shift: float
var _pause_options: Array = []
var _pressed_pause_index: int = -1
var _pause_press_timer = 0.0
var _dbg_x: float
var _dbg_y: float
var _dbg_w: float
var _dbg_h: float
var _dbg_tex: Texture2D

var _show_hints: bool = false
var _hint_tilted: bool = false
var _hint_right_a: Texture2D
var _hint_right_b: Texture2D
var _hint_left_a: Texture2D
var _hint_left_b: Texture2D

func _fy(y: float) -> float:
	return Game.h - y

func _ready():
	_level = PlayerPrefs.get_pref("_current_level", 1)
	_data = LevelLoader.load_level(_level)
	_ball_diam = Game.w * 0.06
	_hole_diam = Game.w * 0.0695
	_hole_phys_r = Game.w * 0.01
	_board_w = Game.board_width
	_board_h = Game.board_height
	_board_base_x = Game.w * 0.125
	_board_base_y = _fy(Game.h * 0.06) - _board_h

	_timer_size = Game.size_text
	_pause_font_size = Game.size_text_result

	_create_board()
	_create_ball()
	_create_static_holes()
	_create_dynamic_holes()
	_create_barriers()
	_create_rotating_platforms()
	_setup_pause()
	_setup_debug()
	_build_hints()

func _create_board():
	_board = StaticBody2D.new()
	_board.position = Vector2(_board_base_x, _board_base_y)
	var coll = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(_board_w, _board_h)
	coll.shape = shape
	coll.position = Vector2(_board_w / 2.0, _board_h / 2.0)
	_board.add_child(coll)
	var mat = PhysicsMaterial.new()
	mat.friction = 10.0
	mat.bounce = 0.0
	_board.physics_material_override = mat
	add_child(_board)

func _create_ball():
	_ball = RigidBody2D.new()
	_ball.position = Vector2(Game.w * 0.5, Game.h * 0.88)
	_ball.mass = 1.0
	_ball.gravity_scale = _BALL_GRAVITY_SCALE_REF * (Game.h / _DESIGN_REF_H)
	_ball.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	var coll = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = _ball_diam / 2.0
	coll.shape = shape
	_ball.add_child(coll)
	var mat = PhysicsMaterial.new()
	mat.friction = 10.0
	mat.bounce = 0.4
	_ball.physics_material_override = mat
	add_child(_ball)

func _create_static_holes():
	for h in _data.holes:
		var area = Area2D.new()
		area.position = Vector2(Game.w * h.x, _fy(Game.h * h.y))
		var a_coll = CollisionShape2D.new()
		var a_shape = CircleShape2D.new()
		a_shape.radius = _hole_phys_r
		a_coll.shape = a_shape
		area.add_child(a_coll)
		area.body_entered.connect(func(body): if body == _ball: Game.failed = false)
		add_child(area)

func _create_dynamic_holes():
	for dh in _data.dynamic_holes:
		var body = AnimatableBody2D.new()
		body.position = Vector2(Game.w * dh.x, _fy(Game.h * dh.y))
		var area = Area2D.new()
		var a_coll = CollisionShape2D.new()
		var a_shape = CircleShape2D.new()
		a_shape.radius = _hole_phys_r
		a_coll.shape = a_shape
		area.add_child(a_coll)
		area.body_entered.connect(func(body): if body == _ball: Game.failed = false)
		body.add_child(area)
		add_child(body)
		_dynamic_hole_bodies.append(body)

func _create_barriers():
	for bar in _data.barriers:
		var bw = Game.w * bar.w
		var bh = Game.h * bar.h
		var body = StaticBody2D.new()
		body.position = Vector2(Game.w * bar.x + bw / 2.0, _fy(Game.h * bar.y + bh / 2.0))
		body.rotation = deg_to_rad(-bar.rotation)
		var coll = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(bw, bh)
		coll.shape = shape
		body.add_child(coll)
		add_child(body)

func _create_rotating_platforms():
	if _data.rotating_platforms.is_empty():
		return
	_accent_platform_tex = ProceduralAssets.pixel_bar_texture(Color(0.8, 0.4, 0.2, 1.0))
	_default_platform_tex = ProceduralAssets.pixel_bar_texture(Game.barrier_color)
	for rp in _data.rotating_platforms:
		var rw = Game.w * rp.w
		var rh = Game.h * rp.h
		var body = AnimatableBody2D.new()
		body.position = Vector2(Game.w * rp.x, _fy(Game.h * rp.y))
		var coll = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(rw, rh)
		coll.shape = shape
		body.add_child(coll)
		var mat = PhysicsMaterial.new()
		mat.friction = 0.6
		mat.bounce = 0.4
		body.physics_material_override = mat
		add_child(body)
		_rotating_bodies.append(body)
		_rotating_data.append(rp)

func _setup_pause():
	_pause_size = Game.w * 0.07
	_pause_x = Game.w - _pause_size - Game.w * 0.05
	_pause_y = Game.h * 0.03
	_pause_icon_tex = ProceduralAssets.pause_icon(roundi(_pause_size), Color.WHITE)
	_pause_options = [
		I18N.get_s("pause_continue"),
		I18N.get_s("pause_restart"),
		I18N.get_s("pause_levels"),
		I18N.get_s("pause_menu")
	]
	var max_w = 0.0
	for s in _pause_options:
		max_w = maxf(max_w, Game.game_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, _pause_font_size).x)
	max_w = maxf(max_w, Game.game_font.get_string_size(I18N.get_s("pause_title"), HORIZONTAL_ALIGNMENT_LEFT, -1, _pause_font_size).x)
	var pad_h = Game.w * 0.08
	var pad_v = Game.w * 0.08
	var radius = Game.w * 0.05
	_panel_w = minf(max_w + pad_h * 2, Game.w * 0.92)
	var lh = _pause_font_size
	var n = _pause_options.size()
	var center_y = Game.h / 2.0
	var title_pos = center_y - lh * 3.3
	var last_pos = center_y - lh * 1.5 + (n - 1) * lh * 1.8
	_pause_shift = center_y - (title_pos + last_pos) / 2.0
	_panel_h = minf(last_pos - title_pos + lh + pad_v * 2, Game.h * 0.85)
	_panel_x = (Game.w - _panel_w) / 2.0
	_panel_y = center_y - _panel_h / 2.0
	_panel_tex = ProceduralAssets.round_rect_gradient(roundi(_panel_w), roundi(_panel_h), radius, Color(0.22, 0.18, 0.32, 0.40), Color(0.08, 0.06, 0.14, 0.60))
	_panel_shadow_tex = ProceduralAssets.round_rect(roundi(_panel_w), roundi(_panel_h), radius, Color(0, 0, 0, 0.25))

func _setup_debug():
	_dbg_w = Game.w * 0.2
	_dbg_h = Game.h * 0.045
	_dbg_x = Game.w * 0.05
	_dbg_y = _fy(Game.h * 0.86)
	_dbg_tex = ProceduralAssets.solid(Color(0, 0, 0, 0.5))

func _build_hints():
	_show_hints = _data.show_hints
	if not _show_hints:
		return
	_hint_right_a = load("res://assets/Gestures/training_right_74.png")
	_hint_right_b = load("res://assets/Gestures/training_right_64.png")
	_hint_left_a = load("res://assets/Gestures/training_left_74.png")
	_hint_left_b = load("res://assets/Gestures/training_left_64.png")

func _physics_process(delta):
	if _exiting:
		return

	if Game.paused:
		if _pause_press_timer > 0:
			_pause_press_timer -= delta
			if _pause_press_timer <= 0:
				_pause_press_timer = 0
				_execute_pause_action(_pressed_pause_index)
				_pressed_pause_index = -1
		else:
			_handle_pause_input()
		queue_redraw()
		return

	if not Game.failed or Game.win:
		_exiting = true
		if Game.win:
			Game.finish_seconds = Game.minutes * 60 + Game.seconds
			Input.vibrate_handheld(60)
		else:
			Input.vibrate_handheld(120)
		ResultScreen.set_result_context(_level, not Game.failed, Game.win, Game.the_end)
		Game.show_result(_level)
		return

	if Input.is_action_just_pressed("ui_click"):
		var pos = _touch_pos()
		if pos.x >= _pause_x and pos.x <= _pause_x + _pause_size and pos.y >= _pause_y and pos.y <= _pause_y + _pause_size:
			Game.paused = true
			queue_redraw()
			return
		if OS.is_debug_build() and pos.x >= _dbg_x and pos.x <= _dbg_x + _dbg_w and pos.y >= _dbg_y and pos.y <= _dbg_y + _dbg_h:
			Game.win = true
			return

	_handle_tilt()
	_sync_board_physics()
	_update_dynamic_holes()
	_update_rotating_platforms()

	if _ball:
		var ball_y = _ball.position.y
		if ball_y > Game.h * 0.99:
			Game.failed = false
		if ball_y < Game.h * 0.02:
			Game.win = true

	if _fade > 0:
		_fade -= delta / 0.25
	queue_redraw()

func _handle_tilt():
	if Game.consume_touch:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			return
		Game.consume_touch = false
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	var pos = _touch_pos()
	if pos.y < Game.h * 0.1:
		return
	_hint_tilted = true
	var tx = pos.x
	if tx < Game.w / 2.0:
		_tilt_side = -1
		if _i_right == 0:
			_i_right = _i_left
		_i_right -= 0.7
		if _i_right < -28:
			_i_right = -28
		_i_left = 0
	else:
		_tilt_side = 1
		if _i_left == 0:
			_i_left = _i_right
		_i_left += 0.7
		if _i_left > 28:
			_i_left = 28
		_i_right = 0

func _get_origin_for_side(side: int) -> Vector2:
	if side == 1:
		return Vector2(0.0, 0.0)
	elif side == -1:
		return Vector2(_board_w, 0.0)
	else:
		return Vector2(_board_w / 2.0, _board_h / 2.0)

func _sync_board_physics():
	var angle = -(_i_left + _i_right)
	var pivot_side = _tilt_side
	if pivot_side != _last_pivot_side:
		_recompute_base_for_new_pivot(pivot_side, angle)
		_last_pivot_side = pivot_side
	var origin = _get_origin_for_side(pivot_side)
	var pivot_x = _board_base_x + origin.x
	var pivot_y = _board_base_y + origin.y
	var rad = deg_to_rad(angle)
	var dx = -origin.x
	var dy = -origin.y
	var new_dx = dx * cos(rad) - dy * sin(rad)
	var new_dy = dx * sin(rad) + dy * cos(rad)
	_board.position = Vector2(pivot_x + new_dx, pivot_y + new_dy)
	_board.rotation = rad

func _recompute_base_for_new_pivot(new_side: int, angle: float):
	var old_origin = _get_origin_for_side(_last_pivot_side)
	var old_pivot_x = _board_base_x + old_origin.x
	var old_pivot_y = _board_base_y + old_origin.y
	var rad = deg_to_rad(angle)
	var cx_off = _board_w / 2.0 - old_origin.x
	var cy_off = _board_h / 2.0 - old_origin.y
	var center_x = old_pivot_x + cx_off * cos(rad) - cy_off * sin(rad)
	var center_y = old_pivot_y + cx_off * sin(rad) + cy_off * cos(rad)
	var new_origin = _get_origin_for_side(new_side)
	var ncx_off = _board_w / 2.0 - new_origin.x
	var ncy_off = _board_h / 2.0 - new_origin.y
	var ncx_rot = ncx_off * cos(rad) - ncy_off * sin(rad)
	var ncy_rot = ncx_off * sin(rad) + ncy_off * cos(rad)
	_board_base_x = center_x - ncx_rot - new_origin.x
	_board_base_y = center_y - ncy_rot - new_origin.y

func _update_dynamic_holes():
	_dyn_accum += get_physics_process_delta_time()
	while _dyn_accum >= Game.dyn_interval and not _dynamic_hole_bodies.is_empty():
		_dyn_accum -= Game.dyn_interval
		if Game.box_hole_din_sign:
			Game.box_din += 1
		else:
			Game.box_din -= 1
	for i in range(_dynamic_hole_bodies.size()):
		var dh = _data.dynamic_holes[i]
		var x = Game.w * dh.x + dh.xDin * Game.box_din
		var y = _fy(Game.h * dh.y) + dh.yDin * Game.box_din
		_dynamic_hole_bodies[i].position = Vector2(x, y)
	if not _dynamic_hole_bodies.is_empty() and not _data.dynamic_control.is_empty():
		var ctrl_x = _dynamic_hole_bodies[0].position.x
		var ctrl = _data.dynamic_control
		if not ctrl.inverted:
			if ctrl_x >= ctrl.upperX * Game.w:
				Game.box_hole_din_sign = false
			elif ctrl_x <= ctrl.lowerX * Game.w:
				Game.box_hole_din_sign = true
		else:
			if ctrl_x <= ctrl.lowerX * Game.w:
				Game.box_hole_din_sign = false
			elif ctrl_x >= ctrl.upperX * Game.w:
				Game.box_hole_din_sign = true

func _update_rotating_platforms():
	var delta = get_physics_process_delta_time()
	for i in range(_rotating_bodies.size()):
		var angle_delta = deg_to_rad(-_rotating_data[i].rotationSpeed) * delta
		_rotating_bodies[i].rotation += angle_delta

func _handle_pause_input():
	if not Input.is_action_just_pressed("ui_click"):
		return
	var pos = _touch_pos()
	var band_w = Game.w * 0.6
	var band_h = _pause_font_size * 1.6
	for i in range(_pause_options.size()):
		var cy = _pause_option_y(i)
		if pos.x >= Game.w / 2.0 - band_w / 2.0 and pos.x <= Game.w / 2.0 + band_w / 2.0 and pos.y >= cy - band_h / 2.0 and pos.y <= cy + band_h / 2.0:
			_pressed_pause_index = i
			_pause_press_timer = 0.08
			return

func _draw():
	draw_texture_rect(Game.current_bg_tex, Rect2(0, 0, Game.w, Game.h), false)
	_draw_hints()
	_draw_static_holes()
	_draw_dynamic_holes()
	_draw_barriers()
	_draw_rotating_platforms()
	_draw_ball()
	_draw_board()
	_draw_hud()
	_draw_pause_overlay()
	if _fade > 0:
		draw_rect(Rect2(0, 0, Game.w, Game.h), Color(0, 0, 0, _fade))

func _draw_board():
	var angle = -(_i_left + _i_right)
	var half_w = _board_w / 2.0
	var half_h = _board_h / 2.0
	var origin = _get_origin_for_side(_tilt_side)
	var pivot_x = _board_base_x + origin.x
	var pivot_y = _board_base_y + origin.y
	var rad = deg_to_rad(angle)
	var dx = -origin.x
	var dy = -origin.y
	var new_dx = dx * cos(rad) - dy * sin(rad)
	var new_dy = dx * sin(rad) + dy * cos(rad)
	var new_base_x = pivot_x + new_dx
	var new_base_y = pivot_y + new_dy
	var rcx = half_w * cos(rad) - half_h * sin(rad)
	var rcy = half_w * sin(rad) + half_h * cos(rad)
	var world_cx = new_base_x + rcx
	var world_cy = new_base_y + rcy
	draw_set_transform(Vector2(world_cx, world_cy), deg_to_rad(angle), Vector2.ONE)
	draw_texture_rect(Game.board_tex, Rect2(-half_w, -half_h, _board_w, _board_h), false)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _draw_ball():
	if not _ball:
		return
	var p = _ball.position
	draw_texture(Game.ball_tex, Vector2(p.x - _ball_diam / 2.0, p.y - _ball_diam / 2.0))

func _draw_static_holes():
	var hh = _hole_diam / 2.0
	for h in _data.holes:
		draw_texture(Game.hole_tex, Vector2(Game.w * h.x - hh, _fy(Game.h * h.y) - hh))

func _draw_hints():
	if not _show_hints or _hint_tilted:
		return
	var base_y = _fy(Game.h * 0.1)
	if Game.gest % 2 == 0:
		_draw_hint(_hint_right_b, Game.w * 0.8, base_y)
		_draw_hint(_hint_left_a, Game.w * 0.2 - _hint_left_a.get_width(), base_y)
	else:
		_draw_hint(_hint_right_a, Game.w * 0.8, base_y)
		_draw_hint(_hint_left_b, Game.w * 0.2 - _hint_left_b.get_width(), base_y)

func _draw_hint(tex: Texture2D, x: float, base_y: float):
	draw_texture(tex, Vector2(x, base_y - tex.get_height()))

func _draw_dynamic_holes():
	var hh = _hole_diam / 2.0
	for body in _dynamic_hole_bodies:
		var p = body.position
		draw_texture(Game.hole_tex, Vector2(p.x - hh, p.y - hh))

func _draw_barriers():
	for bar in _data.barriers:
		var bw = Game.w * bar.w
		var bh = Game.h * bar.h
		var cx = Game.w * bar.x + bw / 2.0
		var cy = _fy(Game.h * bar.y + bh / 2.0)
		draw_set_transform(Vector2(cx, cy), deg_to_rad(-bar.rotation), Vector2.ONE)
		draw_texture_rect(Game.barrier_tex, Rect2(-bw / 2.0, -bh / 2.0, bw, bh), false)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _draw_rotating_platforms():
	for i in range(_rotating_bodies.size()):
		var body = _rotating_bodies[i]
		var rp = _rotating_data[i]
		var rw = Game.w * rp.w
		var rh = Game.h * rp.h
		var tex = _accent_platform_tex if rp.color == "accent" else _default_platform_tex
		draw_set_transform(body.position, body.rotation, Vector2.ONE)
		draw_texture_rect(tex, Rect2(-rw / 2.0, -rh / 2.0, rw, rh), false)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _draw_hud():
	draw_string(Game.game_font, Vector2(Game.w * 0.05, Game.h * 0.04), Game.timer_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _timer_size, Color.WHITE)
	draw_texture(_pause_icon_tex, Vector2(_pause_x, _pause_y))
	if OS.is_debug_build():
		draw_texture_rect(_dbg_tex, Rect2(_dbg_x, _dbg_y, _dbg_w, _dbg_h), false)
		var ws = Game.game_font.get_string_size("WIN", HORIZONTAL_ALIGNMENT_LEFT, -1, _timer_size)
		var ascent = Game.game_font.get_ascent(_timer_size)
		var descent = Game.game_font.get_descent(_timer_size)
		draw_string(Game.game_font, Vector2(_dbg_x + _dbg_w / 2.0 - ws.x / 2.0, _dbg_y + _dbg_h / 2.0 + (ascent - descent) / 2.0), "WIN", HORIZONTAL_ALIGNMENT_LEFT, -1, _timer_size, Color.WHITE)

func _draw_pause_overlay():
	if not Game.paused:
		return
	draw_rect(Rect2(0, 0, Game.w, Game.h), Color(0, 0, 0, 0.30))
	var soff = Game.w * 0.007
	draw_texture(_panel_shadow_tex, Vector2(_panel_x + soff, _panel_y + soff))
	draw_texture(_panel_tex, Vector2(_panel_x, _panel_y))
	_draw_pause_text(I18N.get_s("pause_title"), _pause_option_y(-1), false)
	for i in range(_pause_options.size()):
		_draw_pause_text(_pause_options[i], _pause_option_y(i), i == _pressed_pause_index)

func _pause_option_y(i: int) -> float:
	return Game.h / 2.0 - _pause_font_size * 1.5 + _pause_shift + i * _pause_font_size * 1.8

func _draw_pause_text(text: String, y: float, pressed: bool):
	var ts = Game.game_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _pause_font_size)
	var x = Game.w / 2.0 - ts.x / 2.0
	var o = maxf(1.0, Game.w * 0.004)
	if pressed:
		draw_string(Game.game_font, Vector2(x + o * 0.5, y - o * 0.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _pause_font_size, Color(0, 0, 0, 0.6))
		draw_string(Game.game_font, Vector2(x + o, y - o), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _pause_font_size, Color.WHITE)
	else:
		draw_string(Game.game_font, Vector2(x + o, y - o), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _pause_font_size, Color(0, 0, 0, 0.5))
		draw_string(Game.game_font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _pause_font_size, Color.WHITE)

func _execute_pause_action(index: int):
	if index == 0:
		Game.paused = false
		Game.consume_touch = true
	elif index == 1:
		PlayerPrefs.set_pref("_current_level", _level)
		Game.go_to_level(_level)
	elif index == 2:
		Game.show_level_select()
	elif index == 3:
		Game.paused = false
		Game.show_menu()

func _touch_pos() -> Vector2:
	return get_global_mouse_position()
