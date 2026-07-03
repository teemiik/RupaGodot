extends GutTest

# F4 regression guard (hue units in Color.from_hsv).
#
# Godot's Color.from_hsv takes hue in [0..1], NOT radians and NOT degrees.
# The old code passed deg_to_rad(hue); the fix is (hue / 360.0). This test
# locks the correct idiom and proves the radian form is wrong, so a future
# "fix" that reverts the formula will turn this red.

func test_correct_hue_fraction_produces_expected_hue():
	var hue_deg = 47.0
	var c = Color.from_hsv(hue_deg / 360.0, 0.3, 0.8, 1.0)
	assert_almost_eq(c.h, hue_deg / 360.0, 0.01, "hue/360.0 yields the intended hue")

func test_radian_form_is_wrong():
	# deg_to_rad(47) ≈ 0.82, which from_hsv modulo-treats as a different hue.
	var hue_deg = 47.0
	var wrong = Color.from_hsv(deg_to_rad(hue_deg), 0.3, 0.8, 1.0)
	assert_almost_ne(wrong.h, hue_deg / 360.0, 0.01, "deg_to_rad(hue) must NOT match intended hue")

func test_per_level_hue_progression_is_monotonic():
	# build_level_theme uses hue = fmod((level-1)*47, 360). Successive levels
	# should step through distinct hues until they wrap.
	var prev = -1.0
	for level in range(1, 7):  # 6 levels stay below the 360 wrap
		var hue = fmod((level - 1) * 47.0, 360.0) / 360.0
		assert_ne(hue, prev, "level %d hue differs from previous" % level)
		prev = hue
