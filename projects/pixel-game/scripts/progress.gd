class_name Progress
extends RefCounted
## Temple progress: opened doors and chests, fired triggers and small keys. Saved with the
## game. Entries are namespaced by map, e.g. "temple1:keys" or "temple1:trigger/crab".

## A trigger fired (a plate pressed, a switch hit, a mini-boss beaten).
signal triggered(trigger_name: String)
signal keys_changed(count: int)

## The map whose triggers and keys are meant (Game sets it when Chad changes map).
var map_id := "overworld"
var data: Dictionary = {}


func key(what: String) -> String:
	return "%s:%s" % [map_id, what]


func is_done(entry: String) -> bool:
	return data.get(entry, false) == true


func mark_done(entry: String) -> void:
	data[entry] = true


## Small keys held for the current map.
func key_count() -> int:
	return int(data.get(key("keys"), 0))


func add_key(amount := 1) -> void:
	data[key("keys")] = key_count() + amount
	keys_changed.emit(key_count())


## Uses a small key if there is one.
func use_key() -> bool:
	if key_count() <= 0:
		return false
	add_key(-1)
	return true


## The big key that opens this map's boss door.
func has_boss_key() -> bool:
	return is_done(key("boss_key"))


func give_boss_key() -> void:
	mark_done(key("boss_key"))
	keys_changed.emit(key_count())


func is_triggered(trigger_name: String) -> bool:
	return is_done(key("trigger/" + trigger_name))


## Fires a trigger for good and tells gates, chests and the like.
func fire(trigger_name: String) -> void:
	if is_triggered(trigger_name):
		return
	mark_done(key("trigger/" + trigger_name))
	triggered.emit(trigger_name)
