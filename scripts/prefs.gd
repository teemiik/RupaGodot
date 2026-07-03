class_name PlayerPrefs
extends RefCounted

static func get_pref(key: String, default: Variant = null) -> Variant:
	if SaveData.data.has(key):
		return SaveData.data[key]
	return default

static func set_pref(key: String, value: Variant):
	SaveData.data[key] = value
	SaveData.save()

class SaveData:
	static var data: Dictionary = {}
	static var _loaded= false

	static func load_data():
		if _loaded:
			return
		_loaded = true
		if FileAccess.file_exists("user://save.json"):
			var f= FileAccess.open("user://save.json", FileAccess.READ)
			if f:
				var json= JSON.new()
				if json.parse(f.get_as_text()) == OK:
					data = json.data

	static func save():
		var f= FileAccess.open("user://save.json", FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(data))

	static func _static_init():
		load_data()
