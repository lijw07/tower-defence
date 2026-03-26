class_name StatusAura
extends Node2D
## Persistent visual aura that attaches to an enemy while a status effect
## is active. Draws small radiating particles each frame using _draw().
## Call StatusAura.create_poison() or StatusAura.create_ice() to attach.

enum AuraType { POISON, ICE }

var _type: AuraType = AuraType.POISON
var _elapsed: float = 0.0
var _emit_timer: float = 0.0
const EMIT_INTERVAL: float = 0.12
var _particles: Array = []  # {pos, vel, life, max_life, color, size}

func _process(delta: float) -> void:
	_elapsed += delta
	_emit_timer -= delta

	# Emit new particles periodically
	if _emit_timer <= 0.0:
		_emit_timer = EMIT_INTERVAL
		_emit_particles()

	# Update existing particles
	var _alive := false
	for p in _particles:
		p.life -= delta
		if p.life <= 0.0:
			continue
		_alive = true
		p.pos += p.vel * delta

	# Always keep running (parent removal handles cleanup)
	queue_redraw()

func _draw() -> void:
	for p in _particles:
		if p.life <= 0.0:
			continue
		var alpha: float = clampf(p.life / p.max_life, 0.0, 1.0) * 0.7
		var c: Color = p.color
		c.a = alpha
		var s: float = p.size
		draw_rect(Rect2(p.pos - Vector2(s, s) * 0.5, Vector2(s, s)), c)

func _emit_particles() -> void:
	# Remove dead particles first
	var live: Array = []
	for p in _particles:
		if p.life > 0.0:
			live.append(p)
	_particles = live

	if _type == AuraType.POISON:
		_emit_poison()
	else:
		_emit_ice()

func _emit_poison() -> void:
	# 1-2 green smoke puffs rising from the enemy
	for i in range(randi_range(1, 2)):
		var angle: float = randf_range(-PI * 0.6, PI * 0.6) - PI / 2.0  # mostly upward
		var spd: float = randf_range(6.0, 14.0)
		var colors: Array[Color] = [Color(0.2, 0.75, 0.1), Color(0.35, 0.9, 0.15), Color(0.15, 0.55, 0.05)]
		_particles.append({
			"pos": Vector2(randf_range(-5, 5), randf_range(-2, 2)),
			"vel": Vector2(cos(angle), sin(angle)) * spd,
			"life": randf_range(0.3, 0.6),
			"max_life": 0.6,
			"color": colors[randi() % colors.size()],
			"size": randf_range(1.5, 3.0),
		})

func _emit_ice() -> void:
	# 1-2 ice crystals drifting outward slowly
	for i in range(randi_range(1, 2)):
		var angle: float = randf() * TAU
		var spd: float = randf_range(5.0, 12.0)
		var colors: Array[Color] = [Color(0.55, 0.8, 1.0), Color(0.8, 0.92, 1.0), Color(0.4, 0.65, 1.0)]
		_particles.append({
			"pos": Vector2(randf_range(-4, 4), randf_range(-4, 4)),
			"vel": Vector2(cos(angle), sin(angle)) * spd + Vector2(0, -4.0),
			"life": randf_range(0.25, 0.5),
			"max_life": 0.5,
			"color": colors[randi() % colors.size()],
			"size": randf_range(1.0, 2.5),
		})

# ── Static factory methods ──────────────────────────────────────────────────

static func create_poison(parent: Node2D) -> StatusAura:
	var aura := StatusAura.new()
	aura._type = AuraType.POISON
	aura.z_index = 1  # slightly above the enemy sprite
	parent.add_child(aura)
	return aura

static func create_ice(parent: Node2D) -> StatusAura:
	var aura := StatusAura.new()
	aura._type = AuraType.ICE
	aura.z_index = 1
	parent.add_child(aura)
	return aura
