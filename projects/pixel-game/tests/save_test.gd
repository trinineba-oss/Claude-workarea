extends "res://tests/test_base.gd"
## Saving and loading the save file.


func _run() -> void:
	var save := SaveGame.new()
	save.path = "user://test_save_unit.json"
	save.delete()
	_check(save.read().is_empty(), "no save reads as empty")

	_check(save.write({"room": [2, 1], "position": [10.5, 20.0]}), "write succeeds")
	var data := save.read()
	_check(data.get("room") == [2.0, 1.0], "room round-trips")
	_check(data.get("position") == [10.5, 20.0], "position round-trips")
	_check(not FileAccess.file_exists(save.path + ".tmp"), "temp file is cleaned up")

	var file := FileAccess.open(save.path, FileAccess.WRITE)
	file.store_string("not json {")
	file.close()
	_check(save.read().is_empty(), "corrupt save reads as empty")

	file = FileAccess.open(save.path, FileAccess.WRITE)
	file.store_string('{"version": 999, "room": [0, 0]}')
	file.close()
	_check(save.read().is_empty(), "other version reads as empty")

	save.delete()
	_check(not save.exists(), "delete removes the file")
	_finish()
