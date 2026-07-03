extends GutTest

# F-registry: regression guard for Progress (JSON-float edge case + format_time).
# Progress uses typed signatures (-> int / seconds: int), which coerce JSON floats
# away — this test documents and locks that behaviour.

const _THROWAWAY_LEVEL = 997

func test_format_time_zero():
	assert_eq(Progress.format_time(0), "00:00")

func test_format_time_minute():
	assert_eq(Progress.format_time(65), "01:05")

func test_format_time_hour():
	assert_eq(Progress.format_time(3600), "60:00")

func test_format_time_accepts_float_via_typed_param():
	# JSON round-trips ints as floats; typed param `seconds: int` coerces.
	# If this ever stops coercing, the real save path breaks.
	assert_eq(Progress.format_time(1.0), "00:01")

func test_record_and_best_time_roundtrip():
	Progress.record_time(_THROWAWAY_LEVEL, 42)
	assert_eq(Progress.best_time(_THROWAWAY_LEVEL), 42)
	assert_true(Progress.is_completed(_THROWAWAY_LEVEL))
	assert_eq(Progress.format_time(Progress.best_time(_THROWAWAY_LEVEL)), "00:42")
	PlayerPrefs.set_pref("best_%d" % _THROWAWAY_LEVEL, -1)

func test_record_keeps_lower_best():
	Progress.record_time(_THROWAWAY_LEVEL, 50)
	Progress.record_time(_THROWAWAY_LEVEL, 30)
	assert_eq(Progress.best_time(_THROWAWAY_LEVEL), 30)
	PlayerPrefs.set_pref("best_%d" % _THROWAWAY_LEVEL, -1)
