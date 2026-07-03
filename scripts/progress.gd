class_name Progress
extends RefCounted

static func best_time(level: int) -> int:
	return PlayerPrefs.get_pref("best_%d" % level, -1)

static func is_completed(level: int) -> bool:
	return best_time(level) >= 0

static func record_time(level: int, seconds: int):
	var cur= best_time(level)
	if cur < 0 or seconds < cur:
		PlayerPrefs.set_pref("best_%d" % level, seconds)

static func format_time(seconds: int) -> String:
	var m= seconds / 60
	var s= seconds % 60
	return "%02d:%02d" % [m, s]
