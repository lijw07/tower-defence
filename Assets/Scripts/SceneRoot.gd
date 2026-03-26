extends Node2D

@onready var _castle: Area2D = $SpringBiomeMap/CastleBlue
@onready var _castle_tower: Node2D = $SpringBiomeMap/CastleTowerBlue
@onready var _castle_tower2: Node2D = $SpringBiomeMap/CastleTowerBlue2
@onready var _game_over_ui: CanvasLayer = $GameOverUI
@onready var _tower_shop: CanvasLayer = $TowerShopUI
@onready var _placement_manager: Node = $PlacementManager
@onready var _wave_clear_ui: CanvasLayer = $WaveClearUI
@onready var _wave_manager: Node = $Path2D/WaveManager
@onready var _tower_sell_ui: CanvasLayer = $TowerSellUI
@onready var _health_bar_ui: CanvasLayer = $HealthBarUI
@onready var _upgrade_shop_ui: CanvasLayer = $UpgradeShopUI
var _last_heal_count: int = 0
var _decoration_spawner: Node = null
var _obstacle_removal_ui: CanvasLayer = null

func _ready() -> void:
	_castle.game_over.connect(_on_game_over)
	_tower_shop.tower_selected.connect(_placement_manager.begin_placement)
	# Register a block of tiles around each castle element so towers can't overlap
	var ground: TileMapLayer = $SpringBiomeMap
	_register_castle_block(ground, _castle.global_position)
	_register_castle_block(ground, _castle_tower.global_position)
	if is_instance_valid(_castle_tower2):
		_register_castle_block(ground, _castle_tower2.global_position)
	_wave_manager.wave_completed.connect(_wave_clear_ui.show_wave_complete)
	_wave_manager.wave_completed.connect(_on_wave_completed)
	_wave_clear_ui.next_wave_requested.connect(_wave_manager.proceed_to_next_wave)

	# Tower sell: click a placed tower → show sell UI; sell confirmed → remove tower
	_placement_manager.tower_clicked.connect(_tower_sell_ui.select_tower)
	_tower_sell_ui.tower_sold.connect(_placement_manager.sell_tower)
	# Unlock shop tooltip when placement ends (placed or cancelled)
	_placement_manager.placement_ended.connect(_tower_shop.on_placement_ended)

	# Health bar — health + armor
	_castle.lives_changed.connect(_health_bar_ui.update_health)
	_castle.lives_changed.connect(_on_castle_lives_changed)
	_castle.armor_changed.connect(_health_bar_ui.update_armor)

	# Upgrade shop — button lives in TowerShopUI, panel lives in UpgradeShopUI
	_tower_shop.upgrade_pressed.connect(_upgrade_shop_ui.toggle_shop)
	# Pass tower data so the shop knows which towers exist
	_upgrade_shop_ui.setup(Array(_tower_shop.tower_data_list))

	GameManager.reset()
	var upgrade_mgr: Node = get_node_or_null("/root/UpgradeManager")
	if upgrade_mgr:
		upgrade_mgr.reset()
		# Mark free towers (unlock_cost == 0) as available before the shop builds buttons
		upgrade_mgr.init_unlocks(Array(_tower_shop.tower_data_list))
		# Listen for castle health upgrades so we can apply them to the castle
		upgrade_mgr.castle_stats_changed.connect(_on_castle_stats_changed)

	# Decoration spawner — random trees, rocks, mushrooms
	var spawner_script: GDScript = load("res://Assets/Scripts/DecorationSpawner.gd") as GDScript
	_decoration_spawner = Node.new()
	_decoration_spawner.set_script(spawner_script)
	_decoration_spawner.name = "DecorationSpawner"
	add_child(_decoration_spawner)
	var castle_positions: Array[Vector2] = [_castle.global_position, _castle_tower.global_position]
	if is_instance_valid(_castle_tower2):
		castle_positions.append(_castle_tower2.global_position)
	var ground_layer: TileMapLayer = $SpringBiomeMap
	var road_layer: TileMapLayer = $SpringBiomeMap/Road
	var path2d: Path2D = $Path2D
	_decoration_spawner.setup(ground_layer, road_layer, path2d, castle_positions, "spring")
	# Register spawned decorations as obstacles for tower placement
	for pos in _decoration_spawner.get_spawned_positions():
		_placement_manager.register_obstacle(pos)
	_placement_manager.set_decoration_spawner(_decoration_spawner)

	# Obstacle removal UI — created at runtime (same pattern as DecorationSpawner)
	var removal_script: GDScript = load("res://Assets/Scripts/ObstacleRemovalUI.gd") as GDScript
	_obstacle_removal_ui = CanvasLayer.new()
	_obstacle_removal_ui.set_script(removal_script)
	_obstacle_removal_ui.name = "ObstacleRemovalUI"
	add_child(_obstacle_removal_ui)
	_placement_manager.decoration_clicked.connect(_obstacle_removal_ui.select_decoration)
	_obstacle_removal_ui.obstacle_removed.connect(_on_obstacle_removed)

	# Show wave 1 countdown instead of starting immediately
	_wave_clear_ui.show_wave_starting(1)

	# Start gameplay background music
	var sfx: Node = get_node_or_null("/root/SFXManager")
	if sfx:
		sfx.play_music("gameplay")

