extends Node3D

@export var rotation_speed : float = 3.0 # Degrees per physics frame

func _physics_process(_delta: float) -> void:
	# Rotate the cheese around the Y-axis
	rotate_y(deg_to_rad(rotation_speed))
