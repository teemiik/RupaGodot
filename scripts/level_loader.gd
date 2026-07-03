class_name LevelLoader
extends RefCounted

static func count() -> int:
	var n = 0
	while ResourceLoader.exists("res://assets/levels/level%d.json" % (n + 1)):
		n += 1
	return n

static func load_level(level: int) -> LevelData:
	var path= "res://assets/levels/level%d.json" % level
	if not ResourceLoader.exists(path):
		push_error("Level file not found: " + path)
		return LevelData.new()
	var f= FileAccess.open(path, FileAccess.READ)
	var json= JSON.new()
	if json.parse(f.get_as_text()) != OK:
		return LevelData.new()
	var root: Dictionary = json.data
	var data= LevelData.new()

	if root.has("board"):
		data.board = root["board"]
	if root.has("background"):
		data.background = root["background"]
	if root.has("showHints"):
		data.show_hints = root["showHints"]

	if root.has("holes"):
		for h in root["holes"]:
			data.holes.append({"x": float(h["x"]), "y": float(h["y"])})

	if root.has("dynamicHoles"):
		for d in root["dynamicHoles"]:
			data.dynamic_holes.append({
				"x": float(d["x"]), "y": float(d["y"]),
				"xDin": int(d.get("xDin", 0)), "yDin": int(d.get("yDin", 0))
			})

	if root.has("dynamicControl"):
		var ctrl: Dictionary = root["dynamicControl"]
		data.dynamic_control = {
			"lowerX": float(ctrl.get("lowerX", 0)),
			"upperX": float(ctrl.get("upperX", 0)),
			"inverted": bool(ctrl.get("inverted", false))
		}

	if root.has("barriers"):
		for b in root["barriers"]:
			data.barriers.append({
				"x": float(b["x"]), "y": float(b["y"]),
				"w": float(b["w"]), "h": float(b["h"]),
				"rotation": float(b.get("rotation", 0))
			})

	if root.has("rotatingPlatforms"):
		for p in root["rotatingPlatforms"]:
			data.rotating_platforms.append({
				"x": float(p["x"]), "y": float(p["y"]),
				"w": float(p["w"]), "h": float(p["h"]),
				"rotationSpeed": float(p.get("rotationSpeed", 45)),
				"color": str(p.get("color", "default"))
			})

	return data
