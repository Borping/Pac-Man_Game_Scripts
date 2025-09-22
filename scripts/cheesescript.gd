extends Node3D

@export var rotation_speed : float = 3.0 # Degrees per physics frame
@export var float_speed : float = 2.0    # Speed of floating up and down
@export var float_amplitude : float = 0.3 # How high/low it moves

@export var magnet_pull_speed : float = 6.0
@export var rise_height : float = 1.0    # How far up the cheese rises
@export var rise_time : float = 0.3      # How long the rise takes

var rising: bool = false
var magnetized: bool = false
var player: Node3D = null

var base_y : float = 0.0
var time_passed : float = 0.0

func _ready() -> void:
	base_y = global_transform.origin.y

func _physics_process(delta: float) -> void:
	# Always rotate
	rotate_y(deg_to_rad(rotation_speed))

	# Idle bobbing only when not rising/magnetized
	if not rising and not magnetized:
		time_passed += delta * float_speed
		var new_y = base_y + sin(time_passed) * float_amplitude
		global_transform.origin.y = new_y

	# Magnetized: lerp toward player
	if magnetized and player:
		var pos = global_transform.origin
		var target = player.global_transform.origin
		global_transform.origin = pos.lerp(target, magnet_pull_speed * delta)


func _on_cheese_body_entered(body):
	if body.name == "character":
		SignalBus.emit_signal("cheese_collected")
		queue_free()


func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.name == "MagnetArea" and not rising and not magnetized:
		player = area.get_parent()
		rising = true

		var start_pos = global_transform.origin
		var target_pos = start_pos + Vector3(0, rise_height, 0)

		var tween = create_tween()
		tween.tween_property(self, "global_transform:origin", target_pos, rise_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

		tween.finished.connect(func():
			rising = false
			magnetized = true
		)
