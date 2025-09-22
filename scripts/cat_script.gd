extends CharacterBody3D

var puff_of_smoke = preload("res://Scenes/puff_of_smoke.tscn")

@onready var nav_agent = $NavigationAgent3D
@onready var vision_ray: RayCast3D = $Sketchfab_model/RayCast3D
@onready var grace_timer: Timer = $Grace
@onready var chase_timeout: Timer = $ChaseTimeout
@onready var alert: Sprite3D = $Alert

@onready var idle_mesh: MeshInstance3D = $Sketchfab_model/IdleCat
@onready var active_mesh: Node3D = $Sketchfab_model/c81d676aaf394e9e99fa643affe79c8b_fbx/Object_2/RootNode/Armature/Object_6
@onready var anim_player: AnimationPlayer = $Sketchfab_model/AnimationPlayer
@onready var sketchfab_model: Node3D = $Sketchfab_model

@onready var idle_cat: MeshInstance3D = $Sketchfab_model/IdleCat
@onready var object_9: MeshInstance3D = $Sketchfab_model/c81d676aaf394e9e99fa643affe79c8b_fbx/Object_2/RootNode/Armature/Object_6/Skeleton3D/Object_9
@onready var spawn_point: Node3D = $"../spawn_point"

var SPEED = 5.5
var active = false
var mode: String = "idle" # "idle", "wander", "chase"
var player: Node3D = null
var needs_new_wander_point = false
var player_is_hit = false

# anti-stuck
var last_pos: Vector3
var stuck_time: float = 0.0
var stuck_threshold: float = 3.0 # seconds
var stuck_radius: float = 1.0    # meters
var character

# materials
var original_idle_material : StandardMaterial3D = null
var original_object9_material : StandardMaterial3D = null

var eat_blue_idle : StandardMaterial3D = null
var eat_blue_object9 : StandardMaterial3D = null
var eat_white_idle : StandardMaterial3D = null
var eat_white_object9 : StandardMaterial3D = null

# eat powerup
var edible: bool = false
var _edible_time_left: float = 0.0
const EAT_DURATION: float = 8.0
const BLINK_INTERVAL: float = 0.3
var blink_active: bool = false

func _ready() -> void:
	# connect once
	SignalBus.connect("eat", Callable(self, "_on_eat_powerup"))

	idle_mesh.show()
	active_mesh.hide()

	character = get_node("/root/Level/character") # adjust path if needed
	if character:
		character.connect("player_teleported", Callable(self, "_on_player_teleported"))

	last_pos = global_position

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

# ---------------- CACHE ORIGINAL MATERIALS ----------------
func _cache_original_materials() -> void:
	# Grab whatever material is currently active on each mesh. Prefer surface override, then active material.
	var mat_idle = idle_cat.get_surface_override_material(0)
	if mat_idle == null:
		mat_idle = idle_cat.get_active_material(0)
	if mat_idle == null:
		# create a fallback material so we always have something
		mat_idle = StandardMaterial3D.new()
		mat_idle.albedo_color = Color(1, 1, 1)

	var mat_obj9 = object_9.get_surface_override_material(0)
	if mat_obj9 == null:
		mat_obj9 = object_9.get_active_material(0)
	if mat_obj9 == null:
		mat_obj9 = StandardMaterial3D.new()
		mat_obj9.albedo_color = Color(1, 1, 1)

	# Duplicate to own unique originals and apply as surface overrides so the mesh uses them exclusively.
	original_idle_material = mat_idle.duplicate()
	original_object9_material = mat_obj9.duplicate()

	idle_cat.set_surface_override_material(0, original_idle_material)
	object_9.set_surface_override_material(0, original_object9_material)

	print("📦 [CACHE] Cat", name, "Idle color =", original_idle_material.albedo_color)
	print("📦 [CACHE] Cat", name, "Object_9 color =", original_object9_material.albedo_color)

	# Prebuild eat versions from these originals (safe because originals are valid now)
	eat_blue_idle = original_idle_material.duplicate()
	eat_blue_idle.albedo_color = Color(0.0, 0.2, 1.0)

	eat_blue_object9 = original_object9_material.duplicate()
	eat_blue_object9.albedo_color = Color(0.0, 0.2, 1.0)

	eat_white_idle = original_idle_material.duplicate()
	eat_white_idle.albedo_color = Color(1, 1, 1)

	eat_white_object9 = original_object9_material.duplicate()
	eat_white_object9.albedo_color = Color(1, 1, 1)
