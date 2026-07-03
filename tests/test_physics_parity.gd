extends GutTest

# F2 regression guard (ball gravity parity libGDX -> Godot).
#
# The original libGDX game steps Box2D by `time_step = 0.6` SIM-seconds per
# rendered frame (Intro.java:410, LevelScreen.java:387). At 60 fps that is
# 36x real-time, so gravity `g` in sim feels like g * 36^2 in real time.
#
# Therefore the Godot port (which steps physics in real time) must set
#   default_gravity * gravity_scale  ~=  original_g * (fps * time_step)^2
#                                 ~=  2 * 36^2  = 2592 px/s^2
#
# This test would have turned red when the gravity was wrongly "fixed" to 2.

const _ORIGINAL_G = 2.0          # Box2D World gravity, px/sim_s^2
const _TIME_STEP = 0.6           # sim-seconds advanced per render frame
const _FPS = 60.0
const _PORT_SCALE_FACTOR = 1.3   # gravity_scale at reference height 640 (level_screen.gd:99)

func _original_effective_realtime_gravity() -> float:
	var sim_speed = _FPS * _TIME_STEP  # 36x
	return _ORIGINAL_G * sim_speed * sim_speed

func test_port_gravity_matches_original_realtime_feel():
	var original = _original_effective_realtime_gravity()  # ~2592
	var port_default = ProjectSettings.get_setting("physics/2d/default_gravity")
	var port_effective = float(port_default) * _PORT_SCALE_FACTOR
	assert_almost_eq(port_effective, original, original * 0.10,
		"port effective gravity (~%.0f) must match original realtime feel (~%.0f) within 10%%" % [port_effective, original])

func test_port_default_gravity_is_in_thousands_not_units():
	# Guards against the exact mistake that froze the ball: setting this to 2.
	var g = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	assert_gt(g, 100.0, "default_gravity must be the real-time value (~2000), not the sim constant 2")
