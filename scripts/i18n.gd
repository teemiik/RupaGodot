class_name I18N
extends RefCounted

static var _strings: Dictionary = {}

static func init():
	_strings.clear()
	_load_file("res://assets/strings.properties")
	if OS.get_locale_language() != "ru":
		_load_file("res://assets/strings_en.properties")

static func _load_file(path: String):
	if not FileAccess.file_exists(path):
		return
	var f= FileAccess.open(path, FileAccess.READ)
	while not f.eof_reached():
		var line= f.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var eq= line.find("=")
		if eq < 0:
			continue
		var key= line.left(eq).strip_edges()
		var val= line.substr(eq + 1).strip_edges()
		_strings[key] = val

static func get_s(key: String) -> String:
	if _strings.has(key):
		return _strings[key]
	return key

static func fmt(key: String, arg: String) -> String:
	var t= get_s(key)
	return t.replace("{0}", arg)
