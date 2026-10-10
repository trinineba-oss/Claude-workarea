class_name Bandit
extends Enemy
## A night-time bandit: creeps after Chad through the dark, snatches half his money (or the
## best thing in his bag when his pockets are empty), stops to gloat, then runs. Hit him before
## he gets away to take it back. He never steps into lamplight, so lit streets are safe.

signal stole(what: String, amount: int)
signal escaped

enum State { LURK, STALK, GLOAT, FLEE }

const LURK_SPEED := 70.0
const STALK_SPEED := 200.0
const FLEE_SPEED := 290.0
const NOTICE_RANGE := 420.0
const GIVE_UP_RANGE := 600.0
const GLOAT_TIME := 0.7
const FLEE_TIME := 3.0
## Share of Chad's money he takes (at least TT$1).
const TAKE_FRACTION := 0.5

var state := State.LURK
## What he is carrying off: dollars, or an item id.
var loot_money := 0
var loot_item := ""

var _timer := 0.0
var _wander := Vector2.ZERO
var _wander_time := 0.0

@onready var _bag: Sprite2D = $Bag


func _ready() -> void:
	super()
	_bag.visible = false


func has_loot() -> bool:
	return loot_money > 0 or loot_item != ""


func take_hit(damage: int, from_position: Vector2) -> bool:
	if health <= 0:
		return false
	_give_back()
	var landed := super(damage, from_position)
	if health > 0:
		_enter(State.FLEE, FLEE_TIME)
	return landed


func _think(delta: float) -> void:
	_timer -= delta
	var player := _player()
	match state:
		State.LURK:
			_wander_time -= delta
			if _wander_time <= 0.0:
				_wander = [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP].pick_random()
				_wander_time = randf_range(1.0, 2.4)
			velocity = _wander * LURK_SPEED
			if player != null and _can_reach(player, NOTICE_RANGE):
				state = State.STALK
		State.STALK:
			if player == null or not _can_reach(player, GIVE_UP_RANGE):
				state = State.LURK
				velocity = Vector2.ZERO
			else:
				velocity = global_position.direction_to(player.global_position) * STALK_SPEED
		State.GLOAT:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_enter(State.FLEE, FLEE_TIME)
		State.FLEE:
			var away := (
				player.global_position.direction_to(global_position)
				if player != null
				else Vector2.RIGHT
			)
			velocity = away * FLEE_SPEED
			if _timer <= 0.0:
				_escape()
			return
	_keep_out_of_light()


func _touch_player(player: Player) -> void:
	if state != State.LURK and state != State.STALK:
		return
	if player.frozen or player.health <= 0:
		return
	_snatch(player)


## Chad is worth chasing: close, out of the light, and up and about.
func _can_reach(player: Player, reach: float) -> bool:
	return (
		global_position.distance_to(player.global_position) < reach
		and not NightLight.is_lit(get_tree(), player.global_position)
	)


## Never walks into lamplight; backs out if knocked into it.
func _keep_out_of_light() -> void:
	var tree := get_tree()
	if NightLight.is_lit(tree, global_position):
		var player := _player()
		var away := (
			player.global_position.direction_to(global_position) if player != null else Vector2.UP
		)
		velocity = away * STALK_SPEED
	elif NightLight.is_lit(tree, global_position + velocity * 0.25):
		velocity = Vector2.ZERO


func _snatch(player: Player) -> void:
	var above := position + Vector2(0, -110)
	var game := get_tree().get_first_node_in_group("game") as Game
	if player.money > 0:
		loot_money = maxi(int(player.money * TAKE_FRACTION), 1)
		player.add_money(-loot_money)
		Effects.float_text(get_parent(), above, "-TT$%d!" % loot_money, Color(1, 0.5, 0.45))
		stole.emit("money", loot_money)
	elif game != null and game.inventory.most_valuable() != "":
		loot_item = game.inventory.most_valuable()
		game.inventory.remove(loot_item)
		var name: String = GameData.item(loot_item).get("name", loot_item)
		Effects.float_text(get_parent(), above, "-1 %s!" % name, Color(1, 0.5, 0.45))
		stole.emit(loot_item, 1)
	else:
		Effects.float_text(get_parent(), above, "Yuh broke? Steups.", Color(0.85, 0.85, 1))
	_bag.visible = has_loot()
	_enter(State.GLOAT, GLOAT_TIME)


## A hit makes him drop whatever he took.
func _give_back() -> void:
	if not has_loot():
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	var game := get_tree().get_first_node_in_group("game") as Game
	var above := position + Vector2(0, -110)
	if loot_money > 0 and player != null:
		player.add_money(loot_money)
		Effects.float_text(get_parent(), above, "+TT$%d back!" % loot_money, Color(0.7, 1, 0.6))
	elif loot_item != "" and game != null:
		var name: String = GameData.item(loot_item).get("name", loot_item)
		if game.inventory.add(loot_item) == 0:
			Effects.float_text(get_parent(), above, "+1 %s back!" % name, Color(0.7, 1, 0.6))
	Effects.burst(get_parent(), position + Vector2(0, -50), "sparkle")
	loot_money = 0
	loot_item = ""
	_bag.visible = false


func _escape() -> void:
	if has_loot():
		Effects.float_text(get_parent(), position + Vector2(0, -110), "Gone...", Color(1, 0.6, 0.5))
	loot_money = 0
	loot_item = ""
	escaped.emit()
	leave()


func _animate(_delta: float) -> void:
	var moving := velocity.length() > 1.0
	var running := state == State.FLEE
	var hop := absf(sin(_age * (16.0 if running else 9.0))) * (7.0 if running else 3.0)
	_sprite.position.y = -hop if moving else 0.0
	# Sneaking is low and leaning; gloating is a little bounce on the spot.
	var crouch := 0.9 if state == State.STALK or state == State.LURK else 1.0
	if state == State.GLOAT:
		crouch = 1.0 + sin(_age * 30.0) * 0.05
	_sprite.scale = Vector2(1.0, crouch)
	_sprite.rotation = 0.12 * signf(velocity.x) if state == State.STALK else 0.0
	if velocity.x != 0.0:
		_sprite.flip_h = velocity.x < 0.0
	_bag.position = Vector2(0, -96 + _sprite.position.y)


func _enter(new_state: State, seconds: float) -> void:
	state = new_state
	_timer = seconds
