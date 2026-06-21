# ghost.gd
# Ghost AI that patrols, stays dormant, and charges when eye contact is made
class_name Ghost
extends CharacterBody3D

enum State { DORMANT, PATROL, AGITATED, CHASE }

@export var patrol_speed: float = 1.0
@export var chase_speed: float = 3.6
@export var eye_contact_threshold: float = 0.72 # FOV angle dot product
@export var target_player: Player

@onready var visual_mesh: Node3D = $VisualMesh
@onready var raycast: RayCast3D = $RayCast3D

var current_state: State = State.DORMANT
var _timer: float = 0.0
var _shriek_timer: float = 0.0
var _patrol_points: Array[Vector3] = []
var _current_patrol_idx: int = 0
var _base_y: float = 0.0

func _ready() -> void:
	add_to_group("ghost")
	_base_y = global_position.y
	# Setup patrol points around the main facility corridors
	_patrol_points = [
		Vector3(0, _base_y, -8),
		Vector3(0, _base_y, -16),
		Vector3(-9, _base_y, -16),
		Vector3(0, _base_y, -24),
	]

func _physics_process(delta: float) -> void:
	_timer += delta
	
	# Floating animation (bobbing up and down procedurally)
	var bobbing := sin(_timer * 3.0) * 0.15
	visual_mesh.position.y = bobbing
	
	# Rotational float sway
	visual_mesh.rotation.z = sin(_timer * 1.5) * 0.08
	
	if not target_player:
		# Search for player
		var players = get_tree().get_nodes_in_group("player")
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
			velocity = Vector3.ZERO
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
	
	velocity = dir * patrol_speed
	move_and_slide()
	
	# Rotate towards patrol point
	if velocity.length_squared() > 0.01:
		var target_rot := atan2(velocity.x, velocity.z)
		rotation.y = rotate_toward(rotation.y, target_rot, delta * 3.0)
		
	if global_position.distance_to(target) < 1.0:
		_current_patrol_idx = (_current_patrol_idx + 1) % _patrol_points.size()

func _chase_behavior(delta: float) -> void:
	var dir := (target_player.global_position - global_position).normalized()
	
	# Creepy direct flying glide ignoring vertical gravity
	velocity = dir * chase_speed
	move_and_slide()
	
	# Look directly at the player
	var target_rot := atan2(velocity.x, velocity.z)
	rotation.y = rotate_toward(rotation.y, target_rot, delta * 8.0)
	
	# Check distance for kill trigger
	if global_position.distance_to(target_player.global_position) < 1.3:
		# Jump-scare and kill player
		target_player.take_damage(100) # Instakill

func _check_eye_contact() -> void:
	if current_state == State.CHASE:
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
