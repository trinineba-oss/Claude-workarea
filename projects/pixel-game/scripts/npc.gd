class_name Npc
extends Interactable
## A townsperson (or the ibis). Which one comes from data/characters.json. A character can
## be around only while a story flag is set ("present_if") or unset ("present_unless"), and
## with "approach" it walks up and talks as soon as Chad comes near.

const APPROACH_RANGE := 220.0

var character_id := ""
var display_name := ""

var _talk: Array = []
var _present_if := ""
var _present_unless := ""
var _approach := false
var _present := true
var _sprite: Sprite2D
var _age := 0.0


func setup(id: String) -> void:
	character_id = id
	var data := GameData.character(id)
	display_name = data.get("name", id)
	_talk = data.get("talk", [])
	_present_if = data.get("present_if", "")
	_present_unless = data.get("present_unless", "")
	_approach = data.get("approach", false)
	add_child(_shadow(Vector2(0.75, 0.8)))
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/sprites/%s.png" % data.get("sprite", "npc_limer"))
	_sprite.offset = Vector2(0, -_sprite.texture.get_height() / 2.0)
	add_child(_sprite)
	add_child(_feet_shape(Vector2(40, 22), Vector2(0, -8)))
	bubble_height = _sprite.texture.get_height() + 16.0
	_age = randf() * TAU


func _process(delta: float) -> void:
	super(delta)
	_age += delta
	var breathe := sin(_age * 2.4) * 0.025
	_sprite.scale = Vector2(1.0 - breathe, 1.0 + breathe)


func _physics_process(_delta: float) -> void:
	var game := get_tree().get_first_node_in_group("game") as Game
	if game == null:
		return
	var present := is_present(game.flags)
	if present != _present:
		_present = present
		visible = present
		for child in get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", not present)
		if not present:
			set_highlighted(false)
			Effects.burst(get_parent(), position + Vector2(0, -50), "poof")
	if not (present and _approach) or game.is_talking():
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if (
		player != null
		and not player.frozen
		and player.position.distance_to(global_position) < APPROACH_RANGE
	):
		game.talk(dialogue_id(game.dialogue_state()), self)


func is_present(flags: Dictionary) -> bool:
	if _present_if != "" and not flags.get(_present_if, false):
		return false
	return _present_unless == "" or not flags.get(_present_unless, false)


func can_interact(flags: Dictionary) -> bool:
	return _present and super(flags)


func dialogue_id(flags: Dictionary) -> String:
	return GameData.pick_dialogue(_talk, flags)


func on_talk(hero: Node2D) -> void:
	_sprite.flip_h = hero.global_position.x < global_position.x
