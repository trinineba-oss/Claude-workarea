class_name DungeonDoor
extends Interactable
## A two-tile door in a dungeon wall, placed on its first tile; it runs along the wall it sits
## in. Three kinds:
##   locked   opens with a small key (walk into it or press interact) and stays open
##   gate     iron bars that open for good when their trigger fires (a plate, a switch)
##   shutter  bars that slam shut while a mini-boss in the room is fighting, then open again
##   bossdoor the big sealed door; it takes the temple's boss key (the Pepper Key)

enum Mode { LOCKED, GATE, SHUTTER, BOSS }

const TEXTURES := {
	"locked_h": preload("res://assets/sprites/door_locked_h.png"),
	"locked_v": preload("res://assets/sprites/door_locked_v.png"),
	"bars_h": preload("res://assets/sprites/gate_h.png"),
	"bars_v": preload("res://assets/sprites/gate_v.png"),
	"boss_h": preload("res://assets/sprites/door_boss_h.png"),
}
const MODES := {
	"locked": Mode.LOCKED, "gate": Mode.GATE, "shutter": Mode.SHUTTER, "bossdoor": Mode.BOSS
}
const MESSAGE_COOLDOWN := 1.5
## A shutter only closes once Chad is this far inside the room, so it never lands on him.
const SHUTTER_INSET := 96.0

var mode := Mode.LOCKED
var trigger_name := ""
## Progress key (set by Room) for remembering a locked door was opened.
var key := ""
var horizontal := true
var is_open := false

var _sprite: Sprite2D
var _shape: CollisionShape2D
var _message_cooldown := 0.0


func setup(kind: String, arg: String) -> void:
	mode = MODES[kind]
	trigger_name = arg


func _ready() -> void:
	super()
	add_to_group("doors")
	horizontal = _runs_horizontally()
	var span := (
		Vector2(WorldMap.TILE * 2.0, WorldMap.TILE)
		if horizontal
		else Vector2(WorldMap.TILE, WorldMap.TILE * 2.0)
	)
	var centre := Vector2(WorldMap.TILE / 2.0, 0) if horizontal else Vector2(0, WorldMap.TILE / 2.0)
	_shape = _feet_shape(span, centre)
	add_child(_shape)
	_sprite = Sprite2D.new()
	var look: String = {Mode.LOCKED: "locked", Mode.BOSS: "boss"}.get(mode, "bars")
	# The sealed door has no side-wall art of its own; it borrows the locked door's.
	var art := "%s_%s" % [look, "h" if horizontal else "v"]
	_sprite.texture = TEXTURES.get(art, TEXTURES["locked_v"])
	# The art's bottom edge sits on the bottom of the door's tiles.
	_sprite.position = centre + Vector2(0, span.y / 2.0)
	_sprite.offset = Vector2(0, -_sprite.texture.get_height() / 2.0)
	add_child(_sprite)
	bubble_height = _sprite.texture.get_height() - span.y / 2.0 + 20.0
	var game := _game()
	match mode:
		Mode.LOCKED, Mode.BOSS:
			if game != null and game.progress.is_done(key):
				_set_open(true, false)
		Mode.GATE:
			if game != null:
				if game.progress.is_triggered(trigger_name):
					_set_open(true, false)
				else:
					game.progress.triggered.connect(_on_triggered)
		Mode.SHUTTER:
			_set_open(true, false)


func _physics_process(delta: float) -> void:
	_message_cooldown = maxf(_message_cooldown - delta, 0.0)
	if mode == Mode.SHUTTER:
		var fighting := _boss_fighting()
		if fighting == is_open:
			_set_open(not fighting, true)


func can_interact(_flags: Dictionary) -> bool:
	return _has_lock() and not is_open


func touch_point(from: Vector2) -> Vector2:
	var rect := (_shape.shape as RectangleShape2D).size
	var top_left := global_position + _shape.position - rect / 2.0
	return from.clamp(top_left, top_left + rect)


## Interact: try the lock.
func use(game: Game) -> void:
	if mode == Mode.BOSS and not game.progress.has_boss_key():
		game.talk("boss_door")
		return
	_try_unlock(game)


## Chad walked into it.
func bump(_player: Player, _direction: Vector2) -> void:
	if _has_lock() and not is_open:
		_try_unlock(_game())


func _try_unlock(game: Game) -> void:
	if game == null or is_open:
		return
	var unlocked := game.progress.has_boss_key() if mode == Mode.BOSS else game.progress.use_key()
	if unlocked:
		game.progress.mark_done(key)
		_set_open(true, true)
		Effects.float_text(
			get_parent(), position + Vector2(0, -90), "Unlocked!", Color(1, 0.9, 0.5)
		)
		game.save_game()
	elif _message_cooldown <= 0.0:
		_message_cooldown = MESSAGE_COOLDOWN
		Effects.float_text(
			get_parent(),
			position + Vector2(0, -90),
			"Sealed. Need the Pepper Key." if mode == Mode.BOSS else "Locked. Need a small key.",
			Color(1, 0.8, 0.6)
		)


func _has_lock() -> bool:
	return mode == Mode.LOCKED or mode == Mode.BOSS


func _on_triggered(trigger: String) -> void:
	if trigger == trigger_name and not is_open:
		_set_open(true, true)


func _set_open(open: bool, animate: bool) -> void:
	is_open = open
	_shape.set_deferred("disabled", open)
	if is_open and _highlighted:
		set_highlighted(false)
	if not animate:
		_sprite.visible = not open
		_sprite.scale = Vector2.ONE
		return
	_sprite.visible = true
	var tween := create_tween()
	if open:
		Effects.burst(get_parent(), position + Vector2(0, -30), "poof")
		tween.tween_property(_sprite, "scale:y", 0.05, 0.25)
		tween.tween_callback(func(): _sprite.visible = false)
	else:
		_sprite.scale.y = 0.05
		tween.tween_property(_sprite, "scale:y", 1.0, 0.15)


## Is a mini-boss alive in this room with Chad well inside it?
func _boss_fighting() -> bool:
	var room := get_parent()
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not room is Room:
		return false
	var inner := Rect2(room.global_position, WorldMap.room_size()).grow(-SHUTTER_INSET)
	if not inner.has_point(player.global_position):
		return false
	for boss in get_tree().get_nodes_in_group("bosses"):
		if boss.get_parent() == room and boss.health > 0:
			return true
	return false


## Along a top or bottom wall the door runs sideways, along a side wall it runs down; inside
## a room it follows the wall to its left.
func _runs_horizontally() -> bool:
	var tile := WorldMap.TILE
	var cell := Vector2i((global_position / tile).floor())
	var local := Vector2i(posmod(cell.x, WorldMap.COLS), posmod(cell.y, WorldMap.ROWS))
	if local.y == 0 or local.y == WorldMap.ROWS - 1:
		return true
	if local.x == 0 or local.x == WorldMap.COLS - 1:
		return false
	var game := _game()
	return game == null or Tiles.is_solid(game.world.tile_at(cell + Vector2i.LEFT))


func _game() -> Game:
	return get_tree().get_first_node_in_group("game") as Game
