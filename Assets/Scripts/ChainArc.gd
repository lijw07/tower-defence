extends Node2D
## Visual lightning chain arc that draws jagged lines between hit points
## and fades out over a short duration.

var _points: Array[Vector2] = []
var _jitter_points: Array = []  # Array of Array[Vector2] (one jagged path per segment)
var _lifetime: float = 0.25
var _elapsed: float = 0.0
const JITTER_COUNT: int = 4  # intermediate jitter points per segment
const JITTER_AMOUNT: float = 8.0

func setup(points: Array[Vector2]) -> void:
	_points = points
	# Pre-compute jagged paths for each segment
	for i in range(_points.size() - 1):
		var from: Vector2 = _points[i]
		var to: Vector2 = _points[i + 1]
		var segment: Array[Vector2] = [from]
		for j in range(1, JITTER_COUNT + 1):
			var t: float = float(j) / float(JITTER_COUNT + 1)
			var mid: Vector2 = from.lerp(to, t)
			var perp: Vector2 = (to - from).normalized().rotated(PI / 2.0)
			mid += perp * randf_range(-JITTER_AMOUNT, JITTER_AMOUNT)
			segment.append(mid)
		segment.append(to)
		_jitter_points.append(segment)
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if _jitter_points.is_empty():
		return
	var alpha: float = 1.0 - (_elapsed / _lifetime)
	var color_core := Color(0.9, 0.95, 1.0, alpha)
	var color_glow := Color(0.4, 0.6, 1.0, alpha * 0.5)

	for segment in _jitter_points:
		# Draw glow (thicker, dimmer)
		for k in range(segment.size() - 1):
			draw_line(segment[k], segment[k + 1], color_glow, 3.0)
		# Draw core (thinner, brighter)
		for k in range(segment.size() - 1):
			draw_line(segment[k], segment[k + 1], color_core, 1.0)
