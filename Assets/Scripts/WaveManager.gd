# WaveManager.gd
extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed

@export var waves: Array = []

var _path: Path2D
var _current_wave_index: int = 0
var _enemies_alive: int = 0
var _is_spawning: bool = false

func _ready() -> void:
	_path = get_parent() as Path2D
	start_next_wave()

func start_next_wave() -> void:
	if _current_wave_index >= waves.size():
		emit_signal("all_waves_completed")
		return
	var wave = waves[_current_wave_index]
	print("Starting wave ", wave.wave_number)
	emit_signal("wave_started", wave.wave_number)
	_is_spawning = true
	await _run_wave(wave)
	_is_spawning = false

func _run_wave(wave) -> void:
	for i in range(wave.entries.size()):
		await _spawn_batch(wave.entries[i])
		if i < wave.entries.size() - 1:
			await get_tree().create_timer(wave.time_between_batches).timeout

func _spawn_batch(entry) -> void:
	for i in range(entry.count):
		_spawn_enemy(entry.enemy_data)
		await get_tree().create_timer(entry.spawn_interval).timeout

func _spawn_enemy(data) -> void:
	if data == null or data.scene == null:
		push_error("WaveManager: EnemyData or its scene is null!")
		return
	var path_follow := PathFollow2D.new()
	path_follow.loop = false
	_path.add_child(path_follow)
	var enemy = data.scene.instantiate()
	path_follow.add_child(enemy)
	enemy.initialize(data)
	_enemies_alive += 1
	enemy.tree_exited.connect(_on_enemy_removed)

func _on_enemy_removed() -> void:
	_enemies_alive -= 1
	_check_wave_complete()

func _check_wave_complete() -> void:
	if not _is_spawning and _enemies_alive <= 0:
		print("Wave ", waves[_current_wave_index].wave_number, " complete!")
		emit_signal("wave_completed", waves[_current_wave_index].wave_number)
		_current_wave_index += 1
		start_next_wave()
