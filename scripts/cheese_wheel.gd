extends Node3D

@export var rotation_speed : float = 3.0 # Degrees per physics frame
@export var float_speed : float = 2.0 # Speed of floating up and down
@export var float_amplitude : float = 0.3 # How high/low it moves

var base_y : float = 0.0
var time_passed : float = 0.0

func _ready() -> void:
	base_y = global_transform.origin.y

func _physics_process(delta: float) -> void:
	# Rotate the cheese around the Y-axis
	rotate_y(deg_to_rad(rotation_speed))

	# Update time
	time_passed += delta * float_speed

	# Calculate new Y position using sine wave
	var new_y = base_y + sin(time_passed) * float_amplitude
	global_transform.origin.y = new_y


func _on_wheel_body_entered(body: Node3D) -> void:
		if body.name == 'character':
			SignalBus.emit_signal("cheese_wheel_eaten", global_position.round()) # or store original spawn pos
			print(global_position.round())
			print("Enable Power Up")
			var power_up_roll = randi_range(1, 4)
			if power_up_roll == 1:
				SignalBus.emit_signal("superspeed")
				print("superspeed")
			elif power_up_roll == 2:
				SignalBus.emit_signal("magnet")
				print("magnet")
			elif power_up_roll == 3:
				SignalBus.emit_signal("teleport")
				print("teleport")
			elif power_up_roll == 4: # could use else but we'll do this in case we add more in future
				SignalBus.emit_signal("eat")
				print("eat")
			queue_free()
