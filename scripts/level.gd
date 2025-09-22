extends Node3D
# Level.gd

var enemy_scene = preload("res://Scenes/enemy_cat.tscn")
var entrance_smoke = preload("res://Scenes/puff_of_smoke.tscn")

@onready var spawn_point: Node3D = $spawn_point
@onready var gray_overlay: ColorRect = $GrayscaleOverlay
@onready var camera_3d: Camera3D = $character/Camera3D
@onready var character: CharacterBody3D = $character
@onready var death_timeout: Timer = $GrayscaleOverlay/DeathTimeout

@onready var score_label: Label = $"GUI - Control/Score - Label"
@onready var counter_label: Label = $"GUI - Control/Counter - Label"
@onready var post_death_retry: CanvasLayer = $"GUI - Control/PostDeathRetry"

var death_scene = preload("res://Scenes/death.tscn")

# colors for cat albedo
var cat_colors: Array[Color] = [
	Color(1, 0.3, 0.3),   # red
	Color(0.3, 1, 0.3),   # green
	Color(0, 1, 1),   # cyan
	Color(1, 1, 0.3),     # yellow
	Color(1, 0.5, 1)      # pink
]

var current_color_index: int = 0
var height = 0.367219

# random teleport logic had a few bad coordinates that needed removed
var valid_teleport_locations = [
	Vector3(-11.5, height, -8.5),
	Vector3(-11.5, height, -4.5),
	Vector3(-11.5, height, 3.5),
	Vector3(-11.5, height, 7.5),
	Vector3(-11.5, height, 11.5),

	Vector3(-10.5, height, -9.5),
	Vector3(-10.5, height, -8.5),
	Vector3(-10.5, height, -7.5),
	Vector3(-10.5, height, -6.5),
	Vector3(-10.5, height, -5.5),
	Vector3(-10.5, height, -4.5),
	Vector3(-10.5, height, -3.5),
	Vector3(-10.5, height, -2.5),
	Vector3(-10.5, height, -1.5),
	Vector3(-10.5, height, -0.5),
	Vector3(-10.5, height, 0.5),
	Vector3(-10.5, height, 1.5),
	Vector3(-10.5, height, 2.5),
	Vector3(-10.5, height, 3.5),
	Vector3(-10.5, height, 6.5),
	Vector3(-10.5, height, 7.5),
	Vector3(-10.5, height, 8.5),
	Vector3(-10.5, height, 9.5),
	Vector3(-10.5, height, 11.5),

	Vector3(-9.5, height, -10.5),
	Vector3(-9.5, height, -3.5),
	Vector3(-9.5, height, -1.5),
	Vector3(-9.5, height, 1.5),
	Vector3(-9.5, height, 3.5),
	Vector3(-9.5, height, 5.5),
	Vector3(-9.5, height, 9.5),
	Vector3(-9.5, height, 11.5),

	Vector3(-8.5, height, -10.5),
	Vector3(-8.5, height, -9.5),
	Vector3(-8.5, height, -8.5),
	Vector3(-8.5, height, -7.5),
	Vector3(-8.5, height, -6.5),
	Vector3(-8.5, height, -5.5),
	Vector3(-8.5, height, -4.5),
	Vector3(-8.5, height, -3.5),
	Vector3(-8.5, height, -1.5),
	Vector3(-8.5, height, 1.5),
	Vector3(-8.5, height, 3.5),
	Vector3(-8.5, height, 5.5),
	Vector3(-8.5, height, 9.5),
	Vector3(-8.5, height, 10.5),
	Vector3(-8.5, height, 11.5),

	Vector3(-7.5, height, -8.5),
	Vector3(-7.5, height, -3.5),
	Vector3(-7.5, height, -1.5),
	Vector3(-7.5, height, 1.5),
	Vector3(-7.5, height, 3.5),
	Vector3(-7.5, height, 5.5),
	Vector3(-7.5, height, 9.5),
	Vector3(-7.5, height, 11.5),

	Vector3(-6.5, height, -11.5),
	Vector3(-6.5, height, -10.5),
	Vector3(-6.5, height, -9.5),
	Vector3(-6.5, height, -8.5),
	Vector3(-6.5, height, -5.5),
	Vector3(-6.5, height, -4.5),
	Vector3(-6.5, height, -3.5),
	Vector3(-6.5, height, -1.5),
	Vector3(-6.5, height, 1.5),
	Vector3(-6.5, height, 3.5),
	Vector3(-6.5, height, 5.5),
	Vector3(-6.5, height, 9.5),
	Vector3(-6.5, height, 11.5),

	Vector3(-5.5, height, -6.5),
	Vector3(-5.5, height, -3.5),
	Vector3(-5.5, height, -1.5),
	Vector3(-5.5, height, 1.5),
	Vector3(-5.5, height, 3.5),
	Vector3(-5.5, height, 5.5),
	Vector3(-5.5, height, 9.5),
	Vector3(-5.5, height, 11.5),

	Vector3(-4.5, height, -11.5),
	Vector3(-4.5, height, -10.5),
	Vector3(-4.5, height, -8.5),
	Vector3(-4.5, height, -6.5),
	Vector3(-4.5, height, -3.5),
	Vector3(-4.5, height, -1.5),
	Vector3(-4.5, height, 1.5),
	Vector3(-4.5, height, 3.5),
	Vector3(-4.5, height, 5.5),
	Vector3(-4.5, height, 9.5),
	Vector3(-4.5, height, 11.5),

	Vector3(-3.5, height, -10.5),
	Vector3(-3.5, height, -8.5),
	Vector3(-3.5, height, -6.5),
	Vector3(-3.5, height, -5.5),
	Vector3(-3.5, height, -4.5),
	Vector3(-3.5, height, -3.5),
	Vector3(-3.5, height, -2.5),
	Vector3(-3.5, height, -1.5),
	Vector3(-3.5, height, -0.5),
	Vector3(-3.5, height, 0.5),
	Vector3(-3.5, height, 1.5),
	Vector3(-3.5, height, 3.5),
	Vector3(-3.5, height, 4.5),
	Vector3(-3.5, height, 5.5),
	Vector3(-3.5, height, 6.5),
	Vector3(-3.5, height, 7.5),
	Vector3(-3.5, height, 8.5),
	Vector3(-3.5, height, 9.5),
	Vector3(-3.5, height, 11.5),
	
	Vector3(-2.5, height, -10.5),
	Vector3(-2.5, height, -8.5),
	Vector3(-2.5, height, -6.5),
	Vector3(-2.5, height, -3.5),
	Vector3(-2.5, height, -1.5),
	Vector3(-2.5, height, 1.5),
	Vector3(-2.5, height, 3.5),
	Vector3(-2.5, height, 5.5),
	Vector3(-2.5, height, 7.5),
	Vector3(-2.5, height, 9.5),
	Vector3(-2.5, height, 11.5),

	Vector3(-1.5, height, -10.5),
	Vector3(-1.5, height, -8.5),
	Vector3(-1.5, height, -6.5),
	Vector3(-1.5, height, -3.5),
	Vector3(-1.5, height, -1.5),
	Vector3(-1.5, height, 1.5),
	Vector3(-1.5, height, 3.5),
	Vector3(-1.5, height, 5.5),
	Vector3(-1.5, height, 9.5),
	Vector3(-1.5, height, 11.5),

	Vector3(-0.5, height, -10.5),
	Vector3(-0.5, height, -8.5),
	Vector3(-0.5, height, -6.5),
	Vector3(-0.5, height, -3.5),
	Vector3(-0.5, height, -1.5),
	Vector3(-0.5, height, 1.5),
	Vector3(-0.5, height, 3.5),
	Vector3(-0.5, height, 5.5),
	Vector3(-0.5, height, 7.5),
	Vector3(-0.5, height, 9.5),
	Vector3(-0.5, height, 11.5),

	Vector3(0.5, height, -10.5),
	Vector3(0.5, height, -8.5),
	Vector3(0.5, height, -6.5),
	Vector3(0.5, height, -3.5),
	Vector3(0.5, height, -1.5),
	Vector3(0.5, height, 1.5),
	Vector3(0.5, height, 3.5),
	Vector3(0.5, height, 5.5),
	Vector3(0.5, height, 7.5),
	Vector3(0.5, height, 9.5),
	Vector3(0.5, height, 11.5),

	Vector3(1.5, height, -10.5),
	Vector3(1.5, height, -8.5),
	Vector3(1.5, height, -6.5),
	Vector3(1.5, height, -3.5),
	Vector3(1.5, height, -1.5),
	Vector3(1.5, height, 1.5),
	Vector3(1.5, height, 3.5),
	Vector3(1.5, height, 5.5),
	Vector3(1.5, height, 7.5),
	Vector3(1.5, height, 9.5),
	Vector3(1.5, height, 11.5),

	Vector3(2.5, height, -10.5),
	Vector3(2.5, height, -8.5),
	Vector3(2.5, height, -3.5),
	Vector3(2.5, height, -1.5),
	Vector3(2.5, height, 1.5),
	Vector3(2.5, height, 3.5),
	Vector3(2.5, height, 5.5),
	Vector3(2.5, height, 7.5),
	Vector3(2.5, height, 9.5),
	Vector3(2.5, height, 11.5),

	Vector3(3.5, height, -10.5),
	Vector3(3.5, height, -8.5),
	Vector3(3.5, height, -6.5),
	Vector3(3.5, height, -3.5),
	Vector3(3.5, height, -1.5),
	Vector3(3.5, height, 1.5),
	Vector3(3.5, height, 3.5),
	Vector3(3.5, height, 5.5),
	Vector3(3.5, height, 7.5),
	Vector3(3.5, height, 9.5),
	Vector3(3.5, height, 11.5),

	Vector3(4.5, height, -10.5),
	Vector3(4.5, height, -8.5),
	Vector3(4.5, height, -6.5),
	Vector3(4.5, height, -3.5),
	Vector3(4.5, height, -1.5),
	Vector3(4.5, height, 1.5),
	Vector3(4.5, height, 3.5),
	Vector3(4.5, height, 5.5),
	Vector3(4.5, height, 9.5),
	Vector3(4.5, height, 11.5),

	Vector3(5.5, height, -10.5),
	Vector3(5.5, height, -8.5),
	Vector3(5.5, height, -6.5),
	Vector3(5.5, height, -3.5),
	Vector3(5.5, height, -1.5),
	Vector3(5.5, height, 1.5),
	Vector3(5.5, height, 3.5),
	Vector3(5.5, height, 5.5),
	Vector3(5.5, height, 9.5),
	Vector3(5.5, height, 11.5),
	
	Vector3(6.5, height, -10.5),
	Vector3(6.5, height, -8.5),
	Vector3(6.5, height, -6.5),
	Vector3(6.5, height, -3.5),
	Vector3(6.5, height, -1.5),
	Vector3(6.5, height, 1.5),
	Vector3(6.5, height, 3.5),
	Vector3(6.5, height, 5.5),
	Vector3(6.5, height, 9.5),
	Vector3(6.5, height, 11.5),

	Vector3(7.5, height, -8.5),
	Vector3(7.5, height, -6.5),
	Vector3(7.5, height, -3.5),
	Vector3(7.5, height, -1.5),
	Vector3(7.5, height, 1.5),
	Vector3(7.5, height, 3.5),
	Vector3(7.5, height, 5.5),
	Vector3(7.5, height, 9.5),
	Vector3(7.5, height, 11.5),

	Vector3(8.5, height, -10.5),
	Vector3(8.5, height, -8.5),
	Vector3(8.5, height, -6.5),
	Vector3(8.5, height, -3.5),
	Vector3(8.5, height, -1.5),
	Vector3(8.5, height, 1.5),
	Vector3(8.5, height, 3.5),
	Vector3(8.5, height, 5.5),
	Vector3(8.5, height, 9.5),
	Vector3(8.5, height, 11.5),

	Vector3(9.5, height, -10.5),
	Vector3(9.5, height, -8.5),
	Vector3(9.5, height, -6.5),
	Vector3(9.5, height, -3.5),
	Vector3(9.5, height, -1.5),
	Vector3(9.5, height, 1.5),
	Vector3(9.5, height, 3.5),
	Vector3(9.5, height, 5.5),
	Vector3(9.5, height, 7.5),
	Vector3(9.5, height, 9.5),
	Vector3(9.5, height, 11.5),

	Vector3(10.5, height, -10.5),
	Vector3(10.5, height, -8.5),
	Vector3(10.5, height, -6.5),
	Vector3(10.5, height, -3.5),
	Vector3(10.5, height, -1.5),
	Vector3(10.5, height, 1.5),
	Vector3(10.5, height, 3.5),
	Vector3(10.5, height, 5.5),
	Vector3(10.5, height, 7.5),
	Vector3(10.5, height, 9.5),
	Vector3(10.5, height, 11.5),

	Vector3(11.5, height, -10.5),
	Vector3(11.5, height, -8.5),
	Vector3(11.5, height, -6.5),
	Vector3(11.5, height, -3.5),
	Vector3(11.5, height, 3.5),
	Vector3(11.5, height, 5.5),
	Vector3(11.5, height, 7.5),
	Vector3(11.5, height, 9.5),
	Vector3(11.5, height, 11.5),
	]

