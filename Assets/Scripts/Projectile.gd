extends Node2D

const SPEED: float = 300.0

var _target: Node2D = null
var _damage: float = 10.0

func initialize(target: Node2D, damage: float) -> void:
	_target = target
	_damage = damage

func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		queue_free()
		return

	var direction = (_target.global_position - global_position).normalized()
	global_position += direction * SPEED * delta
	rotation = direction.angle()

	# Keep projectiles above towers (towers use 1000 + y)
	z_index = 2000 + int(global_position.y)

	if global_position.distance_to(_target.global_position) < 4.0:
		PixelFX.spawn_arrow_hit(get_tree(), _target.global_position)
		_target.take_damage(_damage)
		queue_free()