# ── Callbacks ───────────────────────────────────────────────────────────────

func _on_game_over() -> void:
	_wave_clear_ui.force_hide()
	# Stop gameplay music and play game over sound
	var sfx: Node = get_node_or_null("/root/SFXManager")
	if sfx:
		sfx.stop_music()
		sfx.play("game_over")
	_game_over_ui.show_game_over()

func _on_castle_lives_changed(current: int, maximum: int) -> void:
	var upgrade_mgr: Node = get_node_or_null("/root/UpgradeManager")
	if upgrade_mgr:
		upgrade_mgr.update_castle_lives(current, maximum)

func _on_castle_stats_changed() -> void:
	var upgrade_mgr: Node = get_node_or_null("/root/UpgradeManager")
	if upgrade_mgr:
		# Re-apply max HP from health upgrades
		var bonus: int = upgrade_mgr.get_castle_health_level()
		var base_max: int = 5  # matches CastleBlue's exported max_lives
		var new_max: int = base_max + bonus
		var damage_taken: int = _castle.max_lives - _castle.lives
		_castle.max_lives = new_max
		_castle.lives = max(1, new_max - damage_taken)

		# Check if a heal was purchased (heal total went up)
		var heal_total: int = upgrade_mgr._castle_heal_total_purchased
		if heal_total > _last_heal_count:
			var heals: int = heal_total - _last_heal_count
			_castle.lives = mini(_castle.lives + heals, _castle.max_lives)
			_last_heal_count = heal_total
		_castle._emit_lives()
		upgrade_mgr.update_castle_lives(_castle.lives, _castle.max_lives)
		# Also update armor display
		_health_bar_ui.update_armor(upgrade_mgr.get_castle_armor())

## Register a 3×3 block of tiles around a castle element as placement obstacles.
func _register_castle_block(ground: TileMapLayer, center_pos: Vector2) -> void:
	var center_tile: Vector2i = ground.local_to_map(ground.to_local(center_pos))
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var tile: Vector2i = center_tile + Vector2i(dx, dy)
			var world_pos: Vector2 = ground.to_global(ground.map_to_local(tile))
			_placement_manager.register_obstacle(world_pos)

func _on_wave_completed(_wave_number: int) -> void:
	# Regrow decorations at the end of each wave (density-aware)
	if _decoration_spawner and is_inside_tree():
		var new_positions: Array[Vector2] = _decoration_spawner.spawn_wave_growth()
		for pos in new_positions:
			_placement_manager.register_obstacle(pos)

func _on_obstacle_removed(deco: Node2D) -> void:
	if deco == null or not is_instance_valid(deco):
		return
	var pos: Vector2 = deco.global_position
	var deco_type: String = deco.get_meta("decoration_type", "tree")
	# Immediately unblock the position and remove from spawner tracking
	_placement_manager.remove_obstacle(pos)
	_decoration_spawner.remove_decoration(deco)
	# Play type-specific sound, particle FX, and animated removal
	var sfx: Node = get_node_or_null("/root/SFXManager")
	match deco_type:
		"tree":
			if sfx: sfx.play("tree_chop")
			PixelFX.spawn_tree_chop(get_tree(), pos)
			_animate_tree_fall(deco)
		"rock":
			if sfx: sfx.play("rock_break")
			PixelFX.spawn_rock_break(get_tree(), pos)
			_animate_rock_crumble(deco)
		"mushroom":
			if sfx: sfx.play("mushroom_pick")
			PixelFX.spawn_mushroom_pick(get_tree(), pos)
			_animate_mushroom_fling(deco)

