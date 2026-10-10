class_name Forage
extends Interactable
## A plant Chad can pick (mango tree, coconut palm, chadon beni, pepper bush). Picking gives
## items and leaves it bare until it regrows, `regrow_days` game days later.

var forage_id := ""
## Unique per placement, used to remember when it was picked.
var key := ""
## Game day on which it is ready again (0 = ready now).
var ready_day := 0

var _data: Dictionary
var _sprite: Sprite2D
var _full: Texture2D
var _bare: Texture2D


func setup(id: String) -> void:
	forage_id = id
	_data = GameData.forage(id)
	_full = load("res://assets/sprites/%s.png" % _data.get("sprite", "bush"))
	_bare = load("res://assets/sprites/%s.png" % _data.get("picked", _data.get("sprite", "bush")))
	var offset: Array = _data.get("offset", [0, -32])
	add_child(_shadow(Vector2(0.9, 0.7)))
	_sprite = Sprite2D.new()
	_sprite.texture = _full
	_sprite.offset = Vector2(offset[0], offset[1])
	add_child(_sprite)
	var solid: Array = _data.get("solid", [40, 24])
	if solid[0] > 0:
		add_child(_feet_shape(Vector2(solid[0], solid[1]), Vector2(0, -solid[1] / 2.0)))
	bubble_height = absf(offset[1]) * 2.0 + 16.0


func is_ready(today: int) -> bool:
	return today >= ready_day


func _process(delta: float) -> void:
	super(delta)
	refresh(_today())


## Shows fruit when it is ready, bare branches when it is not.
func refresh(today: int) -> void:
	_sprite.texture = _full if is_ready(today) else _bare


func can_interact(_flags: Dictionary) -> bool:
	return is_ready(_today())


## Picks it: returns [item id, amount] and marks it bare until it regrows.
func pick(today: int) -> Array:
	var amount: Array = _data.get("amount", [1, 1])
	ready_day = today + int(_data.get("regrow_days", 1))
	refresh(today)
	return [_data.get("item", ""), randi_range(int(amount[0]), int(amount[1]))]


static func _today() -> int:
	return DayNight.current.day if DayNight.current != null else 1
