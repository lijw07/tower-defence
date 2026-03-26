# LightningBolt.gd — Chain-lightning projectile for the Lightning tower.
# Hits the primary target, then arcs to up to MAX_CHAINS nearby enemies,
# each jump dealing CHAIN_FALLOFF × the previous hit's damage.
# Spawns a visual arc effect showing the chain path.
extends Node2D

const SPEED: float = 300.0
const MAX_CHAINS: int = 3
const CHAIN_RADIUS: float = 80.0
const CHAIN_FALLOFF: float = 0.65   # each chain jump does 65 % of the previous damage

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
	z_index = 2000 + int(global_position.y)

	if global_position.distance_to(_target.global_position) < 4.0:
		var chain_points: Array[Vector2] = [global_position]
		_chain_from(_target, _damage, [], MAX_CHAINS, chain_points)
		# Spawn visual chain arc
		if chain_points.size() >= 2:
			_spawn_chain_visual(chain_points)
		queue_free()

# Recursively chain to nearby enemies that haven't been hit yet.
func _chain_from(source: Node2D, dmg: float, already_hit: Array, chains_left: int, chain_points: Array[Vector2]) -> void:
	if not is_instance_valid(source):
		return

	PixelFX.spawn_lightning_hit(get_tree(), source.global_position)
	source.take_damage(dmg)
	already_hit.append(source)
	chain_points.append(source.global_position)

	var sfx: Node = get_node_or_null("/root/SFXManager")
	if sfx and already_hit.size() > 1:
		sfx.play("enemy_hit", -6.0)

	if chains_left <= 0:
		return

	# Find the closest unhit enemy within CHAIN_RADIUS.
	var best_enemy: Node2D = null
	var best_dist: float = CHAIN_RADIUS + 1.0

	for enemy in source.get_tree().get_nodes_in_group("enemies"):
		if enemy in already_hit:
			continue
		if not is_instance_valid(enemy):
			continue
		var dist: float = source.global_position.distance_to(enemy.global_position)
		if dist < best_dist:
			best_dist = dist
			best_enemy = enemy

	if best_enemy != null:
		_chain_from(best_enemy, dmg * CHAIN_FALLOFF, already_hit, chains_left - 1, chain_points)

func _spawn_chain_visual(points: Array[Vector2]) -> void:
	var arc := Node2D.new()
	arc.set_script(load("res://Assets/Scripts/ChainArc.gd"))
	arc.z_index = 3000
	get_tree().current_scene.add_child(arc)
	arc.setup(points)
