# enemy.gd
extends Area2D

@export var speed: float = 60.0
@export var health: float = 40.0
@export var damage: int = 1
@export var reward: int = 10

var _path_follow: PathFollow2D = null

func _ready():
	add_to_group("enemies")

# Called by WaveManager right after instantiation
func initialize(data: EnemyData) -> void:
	speed = data.speed
	health = data.health
	damage = data.damage
	reward = data.reward

func _process(delta):
	if _path_follow == null:
		_path_follow = get_parent() as PathFollow2D
		return
	_path_follow.progress += speed * delta
	if _path_follow.progress_ratio >= 1.0:
		reach_end()

func take_damage(amount: float):
	health -= amount
	if health <= 0:
		die()

func die():
	GameManager.add_gold(reward)
	var parent = get_parent()
	if parent is PathFollow2D:
		parent.queue_free()
	else:
		queue_free()

func reach_end():
	_path_follow.queue_free()
