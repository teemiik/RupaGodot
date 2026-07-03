class_name ResultScreen
extends Control

static var _level: int
var _lost: bool
var _won: bool
var _the_end: bool

var _title_size: int
var _option_size: int
var _info_size: int
var _particle_tex: Texture2D
var _panel_tex: Texture2D
var _panel_shadow_tex: Texture2D
var _panel_w: float
var _panel_h: float
var _panel_x: float
var _panel_y: float
var _fade= 0.7
var _one_render: bool = true
var _record_str: String = ""
var _time_str: String = ""
var _pressed_index: int = -1
var _press_timer= 0.0

var _px: Array = []
var _py: Array = []
var _vx: Array = []
var _vy: Array = []
var _life: Array = []
var _burst: int = 26

var _lose_ys: Array = []
var _win_ys: Array = []

static func set_result_context(level: int, lost: bool, won: bool, the_end: bool):
	ResultScreenData._level = level
	ResultScreenData._lost = lost
	ResultScreenData._won = won
	ResultScreenData._the_end = the_end

func _ready():
	_lost = ResultScreenData._lost
	_won = ResultScreenData._won
	_the_end = ResultScreenData._the_end
	_level = ResultScreenData._level
	_title_size = roundi(Game.size_text_result * 1.35)
	_option_size = Game.size_text_result
	_info_size = Game.size_text
	var p_size= roundi(Game.w * 0.018)
	_particle_tex = ProceduralAssets.circle(maxi(2, p_size), Color.WHITE)
	_px.resize(_burst); _py.resize(_burst)
	_vx.resize(_burst); _vy.resize(_burst)
	_life.resize(_burst)
	for i in range(_burst):
		_px[i] = 0.0; _py[i] = 0.0
		_vx[i] = 0.0; _vy[i] = 0.0
		_life[i] = 0.0
	_setup_panel()

func _setup_panel():
	var max_w= 0.0
	var all= [
		I18N.get_s("result_lose_title"), I18N.get_s("result_win_title"),
		I18N.get_s("result_restart"), I18N.get_s("result_levels"),
		I18N.get_s("result_menu"), I18N.get_s("result_next_level"),
		I18N.fmt("result_time", "00:00"), I18N.fmt("result_record", "00:00")
	]
	for t in all:
		max_w = maxf(max_w, Game.game_font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, _option_size).x)
		max_w = maxf(max_w, Game.game_font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, _title_size).x)
		max_w = maxf(max_w, Game.game_font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, _info_size).x)
	var pad_h= Game.w * 0.08
	var pad_v= Game.w * 0.08
	var radius= Game.w * 0.06
	_panel_w = minf(max_w + pad_h * 2, Game.w * 0.92)

	var center = Game.h / 2.0
	var title_h = _title_size
	var opt_h = _option_size
	var info_h = _info_size

	if _lost:
		var title_y = center - title_h * 1.5
		var retry_y = center + opt_h * 0.5
		var levels_y = center + opt_h * 2.5
		var menu_y = center + opt_h * 4.5
		var content_top = title_y
		var content_bot = menu_y
		var shift = center - (content_top + content_bot) / 2.0
		title_y += shift
		retry_y += shift
		levels_y += shift
		menu_y += shift
		_lose_ys = [title_y, retry_y, levels_y, menu_y]
		_panel_h = minf(content_bot - content_top + opt_h + pad_v * 2, Game.h * 0.92)
	elif _won:
		var title_y = center - title_h * 3.0
		var time_y = center - info_h * 1.5
		var record_y = center - info_h * 0.5
		var next_y = center + opt_h * 1.0
		var retry_y = center + opt_h * 2.5
		var levels_y = center + opt_h * 4.0
		var menu_y = center + opt_h * 5.5
		var content_top = title_y
		var content_bot = menu_y
		var shift = center - (content_top + content_bot) / 2.0
		title_y += shift
		time_y += shift
		record_y += shift
		next_y += shift
		retry_y += shift
		levels_y += shift
		menu_y += shift
		_win_ys = [title_y, time_y, record_y, next_y, retry_y, levels_y, menu_y]
		_panel_h = minf(content_bot - content_top + opt_h + pad_v * 2, Game.h * 0.92)
	else:
		_panel_h = minf(opt_h + pad_v * 2, Game.h * 0.92)

	_panel_x = (Game.w - _panel_w) / 2.0
	_panel_y = center - _panel_h / 2.0
	_panel_tex = ProceduralAssets.round_rect_gradient(roundi(_panel_w), roundi(_panel_h), radius, Color(0.32, 0.28, 0.42, 0.40), Color(0.10, 0.08, 0.16, 0.55))
	_panel_shadow_tex = ProceduralAssets.round_rect(roundi(_panel_w), roundi(_panel_h), radius, Color(0, 0, 0, 0.25))