func _ready():
	$character/Camera3D.connect("cutscene_spawn_enemy", _on_cutscene_spawn_enemy)
	SignalBus.player_dead.connect(_on_player_dead)
	gray_overlay.material.set("shader_parameter/desaturate_amount", 0.0)

func _on_player_dead() -> void:
	# 1. Greyscale effect, hide UI
	gray_overlay.show()
	score_label.hide()
	counter_label.hide()
	
	# 2. Pause the game
	get_tree().paused = true
	
	# 3. Camera zoom-in
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # keeps running while paused
	tween.tween_property(camera_3d, "fov", 35.0, 0.3).set_ease(Tween.EASE_IN_OUT)

	# 4. Puff of smoke + remove character
	var smoke = entrance_smoke.instantiate()
	get_tree().current_scene.add_child(smoke)
	smoke.global_transform.origin = character.global_transform.origin

	# pause for dramatic effect
	death_timeout.start(0.5)
	await death_timeout.timeout
	smoke.set_emitting(true)
	
	camera_3d.reparent($".", true)
	character.queue_free()

	# 5. Play death overlay animation
	var death_instance = death_scene.instantiate()
	gray_overlay.add_child(death_instance)
	var anim_player: AnimationPlayer = death_instance.get_node("AnimationPlayer")
	anim_player.play("death")
	
	await anim_player.animation_finished

	# 6. Bring score to center
	score_label.show()
	$"GUI - Control/Score - Label/AnimationPlayer".play("show_score")
	
	# 7. Show "Play Again" button
	post_death_retry.show()

