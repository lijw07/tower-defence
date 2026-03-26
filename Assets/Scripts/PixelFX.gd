class_name PixelFX
extends Node2D
## Lightweight pixel-art particle system with unique effects per tower type.
## Each particle is a dict: {pos, vel, life, max_life, color, size, gravity}

var _particles: Array = []
var _elapsed: float = 0.0

func _process(delta: float) -> void:
	_elapsed += delta
	var alive := false
	for p in _particles:
		p.life -= delta
		if p.life <= 0.0:
			continue
		alive = true
		p.vel.y += p.gravity * delta
		p.pos += p.vel * delta
	if not alive:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	for p in _particles:
		if p.life <= 0.0:
			continue
		var alpha: float = clampf(p.life / p.max_life, 0.0, 1.0)
		var c: Color = p.color
		c.a = alpha
		var s: float = p.size
		draw_rect(Rect2(p.pos - Vector2(s, s) * 0.5, Vector2(s, s)), c)

# ── Helper to add particles to an FX instance ──────────────────────────────

func _add(pos: Vector2, vel: Vector2, life: float, color: Color, sz: float, grav: float = 60.0) -> void:
	_particles.append({
		"pos": pos, "vel": vel,
		"life": life, "max_life": life,
		"color": color, "size": sz, "gravity": grav,
	})

static func _make(tree: SceneTree, world_pos: Vector2) -> PixelFX:
	var fx := PixelFX.new()
	fx.z_index = 3500
	fx.global_position = world_pos
	tree.current_scene.add_child(fx)
	return fx

# ── Arrow / Crossbow hit — sharp wood-splinter burst ────────────────────────

static func spawn_arrow_hit(tree: SceneTree, pos: Vector2) -> void:
	var fx := _make(tree, pos)
	for i in range(5):
		var angle: float = randf() * TAU
		var spd: float = randf_range(30.0, 65.0)
		var c: Color = [Color(0.85, 0.65, 0.3), Color(0.7, 0.5, 0.2), Color(1.0, 0.9, 0.7)][i % 3]
		fx._add(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * spd,
			randf_range(0.12, 0.28), c, randf_range(1.5, 2.5), 70.0)

# ── Cannon hit — fiery explosion ring ───────────────────────────────────────

static func spawn_cannon_hit(tree: SceneTree, pos: Vector2) -> void:
	var fx := _make(tree, pos)
	# Outer blast ring
	for i in range(10):
		var angle: float = TAU * float(i) / 10.0 + randf_range(-0.15, 0.15)
		var spd: float = randf_range(40.0, 80.0)
		var c: Color = [Color(1.0, 0.6, 0.1), Color(1.0, 0.35, 0.1), Color(1.0, 0.9, 0.3)][i % 3]
		fx._add(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * spd,
			randf_range(0.2, 0.4), c, randf_range(2.0, 3.5), 30.0)
	# Inner smoke
	for i in range(4):
		var angle: float = randf() * TAU
		var spd: float = randf_range(8.0, 20.0)
		fx._add(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * spd,
			randf_range(0.3, 0.5), Color(0.3, 0.3, 0.3), randf_range(3.0, 5.0), -15.0)

# ── Ice hit — crystalline frost shards that drift slowly ────────────────────

static func spawn_ice_hit(tree: SceneTree, pos: Vector2) -> void:
	var fx := _make(tree, pos)
	for i in range(7):
		var angle: float = randf() * TAU
		var spd: float = randf_range(12.0, 35.0)
		var c: Color = [Color(0.6, 0.85, 1.0), Color(0.85, 0.95, 1.0), Color(0.4, 0.7, 1.0)][i % 3]
		fx._add(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * spd,
			randf_range(0.3, 0.6), c, randf_range(1.5, 3.0), -10.0)
	# Sparkle center
	for i in range(3):
		fx._add(Vector2(randf_range(-3, 3), randf_range(-3, 3)), Vector2.ZERO,
			randf_range(0.15, 0.3), Color(1.0, 1.0, 1.0), randf_range(1.0, 2.0), 0.0)

