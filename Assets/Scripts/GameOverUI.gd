extends CanvasLayer

const GAME_SCENE_PATH = "res://Assets/Scene/scene.tscn"
const MAIN_MENU_PATH = "res://Assets/Scene/main_menu.tscn"

@onready var _panel: Control = $Panel
@onready var _new_game_btn: Button = $Panel/VBoxContainer/NewGameButton
@onready var _restart_btn: Button = $Panel/VBoxContainer/RestartButton
@onready var _main_menu_btn: Button = $Panel/VBoxContainer/MainMenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.hide()
	_new_game_btn.pressed.connect(_on_new_game_pressed)
	_restart_btn.pressed.connect(_on_restart_pressed)
	_main_menu_btn.pressed.connect(_on_main_menu_pressed)

func show_game_over() -> void:
	_panel.show()
	get_tree().paused = true

func _on_new_game_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
