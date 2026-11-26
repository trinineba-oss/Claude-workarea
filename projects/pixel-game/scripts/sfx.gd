class_name Sfx
extends Node
## Sound effects (assets/ninja/sfx, CC0): `Sfx.play("hit")` from anywhere. A small pool of
## players lives under the scene tree's root, so sounds overlap and never cut each other off;
## each play gets a touch of random pitch so repeats don't sound mechanical.

const DIR := "res://assets/ninja/sfx/%s.wav"
const VOICES := 10
## Per-sound volume (dB) where the default is too loud or quiet.
const VOLUME := {"dog": -6.0, "fire": -8.0, "roll": -10.0, "whoosh": -6.0, "menu_move": -8.0}

static var _streams: Dictionary = {}
static var _node: Sfx
static var muted := false

var _players: Array[AudioStreamPlayer] = []
var _next := 0


## Plays a sound by name (a file in assets/ninja/sfx). Returns the player, or null.
static func play(sound: String, pitch_jitter := 0.08) -> AudioStreamPlayer:
	if muted:
		return null
	var node := _instance()
	if node == null or not node.is_inside_tree():
		return null
	if not _streams.has(sound):
		var path := DIR % sound
		_streams[sound] = load(path) if ResourceLoader.exists(path) else null
	var stream: AudioStream = _streams[sound]
	if stream == null:
		return null
	var player := node._players[node._next]
	node._next = (node._next + 1) % VOICES
	player.stream = stream
	player.volume_db = float(VOLUME.get(sound, 0.0))
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.play()
	return player


static func _instance() -> Sfx:
	if _node != null and is_instance_valid(_node):
		return _node
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	_node = Sfx.new()
	_node.name = "Sfx"
	_node.process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		_node.add_child(player)
		_node._players.append(player)
	tree.root.add_child.call_deferred(_node)
	return _node
