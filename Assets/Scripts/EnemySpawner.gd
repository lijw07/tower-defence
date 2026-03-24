extends Node

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var max_enemies: int = 10

var _path: Path2D
var _spawned_count: int = 0
var _timer: Timer

func _ready():
	_path = get_parent()

	_timer = Timer.new()
	add_child(_timer)
	_timer.wait_time = spawn_interval
	_timer.timeout.connect(_on_timer_timeout)
	_timer.start()

func _on_timer_timeout():
	if _spawned_count >= max_enemies:
		_timer.stop()
		return

	# Each enemy needs its own PathFollow2D
	var path_follow = PathFollow2D.new()
	path_follow.loop = false
	_path.add_child(path_follow)

	var enemy = enemy_scene.instantiate()
	path_follow.add_child(enemy)

	_spawned_count += 1
