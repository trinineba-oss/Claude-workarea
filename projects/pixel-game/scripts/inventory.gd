class_name Inventory
extends RefCounted
## Chad's bag: a fixed number of slots, each holding a stack of one item.

signal changed

const SLOTS := 12
const MAX_STACK := 99

## Each slot is {} (empty) or {"id": String, "count": int}.
var slots: Array = []


func _init() -> void:
	clear()


func clear() -> void:
	slots = []
	for i in SLOTS:
		slots.append({})
	changed.emit()


## Adds items, filling existing stacks first. Returns how many did not fit.
func add(id: String, amount: int = 1) -> int:
	var left := amount
	for slot: Dictionary in slots:
		if left > 0 and slot.get("id") == id and slot["count"] < MAX_STACK:
			var put := mini(left, MAX_STACK - slot["count"])
			slot["count"] += put
			left -= put
	for i in slots.size():
		if left > 0 and slots[i].is_empty():
			var put := mini(left, MAX_STACK)
			slots[i] = {"id": id, "count": put}
			left -= put
	if left != amount:
		changed.emit()
	return left


## Removes up to `amount`; returns how many were removed.
func remove(id: String, amount: int = 1) -> int:
	var left := amount
	for i in range(slots.size() - 1, -1, -1):
		var slot: Dictionary = slots[i]
		if left > 0 and slot.get("id") == id:
			var take := mini(left, slot["count"])
			slot["count"] -= take
			left -= take
			if slot["count"] == 0:
				slots[i] = {}
	if left != amount:
		changed.emit()
	return amount - left


func count(id: String) -> int:
	var total := 0
	for slot: Dictionary in slots:
		if slot.get("id") == id:
			total += slot["count"]
	return total


## The most valuable thing in the bag that is not a tool, or "" (what a bandit grabs).
func most_valuable() -> String:
	var best := ""
	var best_price := -1
	for slot: Dictionary in slots:
		if slot.is_empty():
			continue
		var item := GameData.item(slot["id"])
		var price := int(item.get("price", 0))
		if not item.get("tool", false) and price > best_price:
			best = slot["id"]
			best_price = price
	return best


func id_at(index: int) -> String:
	return slots[index].get("id", "") if index >= 0 and index < slots.size() else ""


func to_data() -> Array:
	return slots.duplicate(true)


func from_data(data: Variant) -> void:
	clear()
	if not data is Array:
		return
	for i in mini(data.size(), SLOTS):
		var slot: Variant = data[i]
		if slot is Dictionary and GameData.has_item(str(slot.get("id", ""))):
			slots[i] = {
				"id": str(slot["id"]), "count": clampi(int(slot.get("count", 1)), 1, MAX_STACK)
			}
	changed.emit()
