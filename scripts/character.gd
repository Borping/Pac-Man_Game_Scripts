extends CharacterBody3D

var SPEED = 5.0
var normal_speed = 5.0

var boosted = false
var magnet_active = false
var has_teleport = false
var is_bonked = false
var first_input = true
var active_score_labels := 0  # how many floating labels are alive
var smoketscn = preload("res://Scenes/puff_of_smoke.tscn")
var ScoreLabel = preload("res://Scenes/3d_score_label.tscn")

signal player_teleported

# general
@onready var visual := $Sketchfab_model
@onready var animation_player := $Sketchfab_model/RAT_fbx/AnimationPlayer
@onready var rat_mesh: Node3D = $Sketchfab_model/RAT_fbx
@onready var bonk_raycast: RayCast3D = $Sketchfab_model/bonked
@onready var idle_mesh: MeshInstance3D = $Sketchfab_model/IdleMesh
# speed powerup
@onready var speed_timer: Timer = $SpeedTimer
@onready var camera_3d: Camera3D = $Camera3D
# magnet powerup
@onready var magnet_timer: Timer = $MagnetArea/MagnetTimer
@onready var magnet_area: Area3D = $MagnetArea
@onready var magnet_mesh: Node3D = $MagnetArea/Magnet
@onready var magnet_hitbox: CollisionShape3D = $MagnetArea/MagnetHitbox
# tp powerup
@onready var tp_keybind_label: Label = $"../GUI - Control/TPKeybind"
@onready var gridmap: GridMap = $"../NavigationRegion3D/GridMap"
@onready var smoke_timer: Timer = $SmokeTimer
@onready var invincibility_blink: Timer = $InvincibilityBlink
@export var player_is_invisible: bool = false
# eat powerup
@onready var score_animation_player: AnimationPlayer = $Label3D/ScoreAnimationPlayer

func _ready() -> void:
	rat_mesh.hide()
	idle_mesh.show()

	# signals
	SignalBus.connect("superspeed", Callable(self, "_on_superspeed"))
	SignalBus.connect("magnet", Callable(self, "_on_magnet"))
	SignalBus.connect("teleport", Callable(self, "_on_teleport_powerup"))
	SignalBus.connect("display_score_up", Callable(self, "_on_score_up"))
	

	# timers
	speed_timer.one_shot = true
	speed_timer.wait_time = 10.0

	magnet_timer.one_shot = true
	magnet_timer.wait_time = 10.0

	# magnet starts off
	magnet_area.set_collision_layer_value(1, false)
	magnet_mesh.hide()
	
	tp_keybind_label.hide()

# -------------------------------
# SUPERSPEED
# -------------------------------
func _on_superspeed() -> void:
	if not boosted:
		create_tween().tween_property(camera_3d, "fov", 105.0, 0.2).set_ease(Tween.EASE_IN_OUT)
		boosted = true
		normal_speed = SPEED
		SPEED *= 2.0
		speed_timer.start()
		print("Superspeed activated! Speed:", SPEED)
	else:
		speed_timer.start()
		print("Superspeed refreshed!")

func _on_speed_timer_timeout() -> void:
	create_tween().tween_property(camera_3d, "fov", 90, 0.5).set_ease(Tween.EASE_IN_OUT)
	SPEED = normal_speed
	boosted = false
	print("Superspeed expired. Speed:", SPEED)

# -------------------------------
# MAGNET
# -------------------------------
func _on_magnet() -> void:
	if not magnet_active:
		magnet_active = true
		magnet_area.set_collision_layer_value(1, true)
		magnet_mesh.show()
		magnet_timer.start()
		print("Magnet activated!")
	else:
		magnet_timer.start()
		print("Magnet refreshed!")

func _on_magnet_timer_timeout() -> void:
	magnet_active = false
	magnet_area.set_collision_layer_value(1, false)
	magnet_mesh.hide()
	print("Magnet expired!")
# -------------------------------
# TELEPORT
# -------------------------------
func _on_teleport_powerup() -> void:
	if not has_teleport:
		has_teleport = true
		tp_keybind_label.show()
		print("Teleport power-up acquired!")
	else:
		print("Already have a teleport charge, ignoring.")

