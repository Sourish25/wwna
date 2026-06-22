# ghost.gd
# Ghost AI that patrols, stays dormant, and charges when eye contact is made
class_name Ghost
extends CharacterBody3D

enum State { DORMANT, PATROL, AGITATED, CHASE }

@export var patrol_speed: float = 1.0
@export var chase_speed: float = 2.8
@export var eye_contact_threshold: float = 0.72 # FOV angle dot product
@export var target_player: Player

@onready var visual_mesh: Node3D = $VisualMesh
@onready var raycast: RayCast3D = $RayCast3D

var current_state: State = State.DORMANT
var jumpscare_cooldown: float = 0.0
var _timer: float = 0.0
var _shriek_timer: float = 0.0
var _patrol_points: Array[Vector3] = []
var _current_patrol_idx: int = 0
var _base_y: float = 0.0
var _walk_cycle_time: float = 0.0

func _ready() -> void:
	add_to_group("ghost")
	_base_y = global_position.y
	# Setup patrol points around the main facility corridors and expanded rooms
	_patrol_points = [
		Vector3(0, _base_y, -8),
		Vector3(-16, _base_y, 0),    # Cafeteria
		Vector3(0, _base_y, -16),
		Vector3(17, _base_y, -16),   # Locker Room
		Vector3(-17, _base_y, -16),  # Boiler Room
		Vector3(0, _base_y, -24),
		Vector3(16, _base_y, 0),     # Security Office
		Vector3(18, _base_y, -32),   # Infirmary
	]

	
	# Load and assign monster material to all MeshInstance3D nodes in the model
	var mat := load("res://assets/materials/monster_material.tres") as Material
	if mat:
		_apply_material_to_meshes(visual_mesh, mat)

func _physics_process(delta: float) -> void:
	_timer += delta
	if jumpscare_cooldown > 0.0:
		jumpscare_cooldown -= delta
	
	# Make sure visual mesh is aligned with no floating translations or sways
	visual_mesh.position = Vector3.ZERO
	visual_mesh.rotation.z = 0.0
	
	# Run procedural skeleton walking animations
	_animate_skeleton(delta)
	
	# Apply gravity to ghost so it walks on the floor
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	
	if not target_player:
		# Search for player
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:

			target_player = players[0] as Player
		return
		
	# State machine processing
	match current_state:
		State.DORMANT:
			# Stay hidden until awakened (or if player gets too close)
			if global_position.distance_to(target_player.global_position) < 3.0:
				current_state = State.PATROL
				
		State.PATROL:
			_patrol_behavior(delta)
			_check_eye_contact()
			
		State.AGITATED:
			# Shaking creepily, screaming
			velocity.x = 0
			velocity.z = 0
			visual_mesh.rotation.y += sin(_timer * 50.0) * 0.15 # Fast visual shaking
			_check_eye_contact()
			
			_shriek_timer -= delta
			if _shriek_timer <= 0:
				# Scream and charge
				current_state = State.CHASE
				
		State.CHASE:
			_chase_behavior(delta)

func _patrol_behavior(delta: float) -> void:
	if _patrol_points.is_empty():
		return
		
	var target := _patrol_points[_current_patrol_idx]
	var dir := (target - global_position).normalized()
	dir.y = 0 # Remain horizontal
	if dir.length_squared() > 0.001:
		dir = dir.normalized()
	
	velocity.x = dir.x * patrol_speed
	velocity.z = dir.z * patrol_speed
	move_and_slide()
	
	# Rotate towards patrol point
	var horiz_vel := Vector2(velocity.x, velocity.z)
	if horiz_vel.length_squared() > 0.01:
		var target_rot := atan2(velocity.x, velocity.z)
		rotation.y = rotate_toward(rotation.y, target_rot, delta * 3.0)
		
	if global_position.distance_to(target) < 1.0:
		_current_patrol_idx = (_current_patrol_idx + 1) % _patrol_points.size()

