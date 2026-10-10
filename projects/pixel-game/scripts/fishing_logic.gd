class_name FishingLogic
extends RefCounted
## The catch minigame without any drawing: hold to lift the green zone, let go to let it fall,
## and keep the fish inside it until the catch bar fills. Positions run 0 (bottom) to 1 (top).

const ZONE_SIZE := 0.28
const LIFT := 3.4
const GRAVITY := 2.0
const MAX_SPEED := 1.5
const FILL_RATE := 0.34
const DRAIN_RATE := 0.14
const START_PROGRESS := 0.35

var fish_pos := 0.5
## Bottom edge of the green zone.
var zone_pos := 0.1
var progress := START_PROGRESS
var difficulty := 1.0

var _zone_speed := 0.0
var _fish_target := 0.5
var _fish_timer := 0.0
var _rng := RandomNumberGenerator.new()


func _init(fish_difficulty := 1.0, rng_seed := 0) -> void:
	difficulty = maxf(fish_difficulty, 0.1)
	if rng_seed != 0:
		_rng.seed = rng_seed
	else:
		_rng.randomize()
	# Start with the zone on the fish, so the player has a moment to react.
	zone_pos = clampf(fish_pos - ZONE_SIZE / 2.0, 0.0, 1.0 - ZONE_SIZE)


func on_fish() -> bool:
	return fish_pos >= zone_pos and fish_pos <= zone_pos + ZONE_SIZE


## Advances the minigame; returns "caught", "escaped" or "" while it is still going.
func step(delta: float, holding: bool) -> String:
	_zone_speed = clampf(
		_zone_speed + (LIFT if holding else -GRAVITY) * delta, -MAX_SPEED, MAX_SPEED
	)
	zone_pos += _zone_speed * delta
	if zone_pos <= 0.0:
		zone_pos = 0.0
		_zone_speed = maxf(_zone_speed, 0.0)
	elif zone_pos >= 1.0 - ZONE_SIZE:
		zone_pos = 1.0 - ZONE_SIZE
		_zone_speed = minf(_zone_speed, 0.0)
	_fish_timer -= delta
	if _fish_timer <= 0.0:
		_fish_target = _rng.randf_range(0.05, 0.95)
		_fish_timer = _rng.randf_range(0.5, 1.6) / difficulty
	fish_pos = move_toward(fish_pos, _fish_target, delta * 0.32 * difficulty)
	progress += (FILL_RATE if on_fish() else -DRAIN_RATE) * delta
	if progress >= 1.0:
		return "caught"
	if progress <= 0.0:
		return "escaped"
	return ""
