class_name SaveGame
extends RefCounted
## Reads and writes the save file (JSON in user://). Writes are atomic: the data goes to a
## temporary file that then replaces the real one, so a crash cannot leave half a save.

const VERSION := 1

var path := "user://save.json"


func exists() -> bool:
	return FileAccess.file_exists(path)


## Saved data, or an empty dictionary when there is no save, it is unreadable or it is from
## an incompatible version.
func read() -> Dictionary:
	if not exists():
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed: Variant = json.data
	if not parsed is Dictionary or parsed.get("version") != VERSION:
		return {}
	return parsed


func write(data: Dictionary) -> bool:
	var payload := data.duplicate()
	payload["version"] = VERSION
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		push_error("cannot write save file: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(payload))
	file.close()
	return DirAccess.rename_absolute(temp, path) == OK


func delete() -> void:
	if exists():
		DirAccess.remove_absolute(path)