# ── Poison hit — green toxic smoke that rises ──────────────────────────────

static func spawn_poison_hit(tree: SceneTree, pos: Vector2) -> void:
	var fx := _make(tree, pos)
	for i in range(6):
		var angle: float = randf_range(-PI * 0.8, PI * 0.8) - PI / 2.0  # mostly upward
		var spd: float = randf_range(10.0, 30.0)
		var c: Color = [Color(0.2, 0.8, 0.1), Color(0.4, 1.0, 0.2), Color(0.1, 0.6, 0.05)][i % 3]
		fx._add(Vector2(randf_range(-4, 4), 0), Vector2(cos(angle), sin(angle)) * spd,
			randf_range(0.4, 0.8), c, randf_range(2.5, 4.5), -20.0)
	# Drip particles
	for i in range(2):
		fx._add(Vector2(randf_range(-3, 3), 0),
			Vector2(randf_range(-5, 5), randf_range(15, 30)),
			randf_range(0.2, 0.4), Color(0.15, 0.5, 0.0), randf_range(1.5, 2.0), 50.0)

# ── Lightning hit — bright electric sparks ─────────────────────────────────

static func spawn_lightning_hit(tree: SceneTree, pos: Vector2) -> void:
	var fx := _make(tree, pos)
	# Fast outward sparks
	for i in range(8):
		var angle: float = randf() * TAU
		var spd: float = randf_range(50.0, 100.0)
		var c: Color = [Color(0.8, 0.85, 1.0), Color(0.5, 0.6, 1.0), Color(1.0, 1.0, 1.0)][i % 3]
		fx._add(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * spd,
			randf_range(0.06, 0.15), c, randf_range(1.0, 2.0), 0.0)
	# Bright center flash
	fx._add(Vector2.ZERO, Vector2.ZERO, 0.08, Color(1.0, 1.0, 1.0), 6.0, 0.0)

# ── Death burst — white pixels ─────────────────────────────────────────────

static func spawn_death(tree: SceneTree, pos: Vector2) -> void:
	var fx := _make(tree, pos)
	for i in range(7):
		var angle: float = randf() * TAU
		var spd: float = randf_range(30.0, 70.0)
		fx._add(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * spd,
			randf_range(0.15, 0.35), Color(1.0, 1.0, 1.0), randf_range(1.5, 3.0), 50.0)

# ── Tree chop — wood chips + falling leaves ─────────────────────────────────

static func spawn_tree_chop(tree: SceneTree, pos: Vector2) -> void:
	var fx := _make(tree, pos)
	# Wood chips burst outward
	for i in range(6):
		var angle: float = randf_range(-PI * 0.7, PI * 0.7) - PI / 2.0
		var spd: float = randf_range(25.0, 55.0)
		var c: Color = [Color(0.65, 0.45, 0.2), Color(0.8, 0.6, 0.3), Color(0.5, 0.35, 0.15)][i % 3]
		fx._add(Vector2(randf_range(-3, 3), randf_range(-4, 0)),
			Vector2(cos(angle), sin(angle)) * spd,
			randf_range(0.2, 0.4), c, randf_range(1.5, 2.5), 80.0)
	# Falling leaves — slow, drifting, low gravity
	for i in range(5):
		var drift_x: float = randf_range(-30.0, 30.0)
		var drift_y: float = randf_range(-15.0, 5.0)
		var c: Color = [Color(0.3, 0.75, 0.2), Color(0.45, 0.85, 0.3), Color(0.25, 0.6, 0.15),
			Color(0.5, 0.9, 0.35), Color(0.35, 0.7, 0.25)][i]
		fx._add(Vector2(randf_range(-6, 6), randf_range(-8, -2)),
			Vector2(drift_x, drift_y),
			randf_range(0.5, 0.9), c, randf_range(2.0, 3.0), 20.0)

# ── Rock break — heavy debris + dust cloud ──────────────────────────────────

