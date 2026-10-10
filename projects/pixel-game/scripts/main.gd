extends Node2D
## Collect all the coins. Placeholder game loop to build on.

const COIN_SCENE := preload("res://scenes/coin.tscn")
const COIN_COUNT := 8
const MARGIN := 16.0

var score := 0

@onready var _player: Player = $Player
@onready var _label: Label = $HUD/ScoreLabel


func _ready() -> void:
	_spawn_coins()
	_update_label()


func _spawn_coins() -> void:
	var size := get_viewport_rect().size
	for i in COIN_COUNT:
		var coin: Coin = COIN_SCENE.instantiate()
		coin.position = Vector2(
			randf_range(MARGIN, size.x - MARGIN), randf_range(MARGIN + 12.0, size.y - MARGIN)
		)
		coin.collected.connect(_on_coin_collected)
		add_child(coin)


func _on_coin_collected() -> void:
	score += 1
	_update_label()


func _update_label() -> void:
	_label.text = "Coins: %d / %d" % [score, COIN_COUNT]
