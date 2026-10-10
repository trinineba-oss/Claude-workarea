class_name Npc
extends Interactable
## A townsperson (or the ibis). Which one comes from data/characters.json.

var character_id := ""
var display_name := ""

var _talk: Array = []
var _sprite: Sprite2D
var _age := 0.0


func setup(id: String) -> void:
	character_id = id
	var data := GameData.character(id)
	display_name = data.get("name", id)
	_talk = data.get("talk", [])
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


func dialogue_id(flags: Dictionary) -> String:
	return GameData.pick_dialogue(_talk, flags)


func on_talk(hero: Node2D) -> void:
	_sprite.flip_h = hero.global_position.x < global_position.x
