extends Control

const GAME_SCENE_PATH = "res://Assets/Scene/scene.tscn"

@onready var _play_btn: Button = $VBoxContainer/PlayButton

func _ready() -> void:
	_play_btn.pressed.connect(_on_play_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)
