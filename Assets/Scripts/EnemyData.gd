# EnemyData.gd
class_name EnemyData
extends Resource

@export var enemy_name: String = "Basic"
@export var scene: PackedScene
@export var speed: float = 60.0
@export var health: float = 40.0
@export var damage: int = 1
@export var reward: int = 10
