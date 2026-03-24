extends CanvasLayer

signal tower_selected(tower_data: TowerData)

@export var tower_data_list: Array[TowerData] = []

@onready var _button_container: HBoxContainer = $Panel/HBoxContainer
@onready var _gold_label: Label = $Panel/GoldLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for data in tower_data_list:
		_create_tower_button(data)
	GameManager.gold_changed.connect(_on_gold_changed)
	_update_gold_display(GameManager.gold)

func _create_tower_button(data: TowerData) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(48, 48)
	btn.tooltip_text = "%s - Cost: %d\nDamage: %d\nSpeed: %.1fs" % [data.tower_name, data.cost, int(data.damage), data.attack_speed]
	if data.icon != null:
		btn.icon = data.icon
		btn.expand_icon = true
	btn.text = "%d" % data.cost
	btn.pressed.connect(_on_tower_button_pressed.bind(data))
	_button_container.add_child(btn)

func _on_tower_button_pressed(data: TowerData) -> void:
	if GameManager.gold >= data.cost:
		emit_signal("tower_selected", data)

func _on_gold_changed(new_amount: int) -> void:
	_update_gold_display(new_amount)

func _update_gold_display(amount: int) -> void:
	_gold_label.text = "Gold: %d" % amount