func _process(delta):
	if _press_timer > 0:
		_press_timer -= delta
		if _press_timer <= 0:
			_press_timer = 0
			_execute_action(_pressed_index)
			_pressed_index = -1
	if _won and _one_render:
		_time_str = I18N.fmt("result_time", Progress.format_time(Game.finish_seconds))
		Progress.record_time(_level, Game.finish_seconds)
		_record_str = I18N.fmt("result_record", Progress.format_time(Progress.best_time(_level)))
		_spawn_burst()
		_one_render = false
	if _won:
		var g= Game.h * 0.9
		for i in range(_burst):
			if _life[i] <= 0: continue
			_life[i] -= delta
			_vy[i] += g * delta
			_px[i] += _vx[i] * delta
			_py[i] += _vy[i] * delta
	if _fade > 0:
		_fade -= delta / 0.25
	if _press_timer <= 0 and Input.is_action_just_pressed("ui_click"):
		var pos= get_global_mouse_position()
		var band_w= Game.w * 0.8
		var band_h= _option_size * 1.6
		var cx= Game.w / 2.0
		if _lost and _lose_ys.size() >= 4:
			for i2 in range(1, 4):
				var opt_y= _lose_ys[i2]
				var cy = opt_y - _option_size / 2.0
				if pos.x >= cx - band_w / 2 and pos.x <= cx + band_w / 2 and pos.y >= cy - band_h / 2 and pos.y <= cy + band_h / 2:
					_pressed_index = i2 - 1; _press_timer = 0.08; break
		elif _won and _win_ys.size() >= 7:
			for i2 in range(3, 7):
				var opt_y= _win_ys[i2]
				var cy = opt_y - _option_size / 2.0
				if pos.x >= cx - band_w / 2 and pos.x <= cx + band_w / 2 and pos.y >= cy - band_h / 2 and pos.y <= cy + band_h / 2:
					_pressed_index = i2 - 3; _press_timer = 0.08; break
	queue_redraw()

func _draw():
	draw_texture_rect(Game.current_bg_tex, Rect2(0, 0, Game.w, Game.h), false)
	var soff = Game.w * 0.007
	draw_texture(_panel_shadow_tex, Vector2(_panel_x + soff, _panel_y + soff))
	draw_texture(_panel_tex, Vector2(_panel_x, _panel_y))
	if _lost and _lose_ys.size() >= 4:
		_draw_centered(I18N.get_s("result_lose_title"), _lose_ys[0], _title_size, false)
		_draw_centered(I18N.get_s("result_restart"), _lose_ys[1], _option_size, _pressed_index == 0)
		_draw_centered(I18N.get_s("result_levels"), _lose_ys[2], _option_size, _pressed_index == 1)
		_draw_centered(I18N.get_s("result_menu"), _lose_ys[3], _option_size, _pressed_index == 2)
	elif _won and _win_ys.size() >= 7:
		_draw_centered(I18N.get_s("result_win_title"), _win_ys[0], _title_size, false)
		_draw_centered(_time_str, _win_ys[1], _info_size, false)
		_draw_centered(_record_str, _win_ys[2], _info_size, false)
		_draw_centered(I18N.get_s("result_next_level"), _win_ys[3], _option_size, _pressed_index == 0)
		_draw_centered(I18N.get_s("result_restart"), _win_ys[4], _option_size, _pressed_index == 1)
		_draw_centered(I18N.get_s("result_levels"), _win_ys[5], _option_size, _pressed_index == 2)
		_draw_centered(I18N.get_s("result_menu"), _win_ys[6], _option_size, _pressed_index == 3)
		var p_size= Game.w * 0.018
		for i in range(_burst):
			if _life[i] <= 0: continue
			var a= clampf(_life[i], 0, 1)
			draw_texture(_particle_tex, Vector2(_px[i] - p_size / 2, _py[i] - p_size / 2), Color(1, 1, 1, a))
	elif _the_end:
		_draw_centered(I18N.get_s("result_end_title"), Game.h / 2.0, _option_size, false)
	if _fade > 0:
		draw_rect(Rect2(0, 0, Game.w, Game.h), Color(0, 0, 0, _fade))

func _draw_centered(text: String, y: float, font_size: int, pressed: bool):
	var ts= Game.game_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var x= Game.w / 2.0 - ts.x / 2.0
	var o= maxf(1.0, Game.w * 0.004)
	if pressed:
		draw_string(Game.game_font, Vector2(x + o * 0.5, y - o * 0.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.6))
		draw_string(Game.game_font, Vector2(x + o, y - o), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	else:
		draw_string(Game.game_font, Vector2(x + o, y - o), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.5))
		draw_string(Game.game_font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

func _execute_action(index: int):
	if _lost:
		if index == 0: Game.go_to_level(_level)
		elif index == 1: Game.show_level_select()
		elif index == 2: Game.show_menu()
	elif _won:
		if index == 0:
			var next= _level + 1
			if next <= LevelLoader.count():
				PlayerPrefs.set_pref("_current_level", next)
				Game.go_to_level(next)
			else:
				Game.box_din = 0
				Game.win = false
				Game.the_end = true
				ResultScreenData._level = _level
				ResultScreenData._lost = false
				ResultScreenData._won = false
				ResultScreenData._the_end = true
				Game.show_result(_level)
		elif index == 1: Game.go_to_level(_level)
		elif index == 2: Game.show_level_select()
		elif index == 3: Game.show_menu()

func _spawn_burst():
	var cx= Game.w / 2.0
	var cy= Game.h * 0.38
	for i in range(_burst):
		var ang= randf() * PI * 2
		var spd= randf_range(Game.w * 0.25, Game.w * 0.7)
		_px[i] = cx; _py[i] = cy
		_vx[i] = cos(ang) * spd
		_vy[i] = -sin(ang) * spd - Game.h * 0.2
		_life[i] = randf_range(0.9, 1.5)

class ResultScreenData:
	static var _level: int
	static var _lost: bool
	static var _won: bool
	static var _the_end: bool
