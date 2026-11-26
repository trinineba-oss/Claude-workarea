class_name Music
extends Node
## Background music (assets/ninja/music, CC0), cross-fading between tracks: the village theme
## in town, the boat theme on the wharf, the fight theme while the wharf waves are on.

const DIR := "res://assets/ninja/music/%s.ogg"
const FADE := 1.2
const VOLUME := -10.0

var track := ""

var _players: Array[AudioStreamPlayer] = []
var _active := 0


func _ready() -> void:
	name = "Music"
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.volume_db = -80.0
		add_child(player)
		_players.append(player)


## Fades over to a track ("" fades to silence). Does nothing if it is already playing.
func play(next: String) -> void:
	if next == track:
		return
	track = next
	var old := _players[_active]
	_active = 1 - _active
	var new := _players[_active]
	var fade_out := create_tween()
	fade_out.tween_property(old, "volume_db", -80.0, FADE)
	fade_out.tween_callback(old.stop)
	if next == "":
		return
	var path := DIR % next
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	new.stream = stream
	new.volume_db = -80.0
	new.play()
	create_tween().tween_property(new, "volume_db", VOLUME, FADE)