# ---------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not active:
		return

	if needs_new_wander_point:
		needs_new_wander_point = false
		_pick_new_wander_point()

	# update chase target
	if mode == "chase" and player:
		update_target_location(player.global_transform.origin)

	# movement
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * SPEED

	velocity = velocity.move_toward(new_velocity, 0.20)
	move_and_slide()

	if velocity.length() > 0.1:
		_snap_rotation_to_direction(velocity)

	# vision
	if vision_ray.is_colliding():
		var collider = vision_ray.get_collider()
		if collider and player and collider == player and !character.player_is_invisible and !edible:
			if mode != "chase":
				print("🔴 Switching to CHASE mode")
				mode = "chase"
				alert.show()
			chase_timeout.start(8.0)

	# anti-stuck
	_check_stuck(delta)

func _on_eat_powerup() -> void:
	# Immediately refresh timer and run blink routine (safe to call multiple times)
	_edible_time_left = EAT_DURATION
	if edible:
		# already blinking: timer refreshed above
		print("Eat state refreshed for cat ", name)
		return
		
	SPEED = 3.0  # slow down while edible
	edible = true
	_on_chase_timeout_timeout() # force end of any active chase
	
	# Start blinking coroutine
	cat_blink()

func cat_blink() -> void:
	blink_active = true
	
	# Ensure original materials are cached (if Level didn't get to call_deferred yet)
	if original_idle_material == null or original_object9_material == null:
		# Give a couple frames for the deferred cache to run
		var waited := 0
		while (original_idle_material == null or original_object9_material == null) and waited < 5:
			await get_tree().process_frame
			waited += 1
		# If still null, force a cache now
		if original_idle_material == null or original_object9_material == null:
			_cache_original_materials()

	# Safety: if eat materials somehow still null, build them now from original
	if eat_blue_idle == null:
		eat_blue_idle = original_idle_material.duplicate()
		eat_blue_idle.albedo_color = Color(0.0, 0.2, 1.0)
	if eat_blue_object9 == null:
		eat_blue_object9 = original_object9_material.duplicate()
		eat_blue_object9.albedo_color = Color(0.0, 0.2, 1.0)
	if eat_white_idle == null:
		eat_white_idle = original_idle_material.duplicate()
		eat_white_idle.albedo_color = Color(1, 1, 1)
	if eat_white_object9 == null:
		eat_white_object9 = original_object9_material.duplicate()
		eat_white_object9.albedo_color = Color(1, 1, 1)

	# refresh the timer (already set by caller, but keep for safety)
	_edible_time_left = EAT_DURATION

	# start with blue
	idle_cat.set_surface_override_material(0, eat_blue_idle)
	object_9.set_surface_override_material(0, eat_blue_object9)

	# blinking loop — stops decrementing while the tree is paused
