# ObstacleRemovalUI.gd
# Shows a small popup next to a clicked decoration with its name, removal cost,
# and a "Remove" button.  Follows the TowerSellUI popup pattern.
extends CanvasLayer

signal obstacle_removed(decoration: Node2D)

var _selected: Node2D = null

var _panel: PanelContainer
var _name_label: Label
var _desc_label: Label
var _cost_label: Label
var _remove_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 6  # Above TowerShopUI (layer 5) so panel draws on top of toolbar
	_build_ui()

func _build_ui() -> void:
	_panel = UITheme.make_panel(UITheme.BG_LIGHTER)
	_panel.visible = false
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	_panel.add_child(vbox)

	_name_label = UITheme.make_label("", 12, UITheme.GOLD)
	vbox.add_child(_name_label)

	_desc_label = UITheme.make_label("", 9, UITheme.TEXT_DIM)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.custom_minimum_size.x = 170
	vbox.add_child(_desc_label)

	vbox.add_child(UITheme.make_separator())

	_cost_label = UITheme.make_label("", 10, UITheme.TEXT)
	vbox.add_child(_cost_label)

	_remove_btn = UITheme.make_button("Remove", Vector2(170, 30))
	_remove_btn.pressed.connect(_on_remove_pressed)
	vbox.add_child(_remove_btn)

func select_decoration(deco: Node2D) -> void:
	if deco == null:
		return
	_selected = deco
	var deco_name: String = deco.get_meta("decoration_name", "Obstacle")
	var deco_type: String = deco.get_meta("decoration_type", "tree")
	var cost: int = deco.get_meta("removal_cost", 0)

	_name_label.text = deco_name
	_desc_label.text = _get_description(deco_type)
	var can_afford: bool = GameManager.gold >= cost
	if can_afford:
		_cost_label.text = "Cost: %d gold" % cost
		_cost_label.add_theme_color_override("font_color", UITheme.TEXT_ORANGE)
	else:
		_cost_label.text = "Need %d gold (have %d)" % [cost, GameManager.gold]
		_cost_label.add_theme_color_override("font_color", UITheme.TEXT_RED)
	_remove_btn.text = "Remove"
	_remove_btn.disabled = not can_afford

	_panel.visible = true
	# Position near the decoration — wait one frame for panel sizing
	await get_tree().process_frame
	if not is_instance_valid(deco) or _selected != deco or not _panel.visible:
		return
	_position_panel(deco.global_position)

func _position_panel(world_pos: Vector2) -> void:
	# Convert world position to screen position
	var cam := get_viewport().get_camera_2d()
	var screen_pos: Vector2
	if cam:
		screen_pos = (world_pos - cam.global_position) * cam.zoom + get_viewport().get_visible_rect().size * 0.5
	else:
		screen_pos = world_pos

	var panel_size: Vector2 = _panel.size
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var margin: float = 8.0

	# Try placing to the right of the decoration
	var px: float = screen_pos.x + 16.0
	var py: float = screen_pos.y - panel_size.y * 0.5

	# Flip to the left if it would go off the right edge
	if px + panel_size.x > viewport_size.x - margin:
		px = screen_pos.x - panel_size.x - 16.0

	# Clamp horizontal edges
	px = clampf(px, margin, viewport_size.x - panel_size.x - margin)

	# Clamp vertical: allow overlapping the toolbar area (we draw on top via layer 6)
	# but don't let the panel go off-screen
	py = clampf(py, margin, viewport_size.y - panel_size.y - margin)

	_panel.global_position = Vector2(px, py)

func deselect() -> void:
	_selected = null
	_panel.visible = false

func _on_remove_pressed() -> void:
	if _selected == null or not is_instance_valid(_selected):
		deselect()
		return
	var cost: int = _selected.get_meta("removal_cost", 0)
	if not GameManager.spend_gold(cost):
		deselect()
		return
	var deco_ref := _selected
	deselect()
	emit_signal("obstacle_removed", deco_ref)

func _get_description(deco_type: String) -> String:
	match deco_type:
		"tree":
			return "A tall tree rooted deep in the ground. Takes some effort to chop down."
		"rock":
			return "A massive boulder. Extremely heavy and costly to break apart."
		"mushroom":
			return "A patch of wild mushrooms. Quick and cheap to clear away."
		_:
			return "An obstacle blocking tower placement."

func _input(event: InputEvent) -> void:
	if not _panel.visible:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		deselect()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			deselect()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var panel_rect := Rect2(_panel.global_position, _panel.size)
			if not panel_rect.has_point(event.position):
				deselect()