func _chase_behavior(delta: float) -> void:
	# If player hides under a table, stop chasing and return to patrol
	if target_player and target_player.is_hidden:
		current_state = State.PATROL
		return
		
	var dir := (target_player.global_position - global_position).normalized()
	dir.y = 0
	if dir.length_squared() > 0.001:
		dir = dir.normalized()
	
	velocity.x = dir.x * chase_speed
	velocity.z = dir.z * chase_speed
	move_and_slide()
	
	# Look directly at the player
	var horiz_vel := Vector2(velocity.x, velocity.z)
	if horiz_vel.length_squared() > 0.01:
		var target_rot := atan2(velocity.x, velocity.z)
		rotation.y = rotate_toward(rotation.y, target_rot, delta * 8.0)
	
	# Check distance for scare/damage trigger instead of instakill
	if global_position.distance_to(target_player.global_position) < 1.3 and jumpscare_cooldown <= 0.0:
		jumpscare_cooldown = 4.0 # 4 second cooldown
		
		# Play terrifying shriek
		_play_shriek_noise()
		
		# Trigger HUD jumpscare overlay red flash for 0.6 seconds
		EventBus.scare_triggered.emit(0.6)
		
		# Deal 40 damage (allows player to survive multiple catch events)
		target_player.take_damage(40)
		
		# Teleport ghost to the farthest patrol point
		teleport_away()
		
		# Return to patrol state to reset chase
		current_state = State.PATROL

func _check_eye_contact() -> void:
	if current_state == State.CHASE:
		return
		
	if target_player and target_player.is_hidden:
		return
		
	# 1. Check if the player is looking towards the ghost
	var player_pos := target_player.global_position
	var to_ghost := (global_position - player_pos).normalized()
	
	# Grab player looking direction
	var look_dir := -target_player.camera.global_transform.basis.z.normalized()
	var dot := look_dir.dot(to_ghost)
	
	if dot > eye_contact_threshold:
		# 2. Check Line of Sight via Raycast from player camera to ghost
		var space_state := get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(
			target_player.camera.global_position, 
			global_position + Vector3(0, 1.0, 0),
			0b1 # Layer 1 (Geometry)
		)
		var result := space_state.intersect_ray(query)
		
		# If raycast didn't hit any geometry wall, we have direct eye contact!
		if result.is_empty():
			if current_state != State.AGITATED:
				current_state = State.AGITATED
				_shriek_timer = 0.8 # Scream/shake for 0.8 seconds before chasing
				_play_shriek_noise()

func _play_shriek_noise() -> void:
	var player := AudioStreamPlayer3D.new()
	add_child(player)
	player.global_position = global_position
	
	# Load the downloaded Wikimedia horror laugh sound effect
	var sfx := load("res://assets/audio/sfx/ghost_laugh.ogg")
	if sfx:
		player.stream = sfx
		player.play()
		await player.finished
	else:
		# Fallback procedural synthesis scream
		var generator := AudioStreamGenerator.new()
		generator.mix_rate = 22050
		generator.buffer_length = 0.8
		player.stream = generator
		player.play()
		var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
		if playback:
			var sample_rate: float = 22050.0
			var frames := int(sample_rate * 0.8)
			for i in range(frames):
				var t := float(i) / sample_rate
				var freq := 800.0 + sin(2.0 * PI * 80.0 * t) * 300.0
				var osc := sin(2.0 * PI * freq * t) * 0.3 * exp(-3.0 * t)
				var noise := (randf() * 2.0 - 1.0) * 0.15 * exp(-1.5 * t)
				var sample: float = clamp(osc + noise, -1.0, 1.0)
				playback.push_frame(Vector2(sample, sample))
		await player.finished
		
	player.queue_free()

func trigger_spawn() -> void:
	current_state = State.PATROL
	visible = true