static func spawn_rock_break(tree: SceneTree, pos: Vector2) -> void:
	var fx := _make(tree, pos)
	# Stone chunks flying outward
	for i in range(8):
		var angle: float = randf() * TAU
		var spd: float = randf_range(35.0, 75.0)
		var c: Color = [Color(0.55, 0.5, 0.45), Color(0.7, 0.65, 0.6), Color(0.4, 0.38, 0.35),
			Color(0.6, 0.58, 0.52)][i % 4]
		fx._add(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * spd,
			randf_range(0.2, 0.45), c, randf_range(2.0, 3.5), 90.0)
	# Dust cloud — slow, rising, large particles
	for i in range(5):
		var angle: float = randf() * TAU
		var spd: float = randf_range(5.0, 15.0)
		fx._add(Vector2(randf_range(-4, 4), randf_range(-2, 2)),
			Vector2(cos(angle), sin(angle)) * spd,
			randf_range(0.4, 0.7), Color(0.6, 0.55, 0.45, 0.7), randf_range(3.0, 5.0), -8.0)

# ── Mushroom pick — soft spore puff ─────────────────────────────────────────

static func spawn_mushroom_pick(tree: SceneTree, pos: Vector2) -> void:
	var fx := _make(tree, pos)
	# Spore cloud — gentle floating particles rising
	for i in range(8):
		var angle: float = randf_range(-PI * 0.9, PI * 0.9) - PI / 2.0
		var spd: float = randf_range(8.0, 22.0)
		var c: Color = [Color(0.9, 0.8, 0.5), Color(0.95, 0.85, 0.6), Color(0.85, 0.75, 0.45),
			Color(1.0, 0.9, 0.65)][i % 4]
		fx._add(Vector2(randf_range(-4, 4), randf_range(-2, 2)),
			Vector2(cos(angle), sin(angle)) * spd,
			randf_range(0.4, 0.8), c, randf_range(1.5, 2.5), -12.0)
	# Tiny cap fragments popping out
	for i in range(3):
		var angle: float = randf() * TAU
		var spd: float = randf_range(20.0, 40.0)
		var c: Color = [Color(0.85, 0.25, 0.2), Color(0.9, 0.35, 0.25), Color(0.75, 0.2, 0.15)][i]
		fx._add(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * spd,
			randf_range(0.15, 0.3), c, randf_range(1.5, 2.0), 60.0)

# ── Nature grow — green sparkles rising from the ground ─────────────────────

static func spawn_nature_grow(tree: SceneTree, pos: Vector2) -> void:
	var fx := _make(tree, pos)
	# Rising green sparkles
	for i in range(6):
		var angle: float = randf_range(-PI * 0.6, PI * 0.6) - PI / 2.0
		var spd: float = randf_range(10.0, 25.0)
		var c: Color = [Color(0.3, 0.85, 0.3), Color(0.5, 0.95, 0.4), Color(0.2, 0.7, 0.2),
			Color(0.6, 1.0, 0.5)][i % 4]
		fx._add(Vector2(randf_range(-4, 4), randf_range(0, 4)),
			Vector2(cos(angle), sin(angle)) * spd,
			randf_range(0.3, 0.6), c, randf_range(1.5, 2.5), -15.0)
	# Tiny golden pollen motes
	for i in range(3):
		var drift: Vector2 = Vector2(randf_range(-15, 15), randf_range(-20, -8))
		fx._add(Vector2(randf_range(-5, 5), randf_range(-2, 2)),
			drift, randf_range(0.4, 0.7), Color(1.0, 0.9, 0.5, 0.8), randf_range(1.0, 2.0), -5.0)

# ── Muzzle flash (unchanged, used by Tower.gd) ─────────────────────────────

static func spawn_muzzle(tree: SceneTree, world_pos: Vector2, direction: Vector2, color: Color = Color(1.0, 0.9, 0.4)) -> void:
	var fx := _make(tree, world_pos)
	for i in range(3):
		var spread: float = randf_range(-0.4, 0.4)
		var dir: Vector2 = direction.rotated(spread)
		var spd: float = randf_range(30.0, 55.0)
		fx._add(Vector2.ZERO, dir * spd, randf_range(0.08, 0.18), color, randf_range(1.5, 2.5), 0.0)
