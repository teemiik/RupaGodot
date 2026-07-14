extends Control

var _play_tex: Texture2D
var _play_size: float
var _play_x: float
var _play_y: float
var _title_size: int
var _option_size: int
var _pressed_index: int = -1
var _press_timer= 0.0
var _fade= 0.7

func _fy(y: float) -> float:
	return Game.h - y

func _ready():
	_play_tex = load("res://assets/Menu/play.png")
	_play_size = Game.w * 0.24
	_play_x = (Game.w - _play_size) / 2.0
	_play_y = _fy(Game.h * 0.56) - _play_size / 2.0
	_title_size = roundi(Game.size_text_result * 1.6)
	_option_size = Game.size_text_result

func _process(delta):
	queue_redraw()
	if _press_timer > 0:
		_press_timer -= delta
		if _press_timer <= 0:
			_press_timer = 0
			_execute_action(_pressed_index)
			_pressed_index = -1
	if _fade > 0:
		_fade -= delta / 0.25
	if _press_timer <= 0 and Input.is_action_just_pressed("ui_click"):
		var pos= _touch_pos()
		if pos.x >= _play_x and pos.x <= _play_x + _play_size and pos.y >= _play_y and pos.y <= _play_y + _play_size:
			_pressed_index = 0
			_press_timer = 0.08
		elif _hit_text(pos, _fy(Game.h * 0.34)):
			_pressed_index = 1
			_press_timer = 0.08
		elif _hit_text(pos, _fy(Game.h * 0.23)):
			_pressed_index = 2
			_press_timer = 0.08

func _draw():
	draw_texture_rect(Game.menu_bg_tex, Rect2(0, 0, Game.w, Game.h), false)
	_draw_shadowed(I18N.get_s("app_name"), _fy(Game.h * 0.82), _title_size, false)
	var ps= _play_size * (0.92 if _pressed_index == 0 else 1.0)
	var px= _play_x + (_play_size - ps) / 2.0
	var py= _play_y + (_play_size - ps) / 2.0
	draw_texture_rect(_play_tex, Rect2(px, py, ps, ps), false)
	_draw_shadowed(I18N.get_s("menu_levels"), _fy(Game.h * 0.34), _option_size, _pressed_index == 1)
	_draw_shadowed(I18N.get_s("menu_exit"), _fy(Game.h * 0.23), _option_size, _pressed_index == 2)
	if _fade > 0:
		draw_rect(Rect2(0, 0, Game.w, Game.h), Color(0, 0, 0, _fade))

func _draw_shadowed(text: String, y: float, font_size: int, pressed: bool):
	var ts= Game.game_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var x= (Game.w - ts.x) / 2.0
	var o= maxf(1.0, Game.w * 0.004)
	if pressed:
		# depth press (scale inward) like level tiles, instead of side offset
		var s = 0.92
		var ascent = Game.game_font.get_ascent(font_size)
		var descent = Game.game_font.get_descent(font_size)
		var cx = x + ts.x / 2.0
		var cy = y - (ascent - descent) / 2.0
		draw_set_transform(Vector2(cx, cy), 0.0, Vector2(s, s))
		draw_string(Game.game_font, Vector2(-ts.x / 2.0, (ascent - descent) / 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	else:
		draw_string(Game.game_font, Vector2(x + o, y - o), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.5))
		draw_string(Game.game_font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

func _hit_text(pos: Vector2, y: float) -> bool:
	var band_w= Game.w * 0.8
	var band_h= _option_size * 1.6
	return pos.x >= Game.w / 2.0 - band_w / 2.0 and pos.x <= Game.w / 2.0 + band_w / 2.0 and pos.y >= y - band_h / 2.0 and pos.y <= y + band_h / 2.0

func _touch_pos() -> Vector2:
	return get_global_mouse_position()

func _execute_action(index: int):
	if index == 0:
		PlayerPrefs.set_pref("_current_level", 1)
		Game.go_to_level(1)
	elif index == 1:
		Game.show_level_select()
	elif index == 2:
		get_tree().quit()