func _on_cutscene_spawn_enemy():
	var enemy = enemy_scene.instantiate()
	var smoke = entrance_smoke.instantiate()
	add_child(smoke)
	add_child(enemy)
	
	enemy.global_position = spawn_point.global_position
	smoke.global_position = spawn_point.global_position
	
	# Rotate + scale enemy
	enemy.rotate_y(deg_to_rad(90))
	enemy.scale = Vector3(0.03, 0.03, 0.03)
	
	# Pick the cat color
	var color = _set_enemy_color(enemy)
	
	# Tint smoke to match
	_set_smoke_color(smoke, color)
	
	# Emit smoke after color is set
	smoke.set_emitting(true)
	
	print("👹 Enemy spawned during cutscene")
	
	await get_tree().create_timer(smoke.lifetime).timeout
	smoke.queue_free()

func _set_enemy_color(enemy: Node3D) -> Color:
	var idle_cat: MeshInstance3D = enemy.get_node("Sketchfab_model/IdleCat")
	var object_9: MeshInstance3D = enemy.get_node("Sketchfab_model/c81d676aaf394e9e99fa643affe79c8b_fbx/Object_2/RootNode/Armature/Object_6/Skeleton3D/Object_9")

	var color = cat_colors[current_color_index]
	current_color_index = (current_color_index + 1) % cat_colors.size()

	if idle_cat and idle_cat.get_surface_override_material_count() > 0:
		var mat = idle_cat.get_active_material(0).duplicate()
		mat.albedo_color = color
		idle_cat.set_surface_override_material(0, mat)
		print("🔵 [SET] Cat", enemy.name, "Idle color =", mat.albedo_color)

	if object_9 and object_9.get_surface_override_material_count() > 0:
		var mat2 = object_9.get_active_material(0).duplicate()
		mat2.albedo_color = color
		object_9.set_surface_override_material(0, mat2)
		print("🔵 [SET] Cat", enemy.name, "Object_9 color =", mat2.albedo_color)

	# ✅ Cache this cat's unique randomized "originals" after colors are applied
	enemy.call_deferred("_cache_original_materials")

	return color


func _set_smoke_color(smoke: Node3D, color: Color) -> void:
	var mat: ParticleProcessMaterial = smoke.process_material.duplicate()
	mat.color = color
	smoke.process_material = mat
