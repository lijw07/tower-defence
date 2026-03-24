extends Node2D

@onready var _castle: Area2D = $CastleBlue
@onready var _castle_tower: Node2D = $CastleTowerBlue
@onready var _game_over_ui: CanvasLayer = $GameOverUI
@onready var _tower_shop: CanvasLayer = $TowerShopUI
@onready var _placement_manager: Node = $PlacementManager

func _ready() -> void:
	_castle.game_over.connect(_game_over_ui.show_game_over)
	_tower_shop.tower_selected.connect(_placement_manager.begin_placement)
	_placement_manager.register_obstacle(_castle.global_position)
	_placement_manager.register_obstacle(_castle_tower.global_position)
	GameManager.reset()
