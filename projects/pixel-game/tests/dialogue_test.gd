extends "res://tests/test_base.gd"
## Conversations: the data is consistent, the box types and advances, talking to people,
## signs and props, story flags, the ibis's welcome, and that pause and attack do not misfire.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_dialogue.json"

var _finished: Array[String] = []


func _new_game(intro: bool) -> Game:
	var game: Game = GAME.instantiate()
	game.play_intro = intro
	game.save.path = SAVE_PATH
	game.conversation_finished.connect(func(id): _finished.append(id))
	root.add_child(game)
	return game


## Clicks through the open conversation; returns how many lines it had.
func _read_all(box: DialogueBox) -> int:
	var lines := 0
	while box.is_open() and lines < 40:
		box.advance()  # finish typing
		await process_frame
		box.advance()  # next line
		await process_frame
		lines += 1
	await _frames(3)
	return lines


func _face(player: Player, at: Vector2, facing: Vector2) -> void:
	player.position = at
	player.facing = facing
	await _physics_frames(2)


func _run() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	var t := float(WorldMap.TILE)

	# --- the data ----------------------------------------------------------------------------
	for id: String in GameData.conversation_ids():
		var lines := GameData.conversation(id)
		_check(not lines.is_empty(), "conversation '%s' has lines" % id)
		for line: Dictionary in lines:
			_check(
				str(line.get("text", "")).strip_edges() != "", "every line in '%s' has text" % id
			)
	for id: String in GameData.character_ids():
		for option: Dictionary in GameData.character(id).get("talk", []):
			var target: String = option.get("dialogue", "")
			_check(GameData.has_conversation(target), "%s's '%s' exists" % [id, target])
	for id: String in GameData.prop_ids():
		var talk: String = GameData.prop(id).get("dialogue", "")
		_check(talk == "" or GameData.has_conversation(talk), "prop %s's dialogue exists" % id)
	var gyro_talk: Array = GameData.character("gyro_vendor")["talk"]
	_check(GameData.pick_dialogue(gyro_talk, {}) == "gyro_vendor_first", "first meeting")
	_check(
		GameData.pick_dialogue(gyro_talk, {"met_gyro_man": true}) == "gyro_vendor", "later meetings"
	)

	# --- the box -----------------------------------------------------------------------------
	var game := _new_game(false)
	await _physics_frames(2)
	var player: Player = game.get_node("Player")
	var box: DialogueBox = game.get_node("HUD/DialogueBox")
	var overlay: PauseOverlay = game.get_node("HUD/PauseOverlay")
	_check(not box.is_open(), "no conversation at the start (intro off)")
	var touch: TouchControls = game.get_node("HUD/TouchControls")
	touch.visible = true
	game.talk("fisherman")
	await _frames(2)
	_check(box.is_open() and paused, "talking opens the box and pauses the game")
	_check(not touch.visible, "touch controls hide during a conversation")
	var text: Label = box.get("_text")
	_check(text.visible_characters < text.get_total_character_count(), "the line types out")
	box.advance()
	_check(text.visible_characters == -1, "advancing shows the whole line")
	box.advance()
	_check(text.text.begins_with("Catch anything"), "a second advance in the same frame is ignored")
	await process_frame
	box.advance()
	await process_frame
	_check(text.text.begins_with("That boat"), "advancing again shows the next line")
	Input.action_press(&"pause")
	await _frames(2)
	Input.action_release(&"pause")
	await _frames(1)
	_check(not overlay.visible, "pause is ignored during a conversation")
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = Vector2(640, 300)
	box.advance()
	await process_frame
	root.push_input(tap, true)
	await _frames(4)
	_check(not box.is_open(), "tapping the screen closes the last line")
	_check(not paused, "the game resumes afterwards")
	_check(_finished == ["fisherman"], "conversation_finished fires")
	_check(touch.visible, "touch controls come back afterwards")
	touch.visible = false

	# --- talking to the ibis (by facing it and pressing interact) -----------------------------
	var start := WorldMap.room_origin(game.world.start_room())
	await _face(player, start + Vector2(8.5 * t, 5.5 * t), Vector2.UP)
	_check(player.target is Npc and player.target.character_id == "ibis", "the ibis is targeted")
	_check(player.target.get("_bubble").visible, "a speech bubble shows")
	Input.action_press(&"interact")
	await _physics_frames(2)
	Input.action_release(&"interact")
	await _frames(1)
	_check(box.is_open(), "interact starts the conversation")
	var lines := await _read_all(box)
	_check(lines == GameData.conversation("ibis_intro").size(), "the first talk is the welcome")
	_check(game.flags.get("intro_done", false), "the welcome sets intro_done")
	_check(game.save.read().get("flags", {}).get("intro_done", false), "the flag is saved")

	# Attack while facing someone talks instead of swinging, and the closing press is ignored.
	Input.action_press(&"attack")
	await _physics_frames(2)
	Input.action_release(&"attack")
	await _frames(1)
	_check(box.is_open() and player.state != Player.State.ATTACK, "attack near the ibis talks")
	_check(text.text.begins_with("Cross Crossing is up"), "later talks are the hint")
	# The hint has three lines: skip the typing and move on, twice, then finish the last.
	box.advance()
	await process_frame
	box.advance()
	await process_frame
	box.advance()
	await process_frame
	box.advance()
	await process_frame
	box.advance()
	await process_frame
	Input.action_press(&"attack")
	await process_frame
	box.advance()
	await _physics_frames(4)
	Input.action_release(&"attack")
	_check(not box.is_open(), "the hint is over")
	_check(player.state == Player.State.NORMAL, "closing with attack does not swing the cutlass")

	# --- reading a sign and a prop -------------------------------------------------------------
	await _face(player, start + Vector2(12.5 * t, 6.9 * t), Vector2.DOWN)
	_check(player.target is Prop and player.target.prop_id == "boat", "the boat can be read")
	var beach := Vector2i(1, 1)
	game.go_to(beach, WorldMap.room_origin(beach) + Vector2(4.5 * t, 4.5 * t))
	await _face(player, WorldMap.room_origin(beach) + Vector2(4.5 * t, 4.5 * t), Vector2.UP)
	_check(player.target is Signpost, "the beach sign is targeted")
	Input.action_press(&"interact")
	await _physics_frames(2)
	Input.action_release(&"interact")
	await _frames(1)
	_check(box.is_open() and not box.get("_name_panel").visible, "signs have no speaker name")
	await _read_all(box)
	player.position += Vector2(0, 3 * t)
	await _physics_frames(2)
	_check(player.target == null, "walking away clears the target")
	game.free()

	# --- the welcome plays once ----------------------------------------------------------------
	DirAccess.remove_absolute(SAVE_PATH)
	game = _new_game(true)
	box = game.get_node("HUD/DialogueBox")
	for i in 120:
		await process_frame
		if box.is_open():
			break
	_check(box.is_open(), "a new game opens with the ibis's welcome")
	await _read_all(box)
	_check(game.flags.get("intro_done", false), "the welcome is marked as seen")
	game.free()
	game = _new_game(true)
	box = game.get_node("HUD/DialogueBox")
	await _frames(90)
	_check(not box.is_open(), "the welcome does not repeat after loading")
	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()
