class_name Traffic
extends Node2D
## A lane of cars driving across the room in one direction. Cars hurt and knock back the
## hero; they ignore walls and disappear past the edge of the room.

const DIRECTIONS := {
	"down": Vector2.DOWN, "up": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT
}
const CARS := [
	preload("res://assets/sprites/car_white.png"),
	preload("res://assets/sprites/car_red.png"),
	preload("res://assets/sprites/car_blue.png"),
	preload("res://assets/sprites/car_grey.png"),
]
const SPEED_MIN := 300.0
const SPEED_MAX := 380.0
const GAP_MIN := 1.6
const GAP_MAX := 3.2

var direction := Vector2.DOWN

var _timer := 0.0


func setup(arg: String) -> void:
	direction = DIRECTIONS.get(arg, Vector2.DOWN)
	_timer = randf_range(0.2, GAP_MAX)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = randf_range(GAP_MIN, GAP_MAX)
		spawn_car()


## Starts a car just outside the room at this lane's position.
func spawn_car() -> Car:
	var car := Car.new()
	car.setup(CARS.pick_random(), direction * randf_range(SPEED_MIN, SPEED_MAX))
	var size := WorldMap.room_size()
	var start := position
	if direction.y > 0.0:
		start.y = -80.0
	elif direction.y < 0.0:
		start.y = size.y + 80.0
	elif direction.x > 0.0:
		start.x = -80.0
	else:
		start.x = size.x + 80.0
	car.position = start
	get_parent().add_child(car)
	return car