func teleport_away() -> void:
	if _patrol_points.is_empty() or not target_player:
		return
	var best_point := global_position
	var max_dist := 0.0
	for p in _patrol_points:
		var d := p.distance_to(target_player.global_position)
		if d > max_dist:
			max_dist = d
			best_point = p
	global_position = best_point
	velocity = Vector3.ZERO

func _apply_material_to_meshes(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for child in node.get_children():
		_apply_material_to_meshes(child, mat)

func _animate_skeleton(delta: float) -> void:
	var skeleton: Skeleton3D = visual_mesh.find_child("Skeleton3D", true, false) as Skeleton3D
	if not skeleton:
		return
		
	# Determine if the ghost is moving horizontally
	var horiz_vel := Vector2(velocity.x, velocity.z)
	var is_moving := horiz_vel.length_squared() > 0.05
	var anim_speed := 10.0 if current_state == State.CHASE else 5.0
	
	if is_moving:
		_walk_cycle_time += delta * anim_speed
	else:
		# Slowly transition back to neutral standing pose
		var angle_diff := wrapf(_walk_cycle_time, -PI, PI)
		_walk_cycle_time = move_toward(_walk_cycle_time, _walk_cycle_time - angle_diff, delta * 8.0)
		
	var swing := sin(_walk_cycle_time)
	var cos_swing := cos(_walk_cycle_time)
	
	# Thighs swing back and forth
	_set_bone_rot(skeleton, "mixamorig_LeftUpLeg", Vector3(1, 0, 0), swing * 0.45)
	_set_bone_rot(skeleton, "mixamorig_RightUpLeg", Vector3(1, 0, 0), -swing * 0.45)
	
	# Knee bend (shins bend backward when swinging back)
	var left_knee := 0.0
	if swing < 0.0:
		left_knee = -swing * 0.5
	_set_bone_rot(skeleton, "mixamorig_LeftLeg", Vector3(1, 0, 0), left_knee)
	
	var right_knee := 0.0
	if swing > 0.0:
		right_knee = swing * 0.5
	_set_bone_rot(skeleton, "mixamorig_RightLeg", Vector3(1, 0, 0), right_knee)
	
	# Arm poses
	if current_state == State.CHASE:
		# Zombie-like chase pose: arms raised straight forward, slightly swaying
		_set_bone_rot(skeleton, "mixamorig_LeftArm", Vector3(0, 0, 1), -1.2)
		_set_bone_rot(skeleton, "mixamorig_LeftArm", Vector3(1, 0, 0), -1.2 + swing * 0.1)
		
		_set_bone_rot(skeleton, "mixamorig_RightArm", Vector3(0, 0, 1), 1.2)
		_set_bone_rot(skeleton, "mixamorig_RightArm", Vector3(1, 0, 0), -1.2 - swing * 0.1)
	else:
		# Normal walking arm swing at sides
		_set_bone_rot(skeleton, "mixamorig_LeftArm", Vector3(1, 0, 0), -swing * 0.35)
		_set_bone_rot(skeleton, "mixamorig_LeftArm", Vector3(0, 0, 1), 0.0)
		_set_bone_rot(skeleton, "mixamorig_RightArm", Vector3(1, 0, 0), swing * 0.35)
		_set_bone_rot(skeleton, "mixamorig_RightArm", Vector3(0, 0, 1), 0.0)
		
	# Spine swaying and head bobbing
	_set_bone_rot(skeleton, "mixamorig_Spine", Vector3(0, 0, 1), cos_swing * 0.05)
	_set_bone_rot(skeleton, "mixamorig_Head", Vector3(1, 0, 0), sin(_timer * 2.0) * 0.08)

func _set_bone_rot(skeleton: Skeleton3D, bone_name: String, axis: Vector3, angle: float) -> void:
	var idx := skeleton.find_bone(bone_name)
	if idx != -1:
		skeleton.set_bone_pose_rotation(idx, Quaternion(axis.normalized(), angle))

