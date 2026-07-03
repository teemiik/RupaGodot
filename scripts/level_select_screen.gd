extends Control

var _count: int
var _cols: int = 3
var _tile: float
var _gap_x: float
var _gap_y: float
var _start_x: float
var _base_top_y: float
var _title_y: float
var _arrow_y: float
var _text_size: int
var _number_size: int
var _tile_tex: Texture2D
var _check_tex: Texture2D
var _check_bg_tex: Texture2D
var _shadow_tex: Texture2D
var _back_arrow_tex: Texture2D
var _fade= 0.7
var _scroll_y= 0.0
var _max_scroll= 0.0
var _last_pointer_y= 0.0
var _dragging: bool = false
var _drag_accum= 0.0
var _pressed_level: int = -1
var _press_timer= 0.0

func _fy(y: float) -> float:
	return Game.h - y

func _ready():
	_count = maxi(1, LevelLoader.count())
	_text_size = Game.size_text
	_number_size = Game.size_text_result
	_tile = Game.w * 0.17
	_gap_x = _tile * 0.5
	_gap_y = _tile * 0.7
	var rows = (_count + _cols - 1) / _cols
	var arrow_size= roundi(Game.w * 0.07)
	_arrow_y = _fy(Game.h * 0.88)
	var arrow_center_y = _arrow_y + arrow_size / 2.0
	_title_y = arrow_center_y + _text_size / 2.0
	var grid_w= _cols * _tile + (_cols - 1) * _gap_x
	var grid_h= rows * _tile + (rows - 1) * _gap_y
	_start_x = (Game.w - grid_w) / 2.0
	var centered_top = (Game.h - grid_h) / 2.0
	var min_top = _title_y + _text_size + _text_size * 0.5 + _tile * 0.5
	_base_top_y = maxf(centered_top, min_top)
	var last_row_y = _tile_y(rows - 1)
	_max_scroll = maxf(0, last_row_y + _tile + _tile * 0.3 - Game.h)
	_tile_tex = ProceduralAssets.gradient_circle(roundi(_tile), Color(0.32, 0.28, 0.42, 1), Color(0.08, 0.06, 0.14, 1))
	_check_tex = ProceduralAssets.check_mark(roundi(_tile * 0.17), Color.WHITE)
	_check_bg_tex = ProceduralAssets.gradient_circle(roundi(_tile * 0.26), Color(0.32, 0.62, 0.38, 1), Color(0.12, 0.32, 0.18, 1))
	_shadow_tex = ProceduralAssets.gradient_circle(roundi(_tile), Color(0, 0, 0, 0.25), Color(0, 0, 0, 0.25))
	_back_arrow_tex = ProceduralAssets.back_arrow(arrow_size, Color.WHITE)

func _process(delta):
	if _press_timer > 0:
		_press_timer -= delta
		if _press_timer <= 0:
			_press_timer = 0
			if _pressed_level > 0:
				Game.go_to_level(_pressed_level)
				_pressed_level = -1
				return
			_pressed_level = -1
	if _fade > 0:
		_fade -= delta / 0.25
	queue_redraw()

func _draw():
	draw_texture_rect(Game.menu_bg_tex, Rect2(0, 0, Game.w, Game.h), false)
	var title_ts = Game.game_font.get_string_size(I18N.get_s("level_select_title"), HORIZONTAL_ALIGNMENT_LEFT, -1, _text_size)
	draw_string(Game.game_font, Vector2(Game.w / 2.0 - title_ts.x / 2.0, _title_y - _scroll_y), I18N.get_s("level_select_title"), HORIZONTAL_ALIGNMENT_LEFT, -1, _text_size, Color.WHITE)
	var soff= Game.w * 0.007
	for i in range(_count):
		var col= i % _cols
		var row= i / _cols
		var bx= _tile_x(col)
		var by= _tile_y(row) - _scroll_y
		var ts0 = 1.0 if not (_press_timer > 0 and _pressed_level == i + 1) else 0.92
		draw_set_transform(Vector2(bx + _tile / 2.0, by + _tile / 2.0), 0.0, Vector2(ts0, ts0))
		draw_texture(_shadow_tex, Vector2(soff - _tile / 2.0, soff - _tile / 2.0))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in range(_count):
		var col= i % _cols
		var row= i / _cols
		var bx= _tile_x(col)
		var by= _tile_y(row) - _scroll_y
		var level_num= i + 1
		var ts = 1.0 if not (_press_timer > 0 and _pressed_level == level_num) else 0.92
		draw_set_transform(Vector2(bx + _tile / 2.0, by + _tile / 2.0), 0.0, Vector2(ts, ts))
		draw_texture(_tile_tex, Vector2(-_tile / 2.0, -_tile / 2.0))
		var ns= Game.game_font.get_string_size(str(level_num), HORIZONTAL_ALIGNMENT_LEFT, -1, _number_size)
		var ascent = Game.game_font.get_ascent(_number_size)
		var descent = Game.game_font.get_descent(_number_size)
		draw_string(Game.game_font, Vector2(-ns.x / 2.0, (ascent - descent) / 2.0), str(level_num), HORIZONTAL_ALIGNMENT_LEFT, -1, _number_size, Color.WHITE)
		if Progress.is_completed(level_num):
			var badge= _tile * 0.26
			var chk= _tile * 0.17
			draw_texture(_check_bg_tex, Vector2(_tile * 0.32 - badge / 2.0, -_tile * 0.32 - badge / 2.0))
			draw_texture(_check_tex, Vector2(_tile * 0.32 - chk / 2.0, -_tile * 0.32 - chk / 2.0))
			var t= Progress.format_time(Progress.best_time(level_num))
			var ts2= Game.game_font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, _text_size)
			draw_string(Game.game_font, Vector2(-ts2.x / 2.0, _tile * 0.52 + ts2.y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, _text_size, Color.WHITE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var arrow_size= roundi(Game.w * 0.07)
	draw_texture(_back_arrow_tex, Vector2(Game.w * 0.05, _arrow_y))
	if _fade > 0:
		draw_rect(Rect2(0, 0, Game.w, Game.h), Color(0, 0, 0, _fade))

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos= event.position
		var arrow_size= roundi(Game.w * 0.07)
		if pos.x >= Game.w * 0.05 and pos.x <= Game.w * 0.05 + arrow_size and pos.y >= _arrow_y and pos.y <= _arrow_y + arrow_size:
			Game.show_menu()
			return
		if _press_timer <= 0 and _drag_accum < _tile * 0.3:
			for i in range(_count):
				var col= i % _cols
				var row= i / _cols
				var bx= _tile_x(col)
				var by= _tile_y(row) - _scroll_y
				if pos.x >= bx and pos.x <= bx + _tile and pos.y >= by and pos.y <= by + _tile:
					_pressed_level = i + 1
					_press_timer = 0.08
					break
	elif event is InputEventMouseButton and not event.pressed:
		_dragging = false
		_drag_accum = 0.0
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_LEFT:
			if not _dragging:
				if event.position.y > _arrow_y:
					_dragging = true
					_last_pointer_y = event.position.y
					_drag_accum = 0.0
			else:
				var dy = event.position.y - _last_pointer_y
				_drag_accum += absf(dy)
				_scroll_y = clampf(_scroll_y - dy, 0, _max_scroll)
				_last_pointer_y = event.position.y

func _tile_x(col: int) -> float:
	return _start_x + col * (_tile + _gap_x)

func _tile_y(row: int) -> float:
	return _base_top_y + row * (_tile + _gap_y)
