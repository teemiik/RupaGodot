extends GutTest

# ProceduralAssets clamps small sizes and never returns null.
func test_circle_clamps_below_minimum():
	var t = ProceduralAssets.circle(1, Color.WHITE)
	assert_not_null(t)
	assert_eq(t.get_width(), 2)
	assert_eq(t.get_height(), 2)

func test_solid_returns_texture():
	var t = ProceduralAssets.solid(Color.RED)
	assert_not_null(t)

func test_ball_and_hole_textures_have_requested_size():
	var b = ProceduralAssets.ball_tex(12, Color(0.8, 0.8, 0.83))
	var h = ProceduralAssets.hole_tex(12, Color.BLACK)
	assert_eq(b.get_width(), 12)
	assert_eq(h.get_width(), 12)

func test_pause_icon_clamps_below_minimum():
	var p = ProceduralAssets.pause_icon(1, Color.WHITE)
	assert_gte(p.get_width(), 4)
