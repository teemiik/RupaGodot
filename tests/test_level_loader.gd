extends GutTest

# Level loading must stay robust across all shipped levels.
func test_count_matches_shipped_levels():
	assert_eq(LevelLoader.count(), 10, "ten level JSON files ship in assets/levels")

func test_every_level_loads_and_parses():
	for i in range(1, LevelLoader.count() + 1):
		var data = LevelLoader.load_level(i)
		assert_not_null(data, "level %d loaded" % i)
		assert_true(data is LevelData, "level %d is LevelData" % i)
		assert_true(data.holes is Array, "level %d has holes array" % i)
		assert_gt(data.holes.size(), 0, "level %d has at least one hole" % i)

func test_level1_has_hints_and_14_holes():
	var d = LevelLoader.load_level(1)
	assert_true(d.show_hints, "tutorial level shows hints")
	assert_eq(d.holes.size(), 14)

func test_level10_has_rotating_platforms():
	var d = LevelLoader.load_level(10)
	assert_gt(d.rotating_platforms.size(), 0, "level 10 has rotating platforms")
