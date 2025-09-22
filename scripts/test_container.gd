extends Node3D

signal cheese_spawn_complete

@onready var cheese_spawner: Node3D = $cheeseSpawner
@onready var test_container: Node3D = $"."
@onready var follower_camera: Camera3D = $cheeseSpawner/follower_camera
@onready var camera_cooldown: Timer = $Camera_Cooldown
@onready var scene_camera: Camera3D = $"../character/Camera3D"
@onready var topdown_camera: Camera3D = $topdown_camera

const cheese_collectable = preload("res://Scenes/cheese.tscn")
const CHEESE_WHEEL = preload("res://Scenes/cheese_wheel.tscn")

var number_of_cheese_to_spawn = 15

var height = 1
# valid pre-set locations for our cheese to spawn
var master_coordinates = [
	Vector3(-8, height, 12),
	Vector3(0, height, 12),
	Vector3(8, height, 12),  # 3 bottom row
	
	Vector3(-10, height, 10),
	Vector3(-8, height, 10),
	Vector3(-3, height, 10),
	Vector3(0, height, 10),
	Vector3(3, height, 10),
	Vector3(8, height, 10),
	Vector3(10, height, 10), # 7 second row
	
	Vector3(-12, height, 8),
	Vector3(-10, height, 8),
	Vector3(10, height, 8),
	Vector3(12, height, 8), # 4 third row
	
	Vector3(-10, height, 6),
	Vector3(-3, height, 6),
	Vector3(0, height, 6),
	Vector3(3, height, 6),
	Vector3(10, height, 6), # 5 fourth row
	
	Vector3(-12, height, 4),
	Vector3(-10, height, 4),
	Vector3(-3, height, 4),
	Vector3(-1, height, 4),
	Vector3(1, height, 4),
	Vector3(3, height, 4),
	Vector3(10, height, 4),
	Vector3(12, height, 4), # 8 fifth row
	
	Vector3(-10, height, 2),
	Vector3(-3, height, 2),
	Vector3(3, height, 2),
	Vector3(10, height, 2), # 4 sixth row
	
	Vector3(-10, height, -1),
	Vector3(-3, height, -1),
	Vector3(-1, height, -1),
	Vector3(1, height, -1),
	Vector3(3, height, -1),
	Vector3(10, height, -1), # 6 seventh row
	
	Vector3(-10, height, -3),
	Vector3(-8, height, -3),
	Vector3(-6, height, -3),
	Vector3(-3, height, -3),
	Vector3(-1, height, -3),
	Vector3(1, height, -3),
	Vector3(3, height, -3),
	Vector3(6, height, -3),
	Vector3(8, height, -3),
	Vector3(10, height, -3), # 10 eigth row
	
	Vector3(-12, height, -4),
	Vector3(-10, height, -4),
	Vector3(10, height, -4),
	Vector3(12, height, -4), # 4 ninth row
	
	Vector3(-6, height, -6),
	Vector3(-3, height, -6),
	Vector3(3, height, -6),
	Vector3(6, height, -6), # 4 tenth row
	
	Vector3(-12, height, -8),
	Vector3(-10, height, -8),
	Vector3(-8, height, -8),
	Vector3(-6, height, -8),
	Vector3(-1, height, -8),
	Vector3(1, height, -8),
	Vector3(6, height, -8),
	Vector3(8, height, -8),
	Vector3(10, height, -8),
	Vector3(12, height, -8), # 10 eleventh row
	
	Vector3(-10, height, -10),
	Vector3(-8, height, -10),
	Vector3(-4, height, -10),
	Vector3(0, height, -10),
	Vector3(4, height, -10),
	Vector3(8, height, -10),
	Vector3(10, height, -10), # 7 twelfth row
	
	Vector3(-6, height, -12),
	Vector3(-4, height, -12),
	Vector3(4, height, -12),
	Vector3(6, height, -12), # 4 top row
]

var cheese_wheel_spawns = [
	Vector3(-12, 1, 12),
	Vector3(12, 1, 12),
	Vector3(-12, 1, -12),
	Vector3(12, 1, -12)
]

var cheese_wheel_states = {
	Vector3(-12, height, 12): true,  # true = available
	Vector3(12, height, 12): true,
	Vector3(-12, height, -12): true,
	Vector3(12, height, -12): true
}

var valid_coordinates = []

func _ready():
	$"../character/Camera3D".connect("cutscene_complete", _on_cutscene_complete)
	SignalBus.connect("cheese_wheel_eaten", Callable(self, "_on_cheese_wheel_eaten"))

func spawn_cheeses():
	_update_cheese_to_spawn()
	valid_coordinates = master_coordinates.duplicate(true)
	
	topdown_camera.make_current()
	for i in range(number_of_cheese_to_spawn):
		var random_spot = randi_range(0, (valid_coordinates.size() - 1))
		cheese_spawner.global_position = valid_coordinates.pop_at(random_spot)
		
		var cheesy = cheese_collectable.instantiate()
		
		var rotation_offset = randf_range(0, 360)
		cheesy.rotate_y(rotation_offset)
		
		cheese_spawner.add_child(cheesy)
		
		var smoke: GPUParticles3D = cheesy.get_node("GPUParticles3D")
		smoke.set_emitting(true)
		
		cheesy.reparent(test_container)
		camera_cooldown.start(0.2)
		await camera_cooldown.timeout
	
	spawn_cheese_wheels()

func spawn_cheese_wheels():
	valid_coordinates = []
	for coord in cheese_wheel_states.keys():
		if cheese_wheel_states[coord] == false:
			# was eaten, needs to respawn
			valid_coordinates.append(coord)

	if valid_coordinates.is_empty():
		scene_camera.make_current()
		emit_signal("cheese_spawn_complete")
		#nothing to respawn
		return
	
	follower_camera.make_current()
	for coord in valid_coordinates:
		cheese_spawner.global_position = coord

		var cheesy_wheel = CHEESE_WHEEL.instantiate()
		cheese_spawner.add_child(cheesy_wheel)

		var rotation_offset = randf_range(0, 360)
		cheesy_wheel.rotate_y(rotation_offset)

		var smoke: GPUParticles3D = cheesy_wheel.get_node("GPUParticles3D")
		smoke.set_emitting(true)

		cheesy_wheel.reparent(test_container)
		camera_cooldown.start(1)
		await camera_cooldown.timeout

	# ✅ After spawning, reset all wheel states
	for pos in cheese_wheel_spawns:
		cheese_wheel_states[pos] = true

	scene_camera.make_current()
	emit_signal("cheese_spawn_complete")

func _on_cutscene_complete():
	print("ready to spawn cheese")
	spawn_cheeses()

func _on_cheese_wheel_eaten(pos: Vector3):
	if pos in cheese_wheel_states:
		cheese_wheel_states[pos] = false

func _update_cheese_to_spawn() -> void: # using global level variable
	match SignalBus.level:
		1: number_of_cheese_to_spawn = 10
		2: number_of_cheese_to_spawn = 15
		3: number_of_cheese_to_spawn = 20
		_: number_of_cheese_to_spawn = 25
