extends Node3D

signal cutscene_spawn_enemy
signal cutscene_complete

@onready var test_container: Node3D = $"../../testContainer"
@onready var camera: Node3D = $"."

@export var cutscene_position: Vector3
@export var cutscene_rotation: Vector3 # degrees

func _ready() -> void:
	SignalBus.level_is_transitioning.connect(_on_transition)
	process_mode = Node.PROCESS_MODE_ALWAYS
	camera.process_mode = Node.PROCESS_MODE_ALWAYS

func play_cutscene() -> void:
	# original position/rotation
	var original_transform: Transform3D = camera.global_transform

	# Pause AFTER we configure tweens
	get_tree().paused = true

	# Create tween that still works while paused
	var tween = create_tween_always()
	tween.tween_property(camera, "rotation_degrees", cutscene_rotation, 0.5)
	tween.tween_property(camera, "global_position", cutscene_position, 0.5)

	await tween.finished

	print("Spawning enemy...")
	emit_signal("cutscene_spawn_enemy")

	# Timer that still runs while paused
	var intro_scene = preload("res://scenes/approaches.tscn").instantiate()
	get_tree().root.add_child(intro_scene)
	
	await get_tree().create_timer(2.0, true).timeout

	# Tween back to original position
	var tween_back = create_tween_always()
	tween_back.tween_property(camera, "global_transform", original_transform, 2.0)
	await tween_back.finished

	print("✅ Cutscene finished, back to gameplay!")
	emit_signal("cutscene_complete")
	
	await test_container.cheese_spawn_complete
	get_tree().paused = false
	SignalBus.emit_signal("pausable")

func create_tween_always() -> Tween:
	var tween := get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # 🔑 ensures tween runs while paused
	return tween

func _on_transition() -> void:
	play_cutscene()
	print("played cut")
