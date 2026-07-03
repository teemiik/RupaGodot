extends Node

var w: float
var h: float
var ui_scale: float
var board_width: float
var board_height: float
var size_text: int
var size_text_result: int
var speed_hole: int
var time_step= 0.6
var dyn_interval: float

var failed: bool = true
var win: bool = false
var the_end: bool = false
var paused: bool = false
var consume_touch: bool = false
var box_din: int = 0
var box_hole_din_sign: bool = true
var minutes = 0
var seconds = 0
var finish_seconds: int = 0
var gest: int = 0
var timer_text: String = "00:00"

var ball_tex: Texture2D
var hole_tex: Texture2D
var board_tex: Texture2D
var barrier_tex: Texture2D
var current_bg_tex: Texture2D
var menu_bg_tex: Texture2D

var ball_color = Color(0.80, 0.80, 0.83, 1.0)
var hole_color = Color(0.10, 0.10, 0.12, 1.0)
var board_color = Color(0.62, 0.30, 0.28, 1.0)
var barrier_color = Color(0.12, 0.12, 0.13, 1.0)

var bg_warm_top = Color(0.80, 0.76, 0.68, 1.0)
var bg_warm_bottom = Color(0.52, 0.13, 0.18, 1.0)
var bg_warm_glow = Color(0.96, 0.90, 0.78, 1.0)

var game_font: FontFile
var _timer_accum= 0.0
var _gest_accum= 0.0
var _dyn_accum= 0.0

func _ready():
	I18N.init()
	w = get_viewport().get_visible_rect().size.x
	h = get_viewport().get_visible_rect().size.y
	_compute_sizes()
	_generate_base_assets()
	_load_font()

func _compute_sizes():
	board_width = w - w * 0.25
	board_height = w * 0.04
	size_text = clampi(roundi(w * 0.045), 12, 60)
	size_text_result = mini(90, roundi(size_text * 1.5))
	speed_hole = clampi(roundi(11000.0 / w), 5, 14)
	dyn_interval = speed_hole / 1000.0
	ui_scale = w / 1080.0

func _generate_base_assets():
	var ball_diam= roundi(w * 0.06)
	ball_tex = ProceduralAssets.ball_tex(ball_diam, ball_color)
	var hole_diam= roundi(w * 0.0695)
	hole_tex = ProceduralAssets.hole_tex(hole_diam, hole_color)
	barrier_tex = ProceduralAssets.solid(barrier_color)
	menu_bg_tex = ProceduralAssets.background_pixel(bg_warm_top, bg_warm_bottom, bg_warm_glow)

func _load_font():
	game_font = load("res://assets/fonts/10771.ttf")

func build_level_theme(level: int):
	var hue= fmod((level - 1) * 47.0, 360.0)
	var top= Color.from_hsv((hue / 360.0), 0.30, 0.82, 1.0)
	var bottom= Color.from_hsv((hue / 360.0), 0.65, 0.38, 1.0)
	var glow= Color.from_hsv((hue / 360.0), 0.18, 0.95, 1.0)
	current_bg_tex = ProceduralAssets.background_pixel(top, bottom, glow)
	var board_light= Color.from_hsv((hue / 360.0), 0.40, 0.80, 1.0)
	var board_dark= Color.from_hsv((hue / 360.0), 0.58, 0.52, 1.0)
	var bw= maxi(2, roundi(board_width))
	var bh= maxi(2, roundi(board_height))
	board_tex = ProceduralAssets.round_rect_gradient(bw, bh, bh / 2.0, board_light, board_dark)

func go_to_level(level: int):
	PlayerPrefs.set_pref("_current_level", level)
	_reset_state()
	build_level_theme(level)
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func show_menu():
	paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func show_level_select():
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func show_result(_level: int):
	get_tree().change_scene_to_file("res://scenes/result.tscn")

func _reset_state():
	box_din = 0
	box_hole_din_sign = true
	failed = true
	win = false
	the_end = false
	paused = false
	consume_touch = true
	minutes = 0
	seconds = 0
	timer_text = "00:00"
	gest = 0
	_timer_accum = 0.0
	_gest_accum = 0.0
	_dyn_accum = 0.0

func _process(delta):
	if paused:
		return
	_timer_accum += delta
	while _timer_accum >= 1.0:
		_timer_accum -= 1.0
		seconds += 1
		if seconds >= 60:
			minutes += 1
			seconds = 0
		timer_text = str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)
	_gest_accum += delta
	while _gest_accum >= 0.5:
		_gest_accum -= 0.5
		gest += 1
	if win or the_end:
		return
