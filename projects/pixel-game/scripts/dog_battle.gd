class_name DogBattle
extends RefCounted
## The rules of a turn-based dog duel (Brownie against a top dog from data/dogs.json), kept
## apart from the screen so they can be tested. Brownie moves first each round:
##   bite   damage = attack (+ growl/bark changes) + a little luck - the other's defense
##   bark   lowers the foe's attack, and may make it flinch and lose its turn
##   guard  halves the damage she takes this round
##   treat  eat something from Chad's bag and heal (the screen passes in how much)
## The foe picks from its move list: bite, growl (lowers Brownie's attack), howl (heals when
## hurt) and pounce (crouches for a round, then hits twice as hard; guard against it).
## Brownie's stats come from her level, which grows with experience from wins.

const MOVES := ["bite", "bark", "guard", "treat"]
const FLINCH_CHANCE := 0.35
const HOWL_HEAL := 5
const MOD_LIMIT := 2

var brownie: Dictionary
var foe: Dictionary
var rng := RandomNumberGenerator.new()
## True once a side has run out of HP.
var over := false
var brownie_won := false


## `level` is Brownie's; `foe_data` an entry of data/dogs.json. Pass a seed for repeatable luck.
func _init(level: int, foe_data: Dictionary, seed_value := -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var stats := stats_for(level)
	brownie = _fighter("Brownie", stats["hp"], stats["attack"], stats["defense"])
	foe = _fighter(
		foe_data.get("name", "???"),
		int(foe_data.get("hp", 10)),
		int(foe_data.get("attack", 3)),
		int(foe_data.get("defense", 0))
	)
	foe["moves"] = foe_data.get("moves", ["bite"])


## Brownie's battle stats at a level.
static func stats_for(level: int) -> Dictionary:
	var l := maxi(level, 1)
	return {"hp": 16 + (l - 1) * 4, "attack": 4 + (l - 1), "defense": (l - 1) / 2}


## Experience needed to go from `level` to the next.
static func xp_to_next(level: int) -> int:
	return 10 * maxi(level, 1)


## Adds experience to Brownie's saved level ("brownie_level"/"brownie_xp" in `flags`). Returns
## a line for every level gained.
static func add_xp(flags: Dictionary, amount: int) -> Array[String]:
	var level := int(flags.get("brownie_level", 1))
	var xp := int(flags.get("brownie_xp", 0)) + amount
	var lines: Array[String] = []
	while xp >= xp_to_next(level):
		xp -= xp_to_next(level)
		level += 1
		lines.append("Brownie grew to level %d!" % level)
	flags["brownie_level"] = level
	flags["brownie_xp"] = xp
	return lines


## Plays one round: Brownie's move, then the foe's. Returns what happened, line by line.
func play_round(move: String, treat_heal := 0) -> Array[String]:
	var log: Array[String] = []
	if over:
		return log
	brownie["guarding"] = false
	var flinched := false
	match move:
		"bite":
			_attack(brownie, foe, 1.0, log)
		"bark":
			foe["mod"] = maxi(foe["mod"] - 1, -MOD_LIMIT)
			log.append("Brownie barks! %s's attack drops." % foe["name"])
			if not foe["charging"] and rng.randf() < FLINCH_CHANCE:
				flinched = true
				log.append("%s flinches!" % foe["name"])
		"guard":
			brownie["guarding"] = true
			log.append("Brownie braces herself.")
		"treat":
			var healed := mini(treat_heal, brownie["max_hp"] - brownie["hp"])
			brownie["hp"] += healed
			log.append("Brownie gobbles a treat and gets %d HP back." % healed)
	if _check_over(log):
		return log
	if flinched:
		return log
	_foe_turn(log)
	_check_over(log)
	return log


func _foe_turn(log: Array[String]) -> void:
	if foe["charging"]:
		foe["charging"] = false
		log.append("%s POUNCES!" % foe["name"])
		_attack(foe, brownie, 2.0, log)
		return
	var choices: Array = foe["moves"].duplicate()
	if foe["hp"] * 2 > foe["max_hp"]:
		choices.erase("howl")
	if choices.is_empty():
		choices = ["bite"]
	match choices[rng.randi_range(0, choices.size() - 1)]:
		"growl":
			brownie["mod"] = maxi(brownie["mod"] - 1, -MOD_LIMIT)
			log.append("%s growls. Brownie's attack drops." % foe["name"])
		"howl":
			var healed := mini(HOWL_HEAL, foe["max_hp"] - foe["hp"])
			foe["hp"] += healed
			log.append("%s howls and gets %d HP back." % [foe["name"], healed])
		"pounce":
			foe["charging"] = true
			log.append("%s crouches low... (Guard!)" % foe["name"])
		_:
			_attack(foe, brownie, 1.0, log)


func _attack(attacker: Dictionary, target: Dictionary, power: float, log: Array[String]) -> void:
	var raw: float = (attacker["attack"] + attacker["mod"]) * power + rng.randi_range(-1, 1)
	var damage := maxi(int(round(raw)) - target["defense"], 1)
	if target["guarding"]:
		damage = maxi(int(ceil(damage / 2.0)), 1)
	target["hp"] = maxi(target["hp"] - damage, 0)
	var guard_note := " (guarded)" if target["guarding"] else ""
	log.append("%s bites! %d damage%s." % [attacker["name"], damage, guard_note])


func _check_over(log: Array[String]) -> bool:
	if foe["hp"] <= 0:
		over = true
		brownie_won = true
		log.append("%s gives up!" % foe["name"])
	elif brownie["hp"] <= 0:
		over = true
		brownie_won = false
		log.append("Brownie is worn out...")
	return over


static func _fighter(name: String, hp: int, attack: int, defense: int) -> Dictionary:
	return {
		"name": name,
		"hp": hp,
		"max_hp": hp,
		"attack": attack,
		"defense": defense,
		"mod": 0,
		"guarding": false,
		"charging": false,
	}
