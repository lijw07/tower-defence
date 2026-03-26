# TowerSellUI.gd
# Shows a small popup next to a placed tower with its info and a Sell button.
# Clicking Sell refunds half the tower's cost and removes it from the map.
# Click anywhere outside the panel (or press ESC / right-click) to dismiss.
extends CanvasLayer

signal tower_sold(tower: Node2D)

var _selected_tower: Node2D = null
var _range_indicator: Node2D = null

var _panel: PanelContainer
var _name_label: Label
var _dmg_label: Label
var _spd_label: Label
var _desc_label: Label
var _sell_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui() -> void:
	_panel = UITheme.make_panel(UITheme.BG_LIGHTER)
	_panel.visible = false
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)

	_name_label = UITheme.make_label("", 14, UITheme.GOLD)
	vbox.add_child(_name_label)

	vbox.add_child(UITheme.make_separator())

	_dmg_label = UITheme.make_label("", 10, UITheme.TEXT)
	vbox.add_child(_dmg_label)

	_spd_label = UITheme.make_label("", 10, UITheme.TEXT)
	vbox.add_child(_spd_label)

	vbox.add_child(UITheme.make_separator())

	_desc_label = UITheme.make_label("", 9, UITheme.TEXT_DIM)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.custom_minimum_size.x = 190
	vbox.add_child(_desc_label)

	vbox.add_child(UITheme.make_separator())

	_sell_btn = UITheme.make_button("Sell", Vector2(190, 30))
	_sell_btn.pressed.connect(_on_sell_pressed)
	vbox.add_child(_sell_btn)

func select_tower(tower: Node2D) -> void:
	if tower == null or tower.tower_data == null:
		return
	_selected_tower = tower
	var data: TowerData = tower.tower_data
	var sell_value: int = GameManager.get_sell_value(data.tower_name)
	# Show effective stats with upgrades applied
	var upgrade_mgr: Node = get_node_or_null("/root/UpgradeManager")
	var eff_dmg: float = data.damage
	var eff_spd: float = data.attack_speed
	if upgrade_mgr:
		eff_dmg = data.damage * upgrade_mgr.get_damage_multiplier(data.tower_name)
		eff_spd = data.attack_speed / upgrade_mgr.get_speed_multiplier(data.tower_name)
	# Show range indicator on the tower
	_hide_range_indicator()
	var pm: Node = get_node_or_null("../PlacementManager")
	if pm and pm.has_method("get_tower_range_cached"):
		var radius: float = pm.get_tower_range_cached(data)
		if radius > 0.0:
			var ri_script: GDScript = load("res://Assets/Scripts/RangeIndicator.gd") as GDScript
			_range_indicator = Node2D.new()
			_range_indicator.set_script(ri_script)
			_range_indicator.z_index = 999
			_range_indicator.global_position = tower.global_position
			get_tree().current_scene.add_child(_range_indicator)
			_range_indicator.set_radius(radius)
			_range_indicator.set_color(
				Color(1.0, 0.85, 0.2, 0.4),
				Color(1.0, 0.85, 0.2, 0.07)
			)

	_name_label.text = data.tower_name
	_dmg_label.text = "Damage: %d" % int(eff_dmg)
	_spd_label.text = "Speed:  %.1fs" % eff_spd
	_desc_label.text = data.description if data.description != "" else "No description."
	_sell_btn.text = "Sell (%d gold)" % sell_value

	_panel.visible = true
	# Position near the tower in screen space.
	# Wait one frame so the panel calculates its size before positioning.
	await get_tree().process_frame
	# Guard: tower or selection may have changed during the await.
	if not is_instance_valid(tower) or _selected_tower != tower or not _panel.visible:
		return
	var cam := get_viewport().get_camera_2d()
	var screen_pos: Vector2
	if cam:
		screen_pos = (tower.global_position - cam.global_position) * cam.zoom + get_viewport().get_visible_rect().size * 0.5
	else:
		screen_pos = tower.global_position
	var panel_size: Vector2 = _panel.size
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var margin: float = 8.0

	# Try to place to the right of the tower
	var px: float = screen_pos.x + 20
	var py: float = screen_pos.y - panel_size.y * 0.5

	# If it goes off the right edge, flip to the left of the tower
	if px + panel_size.x > viewport_size.x - margin:
		px = screen_pos.x - panel_size.x - 20

	# Clamp left edge
	if px < margin:
		px = margin

	# Clamp top / bottom
	py = clampf(py, margin, viewport_size.y - panel_size.y - margin)

	_panel.global_position = Vector2(px, py)

func deselect() -> void:
	_selected_tower = null
	_panel.visible = false
	_hide_range_indicator()

func _hide_range_indicator() -> void:
	if _range_indicator != null:
		_range_indicator.queue_free()
		_range_indicator = null

func _on_sell_pressed() -> void:
	if _selected_tower == null or not is_instance_valid(_selected_tower):
		deselect()
		return
	var data: TowerData = _selected_tower.tower_data
	var sell_value: int = GameManager.get_sell_value(data.tower_name)
	GameManager.refund_gold(sell_value)
	GameManager.record_tower_sold(data.tower_name)
	var tower_ref := _selected_tower
	deselect()
	emit_signal("tower_sold", tower_ref)

func _input(event: InputEvent) -> void:
	# Uses _input so it runs before PauseMenuUI's _unhandled_input and
	# consumes ESC / clicks when the sell panel is open.
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
			# Dismiss if the click is outside the panel (synchronous check)
			var panel_rect := Rect2(_panel.global_position, _panel.size)
			if not panel_rect.has_point(event.position):
				deselect()
