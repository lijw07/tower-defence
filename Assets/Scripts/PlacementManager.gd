extends Node

var _ground_layer: TileMapLayer
var _road_layer: TileMapLayer

var _pending_data: TowerData = null
var _ghost: Node2D = null
var _occupied_cells: Dictionary = {}
var _blocked_positions: Array[Vector2] = []

func _ready() -> void:
	_ground_layer = get_node("../Ground")
	_road_layer = get_node("../Ground/Road")
	_collect_blocked_positions()

func _collect_blocked_positions() -> void:
	var ground_instance = get_node("../Ground")
	for child in ground_instance.get_children():
		if child is Sprite2D:
			_blocked_positions.append(child.global_position)

func register_obstacle(world_pos: Vector2) -> void:
	_blocked_positions.append(world_pos)

func begin_placement(data: TowerData) -> void:
	cancel_placement()
	_pending_data = data
	_create_ghost(data)

func cancel_placement() -> void:
	_pending_data = null
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null

func _create_ghost(data: TowerData) -> void:
	_ghost = data.scene.instantiate()
	var area = _ghost.get_node("Area2D")
	area.monitoring = false
	area.monitorable = false
	_ghost.modulate = Color(1.0, 1.0, 1.0, 0.5)
	get_tree().current_scene.add_child(_ghost)

func _process(_delta: float) -> void:
	if _pending_data == null or _ghost == null:
		return
	var mouse_world = _get_world_mouse_position()
	var snapped = _snap_to_tile(mouse_world)
	_ghost.global_position = snapped
	var valid = _is_placement_valid(snapped)
	_ghost.modulate = Color(0.2, 1.0, 0.2, 0.5) if valid else Color(1.0, 0.2, 0.2, 0.5)

func _unhandled_input(event: InputEvent) -> void:
	if _pending_data == null:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_world = _get_world_mouse_position()
			var snapped = _snap_to_tile(mouse_world)
			if _is_placement_valid(snapped):
				_place_tower(snapped)
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_placement()
			get_viewport().set_input_as_handled()

	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			cancel_placement()
			get_viewport().set_input_as_handled()

func _get_world_mouse_position() -> Vector2:
	var viewport = get_viewport()
	return viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()

func _snap_to_tile(world_pos: Vector2) -> Vector2:
	var tile_coords: Vector2i = _ground_layer.local_to_map(_ground_layer.to_local(world_pos))
	return _ground_layer.to_global(_ground_layer.map_to_local(tile_coords))

func _is_placement_valid(snapped_world_pos: Vector2) -> bool:
	var tile_coords: Vector2i = _ground_layer.local_to_map(
		_ground_layer.to_local(snapped_world_pos)
	)

	# Must be on ground
	if _ground_layer.get_cell_source_id(tile_coords) == -1:
		return false

	# Must not be on road
	if _road_layer.get_cell_source_id(tile_coords) != -1:
		return false

	# Must not overlap another tower
	if _occupied_cells.has(tile_coords):
		return false

	# Must not be on obstacles
	for blocked_pos in _blocked_positions:
		if snapped_world_pos.distance_to(blocked_pos) < 10.0:
			return false

	return true

func _place_tower(snapped_world_pos: Vector2) -> void:
	if not GameManager.spend_gold(_pending_data.cost):
		cancel_placement()
		return

	var tile_coords: Vector2i = _ground_layer.local_to_map(
		_ground_layer.to_local(snapped_world_pos)
	)
	_occupied_cells[tile_coords] = true

	var tower = _pending_data.scene.instantiate()
	get_tree().current_scene.add_child(tower)
	tower.global_position = snapped_world_pos
	tower.initialize(_pending_data)

	cancel_placement()
