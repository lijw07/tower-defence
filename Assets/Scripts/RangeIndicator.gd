extends Node2D
## Draws a dashed circle to visualise a tower's attack range.
## Add as a child of any node and call set_radius() to configure.

var _radius: float = 0.0
var _color: Color = Color(1.0, 1.0, 1.0, 0.35)
var _fill_color: Color = Color(1.0, 1.0, 1.0, 0.06)
var _segments: int = 48

func set_radius(r: float) -> void:
	_radius = r
	queue_redraw()

func set_color(outline: Color, fill: Color = Color.TRANSPARENT) -> void:
	_color = outline
	_fill_color = fill
	queue_redraw()

func _draw() -> void:
	if _radius <= 0.0:
		return
	# Filled circle (very subtle)
	if _fill_color.a > 0.0:
		var fill_points := PackedVector2Array()
		for i in range(_segments + 1):
			var angle: float = TAU * float(i) / float(_segments)
			fill_points.append(Vector2(cos(angle), sin(angle)) * _radius)
		draw_colored_polygon(fill_points, _fill_color)
	# Dashed outline
	var _dash_length: float = TAU * _radius / float(_segments)
	for i in range(_segments):
		if i % 2 == 1:
			continue  # skip every other segment for dashed look
		var a0: float = TAU * float(i) / float(_segments)
		var a1: float = TAU * float(i + 1) / float(_segments)
		var p0 := Vector2(cos(a0), sin(a0)) * _radius
		var p1 := Vector2(cos(a1), sin(a1)) * _radius
		draw_line(p0, p1, _color, 1.0)