func _use_teleport() -> void:
	if not has_teleport:
		return

	# Consume the charge
	has_teleport = false
	tp_keybind_label.hide()

	# reference to level script
	var level = get_node("/root/Level") # adjust path if your Level node is named differently

	# Pick a random entry from the list
	var target_position: Vector3 = level.valid_teleport_locations.pick_random()

	# Adjust Y to keep the player’s current height
	target_position.y = global_transform.origin.y

	# Teleport
	global_transform.origin = target_position
	print("Teleported to:", target_position)

	# instantiate the smoke bubble, teleport it to the player, and destroy it after 1s
	var smoke = smoketscn.instantiate()
	get_tree().current_scene.add_child(smoke)
	smoke.global_transform.origin = self.global_transform.origin
	
	_invincibility_blink()
	emit_signal("player_teleported")
	
	smoke.set_emitting(true)
	smoke_timer.start(1.0)
	await smoke_timer.timeout
	smoke.queue_free()

func _invincibility_blink() -> void:
	player_is_invisible = true
	for i in range(5):
		self.hide()
		invincibility_blink.start()
		await invincibility_blink.timeout
		self.show()
		invincibility_blink.start()
		await invincibility_blink.timeout
	player_is_invisible = false

func _unhandled_input(event: InputEvent) -> void:
	if has_teleport and event.is_action_pressed("teleport"): # add 'teleport' action in Input Map bound to E
		_use_teleport()

# -------------------------------
# EAT
# -------------------------------
func _on_score_up() -> void:
	print("displaying score up from eating cat")

	var label = ScoreLabel.instantiate()
	label.score_label = get_node("/root/Level/GUI - Control/Score - Label")
	add_child(label)

	# make sure it starts above the rat’s head
	label.transform.origin = Vector3(0, 2.0, 0)

	var anim_player: AnimationPlayer = label.get_node("ScoreAnimationPlayer")

	# calculate delay based on active labels
	var delay := 0.5 * active_score_labels
	active_score_labels += 1

	# defer animation start if necessary
	if delay > 0:
		await get_tree().create_timer(delay).timeout

	if is_instance_valid(anim_player):
		anim_player.play("eat_score")
		anim_player.animation_finished.connect(func(anim_name: String) -> void:
			if anim_name == "eat_score":
				if is_instance_valid(label):
					label.queue_free()
				active_score_labels = max(0, active_score_labels - 1)
		)
	else:
		# fallback if no anim player found
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(label):
			label.queue_free()
		active_score_labels = max(0, active_score_labels - 1)
	
# -------------------------------
# MOVEMENT
# -------------------------------
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if bonk_raycast.is_colliding() and not is_bonked:
		is_bonked = true
		rat_mesh.hide()
		idle_mesh.show()

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := Vector3.ZERO

	if input_dir != Vector2.ZERO:
		if first_input:
			animation_player.play("Run")
			rat_mesh.show()
			idle_mesh.hide()
			first_input = false

		if is_bonked:
			is_bonked = false
			rat_mesh.show()
			idle_mesh.hide()
			animation_player.play("Run")

		if abs(input_dir.x) > abs(input_dir.y):
			if input_dir.x > 0 and not $EastRayCast.is_colliding() and not $EastRayCast2.is_colliding():
				direction = Vector3(1, 0, 0)
				visual.rotation.y = deg_to_rad(180)
			elif input_dir.x < 0 and not $WestRayCast.is_colliding() and not $WestRayCast2.is_colliding():
				direction = Vector3(-1, 0, 0)
				visual.rotation.y = deg_to_rad(0)
		else:
			if input_dir.y > 0 and not $SouthRayCast.is_colliding() and not $SouthRayCast2.is_colliding():
				direction = Vector3(0, 0, 1)
				visual.rotation.y = deg_to_rad(90)
			elif input_dir.y < 0 and not $NorthRayCast.is_colliding() and not $NorthRayCast2.is_colliding():
				direction = Vector3(0, 0, -1)
				visual.rotation.y = deg_to_rad(-90)

	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

	move_and_slide()
