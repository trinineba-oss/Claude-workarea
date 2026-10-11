class_name TopDog
extends Interactable
## A dog that rules its patch (`topdog <x> <y> <id>`, stats and lines in data/dogs.json). Talk
## to it with Brownie at your side and it challenges her to a turn-based duel (DuelScreen).
## Beaten, it is friendly from then on (flag "beat_<id>").

var dog_id := ""

var _sprite: Sprite2D
var _age := 0.0


func setup(id: String) -> void:
	dog_id = id
	var data := GameData.dog(id)
	add_child(_shadow(Vector2(1.0, 0.85)))
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/sprites/%s.png" % data.get("sprite", "dog"))
	_sprite.offset = Vector2(0, -_sprite.texture.get_height() / 2.0)
	_sprite.flip_h = true
	add_child(_sprite)
	add_child(_feet_shape(Vector2(48, 22), Vector2(0, -8)))
	bubble_height = _sprite.texture.get_height() + 22.0
	_age = randf() * TAU


func _process(delta: float) -> void:
	super(delta)
	_age += delta
	var breathe := sin(_age * 3.0) * 0.03
	_sprite.scale = Vector2(1.0 - breathe, 1.0 + breathe)


func dialogue_id(_flags: Dictionary) -> String:
	return GameData.dog(dog_id).get("intro", "")


func on_talk(hero: Node2D) -> void:
	_sprite.flip_h = hero.global_position.x < global_position.x


func is_beaten(game: Game) -> bool:
	return game.flags.get("beat_" + dog_id, false)


## Talking to it: a challenge if Brownie is here, a shrug if not, a friendly look once beaten.
func use(game: Game) -> void:
	var data := GameData.dog(dog_id)
	if is_beaten(game):
		game.talk(data.get("after", ""), self)
		return
	var brownie := get_tree().get_first_node_in_group("companion") as Companion
	if brownie == null or not brownie.joined:
		game.talk("topdog_no_dog", self)
		return
	await game.talk(data.get("intro", ""), self)
	var screen: DuelScreen = game.get_node("HUD/DuelScreen")
	var won: bool = await screen.fight(game, dog_id)
	game.talk(data.get("win" if won else "lose", ""), self)
