extends "res://tests/test_base.gd"
## The bag: stacking, filling up, removing, and saving.


func _run() -> void:
	var bag := Inventory.new()
	var changes := [0]
	bag.changed.connect(func(): changes[0] += 1)
	_check(bag.add("mango", 3) == 0, "3 mangoes fit")
	_check(bag.add("mango", 2) == 0 and bag.count("mango") == 5, "mangoes stack")
	_check(bag.slots[0]["count"] == 5 and bag.slots[1].is_empty(), "in one slot")
	_check(bag.add("coconut") == 0 and bag.id_at(1) == "coconut", "a new item takes the next slot")
	_check(changes[0] == 3, "changed fires on each add")

	_check(bag.remove("mango", 2) == 2 and bag.count("mango") == 3, "remove takes some")
	_check(bag.remove("mango", 9) == 3 and bag.slots[0].is_empty(), "remove empties the slot")
	_check(bag.remove("pimento") == 0, "removing what is not there removes nothing")

	bag.clear()
	_check(bag.add("mango", Inventory.MAX_STACK + 5) == 0, "big amounts spill into a second stack")
	_check(bag.slots[0]["count"] == Inventory.MAX_STACK and bag.slots[1]["count"] == 5, "split")
	for i in Inventory.SLOTS:
		bag.add("coconut", Inventory.MAX_STACK)
	_check(bag.add("pimento", 4) == 4, "a full bag returns what does not fit")

	var saved := bag.to_data()
	var copy := Inventory.new()
	copy.from_data(saved)
	_check(copy.count("mango") == bag.count("mango"), "the bag round-trips")
	copy.from_data([{"id": "not_an_item", "count": 3}, "junk", {"id": "coconut", "count": 500}])
	_check(copy.count("not_an_item") == 0, "unknown items are dropped")
	_check(copy.slots[2]["count"] == Inventory.MAX_STACK, "counts are clamped")

	for id: String in GameData.item_ids():
		_check(GameData.item_icon(id) != null, "%s has an icon" % id)
	_finish()