func _animate_tree_fall(deco: Node2D) -> void:
	# Tree chops and falls sideways (random left or right)
	var direction: float = -1.0 if randf() < 0.5 else 1.0
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	# Rotate to fall sideways (90 degrees)
	tween.tween_property(deco, "rotation", direction * PI / 2.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# Slide in the fall direction
	tween.tween_property(deco, "position", deco.position + Vector2(direction * 12.0, 4.0), 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# Fade out during the fall
	tween.tween_property(deco, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(deco.queue_free)

func _animate_rock_crumble(deco: Node2D) -> void:
	# Rock crumbles downward into the earth
	var start_pos: Vector2 = deco.position
	# Quick shake first
	var shake_tween: Tween = create_tween()
	shake_tween.tween_property(deco, "position", start_pos + Vector2(2.0, 0), 0.04)
	shake_tween.tween_property(deco, "position", start_pos + Vector2(-2.0, 0), 0.04)
	shake_tween.tween_property(deco, "position", start_pos + Vector2(1.0, 0), 0.03)
	shake_tween.tween_property(deco, "position", start_pos, 0.03)
	# Then crumble down
	shake_tween.tween_callback(func():
		var crumble: Tween = create_tween()
		crumble.set_parallel(true)
		crumble.tween_property(deco, "scale", Vector2(1.3, 0.0), 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		crumble.tween_property(deco, "position", start_pos + Vector2(0, 8.0), 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		crumble.tween_property(deco, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		crumble.chain().tween_callback(deco.queue_free)
	)

func _animate_mushroom_fling(deco: Node2D) -> void:
	# Mushroom flies in a parabolic arc, lands, bounces a few times, then fades
	var direction: float = -1.0 if randf() < 0.5 else 1.0
	var start_pos: Vector2 = deco.position
	var ground_y: float = start_pos.y + 6.0  # ground level for bounces
	# Use a method callback so we can simulate a real parabola + bounces
	var phase_data: Dictionary = {
		"dir": direction,
		"start": start_pos,
		"ground_y": ground_y,
		# Arc phase: launch upward and sideways
		"launch_vx": direction * 80.0,
		"launch_vy": -180.0,
		"gravity": 500.0,
		"spin_speed": direction * TAU * 1.5,
		"x": start_pos.x,
		"y": start_pos.y,
		"vx": direction * 80.0,
		"vy": -180.0,
		"bounce_count": 0,
		"max_bounces": 3,
		"damping": 0.45,  # each bounce loses this much energy
		"done": false,
	}
	deco.set_meta("fling_data", phase_data)
	deco.set_meta("fling_time", 0.0)
	deco.set_meta("fling_fade_started", false)
	# Use a tween with a method to drive physics each frame
	var tween: Tween = create_tween()
	tween.tween_method(func(t: float) -> void:
		if not is_instance_valid(deco):
			return
		var d: Dictionary = deco.get_meta("fling_data")
		if d.done:
			return
		var dt: float = t - deco.get_meta("fling_time")
		deco.set_meta("fling_time", t)
		if dt <= 0.0:
			return
		# Apply gravity
		d.vy += d.gravity * dt
		d.x += d.vx * dt
		d.y += d.vy * dt
		# Spin
		deco.rotation += d.spin_speed * dt
		# Check ground collision
		if d.y >= d.ground_y and d.vy > 0.0:
			d.y = d.ground_y
			d.bounce_count += 1
			if d.bounce_count > d.max_bounces:
				d.done = true
				return
			# Bounce: reverse and dampen vertical velocity
			d.vy = -d.vy * d.damping
			d.vx *= 0.7
			d.spin_speed *= 0.5
			# Squash on impact
			deco.scale = Vector2(1.3, 0.6)
		else:
			# Gradually restore scale
			deco.scale = deco.scale.lerp(Vector2(1.0, 1.0), dt * 8.0)
		deco.position = Vector2(d.x, d.y)
		# Start a smooth tween fade after the first bounce
		if d.bounce_count >= 1 and not deco.get_meta("fling_fade_started"):
			deco.set_meta("fling_fade_started", true)
			var fade_tween: Tween = deco.create_tween()
			fade_tween.tween_property(deco, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	, 0.0, 1.8, 1.8)
	tween.tween_callback(deco.queue_free)