# blinking loop — stops decrementing while the tree is paused
	while _edible_time_left > 0.0 and blink_active and mode != "idle":
		# pause-safe: wait until tree is unpaused
		while true:
			var tree := get_tree()
			if tree == null or not is_inside_tree(): # prevent crash when retrying
				return
			if not tree.paused:
				break
			await tree.process_frame

		# 🔑 dynamic blink interval
		# Start slow, then speed up near the end
		var blink_interval := BLINK_INTERVAL
		if _edible_time_left < 2.0:
			blink_interval = 0.1   # very fast in last 2s
		elif _edible_time_left < 4.0:
			blink_interval = 0.2   # medium fast in 2–4s
		# else keep default BLINK_INTERVAL (0.3s)

		# wait blink interval
		await get_tree().create_timer(blink_interval).timeout

		# toggle colors
		var current = idle_cat.get_surface_override_material(0)
		if current == eat_blue_idle:
			idle_cat.set_surface_override_material(0, eat_white_idle)
			object_9.set_surface_override_material(0, eat_white_object9)
		else:
			idle_cat.set_surface_override_material(0, eat_blue_idle)
			object_9.set_surface_override_material(0, eat_blue_object9)

		_edible_time_left -= blink_interval

	# restore originals (safe because we cached them earlier)
	if original_idle_material != null:
		idle_cat.set_surface_override_material(0, original_idle_material)
	if original_object9_material != null:
		object_9.set_surface_override_material(0, original_object9_material)

	#print("⚪ [RESTORE] Cat", name, "Idle color =", original_idle_material.albedo_color if original_idle_material else null)
	#print("⚪ [RESTORE] Cat", name, "Object_9 color =", original_object9_material.albedo_color if original_object9_material else null)

	edible = false
	SPEED = 5.5
	print("Cat ", name, " returned to normal.")

func _check_stuck(delta: float) -> void:
	var dist = global_position.distance_to(last_pos)
	if dist < stuck_radius:
		stuck_time += delta
		if stuck_time >= stuck_threshold and mode == "wander":
			print("⚠️ Cat seems stuck, picking a new wander point")
			stuck_time = 0.0
			_pick_new_wander_point()
	else:
		stuck_time = 0.0
		last_pos = global_position

func update_target_location(target_location: Vector3) -> void:
	nav_agent.set_target_position(target_location)

func _on_navigation_agent_3d_target_reached() -> void:
	if mode == "wander":
		needs_new_wander_point = true
	elif mode == "chase" and player_is_hit == false:
		player_is_hit = true
		print("hit")
		SignalBus.emit_signal("player_dead")

func _snap_rotation_to_direction(dir: Vector3) -> void:
	if not sketchfab_model:
		return

	var rot_y: float
	if abs(dir.x) > abs(dir.z):
		if dir.x > 0:
			rot_y = -PI/2
		else:
			rot_y = PI/2
	else:
		if dir.z > 0:
			rot_y = PI
		else:
			rot_y = 0

	sketchfab_model.rotation.y = rot_y

func _on_grace_timeout() -> void:
	print("⏳ Grace finished")
	active = true
	idle_mesh.hide()
	active_mesh.show()
	anim_player.play("run")

	if mode != "chase":
		print("➡️ Starting WANDER mode")
		mode = "wander"
		_pick_new_wander_point()

func _on_chase_timeout_timeout() -> void:
	if mode == "chase":
		print("🟡 Lost sight of player – returning to WANDER")
		mode = "wander"
		alert.hide()
		_pick_new_wander_point()

func _pick_new_wander_point() -> void:
	var random_x = randf_range(-12, 12)
	var random_z = randf_range(-12, 12)
	var target = Vector3(random_x, 0, random_z)
	update_target_location(target)

func _on_player_teleported() -> void:
	if mode == "chase":
		_on_chase_timeout_timeout()

func _on_eat_area_body_entered(_body: Node3D) -> void:
	if edible and mode != "idle":
		blink_active = false
		edible = false
		
		var smoke = puff_of_smoke.instantiate()
		get_tree().current_scene.add_child(smoke)
		smoke.global_transform.origin = character.global_transform.origin
		smoke.set_emitting(true)
		
		self.global_position = spawn_point.global_position
		sketchfab_model.rotation = Vector3(deg_to_rad(270), 0, 0)
		
		active = false
		mode = "idle"
		idle_mesh.show()
		active_mesh.hide()
		
		print("cat has been consumed")
		SignalBus.emit_signal("display_score_up")
		grace_timer.start()
	else:
		print("you cant eat me right now")
