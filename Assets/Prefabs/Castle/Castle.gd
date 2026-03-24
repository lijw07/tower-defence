extends Area2D

signal game_over

@export var max_lives: int = 3
var lives: int

func _ready():
	lives = max_lives
	area_entered.connect(_on_area_entered)

func _on_area_entered(area):
	if area.is_in_group("enemies"):
		var dmg = area.get("damage")
		if dmg != null:
			lives -= dmg
			var parent = area.get_parent()
			if parent is PathFollow2D:
				parent.queue_free()
			else:
				area.queue_free()
			print("Lives remaining: ", lives)
			if lives <= 0:
				emit_signal("game_over")
