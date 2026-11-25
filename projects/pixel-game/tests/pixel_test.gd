extends "res://tests/test_base.gd"
## The pixel-art look: characters with a pixel sheet get an animated PixelSprite (crisp, on
## the 2x grid) in place of their plain sprite, it plays the right animation for what they
## do, and hits show: enemies flash white and get a health bar, the cutlass leaves slash
## marks, Chad's roll leaves afterimages.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_pixel.json"


func _run() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	var game: Game = GAME.instantiate()
	game.play_intro = false
	game.wharf_demo = false
	game.save.path = SAVE_PATH
	root.add_child(game)
	_bench_evey()
	await _physics_frames(3)
	await _frames(3)
	var player: Player = game.get_node("Player")
	var body: Sprite2D = player.get("_sprite")
	var sprite := body.get_node_or_null("PixelSprite") as PixelSprite
	_check(sprite != null, "Chad gets an animated pixel sprite")
	_check(sprite != null and sprite.sheet == Looks.sheet_by_key("player"), "from his sheet")
	_check(body.texture == null, "and his plain sprite no longer draws")
	_check(
		(
			ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")
			== 0
		),
		"pixels are drawn crisp (nearest filtering)"
	)
	_check(sprite.scale.x == PixelSprite.ART_SCALE, "on the 2x pixel grid")
	_check(Looks.frame_size("chad") == 64, "pixel sheets have 64 px frames")

	# --- animation ---------------------------------------------------------------------------
	_check(sprite.anim_name == "idle", "standing still plays the idle")
	Input.action_press(&"move_left")
	await _physics_frames(6)
	await _frames(2)
	_check(sprite.anim_name in ["walk", "run"], "moving plays the walk")
	_check(Looks.direction_index(sprite.facing) == 1, "facing left")
	var frame_before := sprite.frame
	await _physics_frames(8)
	await _frames(2)
	_check(sprite.frame != frame_before, "the walk cycle moves on as he moves")
	Input.action_release(&"move_left")
	await _physics_frames(4)
	await _frames(2)
	_check(sprite.anim_name == "idle", "and stops when he stops")
	Input.action_press(&"attack")
	await _physics_frames(2)
	await _frames(1)
	Input.action_release(&"attack")
	_check(sprite.anim_name.begins_with("slash"), "a swing plays the slash")
	await _physics_frames(30)

	var evey: Companion = get_first_node_in_group("companion")
	var evey_sprite := evey.get("_sprite").get_node_or_null("PixelSprite") as PixelSprite
	_check(
		evey_sprite != null and evey_sprite.sheet == Looks.sheet_by_key("companion"),
		"Evey is the pixel beagle"
	)

	# --- hit reactions -----------------------------------------------------------------------
	var ghost := sprite.spawn_ghost()
	_check(ghost != null and ghost.frame == sprite.frame, "a roll leaves an afterimage")
	var room := game.current_room()
	var arc := Effects.slash_arc(room, Vector2(300, 300), Vector2(240, 300), true)
	_check(arc != null and arc.is_inside_tree(), "a hit leaves a slash mark")
	var crab: Enemy = Entities.create("crab")
	crab.position = player.position + Vector2(300, 0) - room.position
	room.add_child(crab)
	await _frames(3)
	var crab_sprite: PixelSprite = crab.get("_sprite").get_node_or_null("PixelSprite")
	var bar := crab.get_node_or_null("HealthBar") as HealthBar
	_check(crab_sprite != null and bar != null, "enemies get a pixel sprite and a health bar")
	_check(not bar.visible, "the bar stays hidden at full health")
	crab.take_hit(1, player.global_position)
	await _frames(2)
	_check(crab_sprite.is_flashing(), "a hit enemy flashes white")
	_check(bar.visible and bar.fill() < 1.0, "a hurt enemy shows its health bar")
	crab.queue_free()
	_check(
		Effects.flourish(room, Vector2(200, 200), "star_burst_gold", 1.0) != null,
		"sprite-sheet flourishes play in 2D"
	)
	game.queue_free()
	await _frames(2)
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()
