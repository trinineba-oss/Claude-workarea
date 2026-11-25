class_name PixelCast
extends Node
## Gives every character that has a pixel sheet (Looks) its animated PixelSprite, drawn under
## its plain 2D body sprite (whose own picture is then hidden), and gives enemies a HealthBar.
## Watches the tree, so characters added later (spawns, room changes) get theirs too.


func _ready() -> void:
	name = "PixelCast"
	get_tree().node_added.connect(_on_node_added)
	for node in get_parent().find_children("*", "", true, false):
		_on_node_added(node)


func _on_node_added(node: Node) -> void:
	if node is Node2D and Looks.sheet_for(node) != "":
		dress.call_deferred(node)


## Adds the sprite (and health bar) to one character, once.
static func dress(node: Node2D) -> PixelSprite:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return null
	var main: Variant = node.get("_sprite")
	var body: Sprite2D = main if main is Sprite2D else node.get_node_or_null("Sprite2D")
	if body == null:
		return null
	var existing := body.get_node_or_null("PixelSprite") as PixelSprite
	if existing != null:
		return existing
	# How tall the plain sprite stood: the health bar goes just over it.
	var top := 80.0
	if body.texture != null:
		top = -(body.transform * body.get_rect()).position.y
	var sprite := PixelSprite.new()
	sprite.setup(Looks.sheet_for(node), node)
	body.add_child(sprite)
	body.texture = null
	if node is Enemy:
		var bar := HealthBar.new()
		bar.setup(node, top + 14.0)
		node.add_child(bar)
	return sprite
