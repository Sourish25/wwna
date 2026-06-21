# player.gd
# 3D Player controller for physics movement and camera looking
class_name Player
extends CharacterBody3D

@export var speed: float = 2.5
@export var jump_velocity: float = 3.0
@export var mouse_sensitivity: float = 0.002

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var health_component: HealthComponent = $HealthComponent
@onready var flashlight: SpotLight3D = $CameraPivot/Camera3D/SpotLight3D

var has_doll: bool = false
var _active_interactable: Interactable = null
var heartbeat_player: AudioStreamPlayer
var _ghost_node: Ghost = null
var is_flashlight_enabled: bool = true
var is_crouching: bool = false
var is_hidden: bool = false


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	EventBus.player_spawned.emit(self)
	if health_component:
		health_component.died.connect(_on_death)
		health_component.health_changed.connect(_on_health_changed)
		
	# Setup heartbeat player
	heartbeat_player = AudioStreamPlayer.new()
	heartbeat_player.bus = &"Master"
	add_child(heartbeat_player)
	var hb_sfx := load("res://assets/audio/sfx/heartbeat.ogg")
	if hb_sfx:
		heartbeat_player.stream = hb_sfx
		if heartbeat_player.stream.has_method("set_loop"):
			heartbeat_player.stream.set_loop(true)
		elif "loop" in heartbeat_player.stream:
			heartbeat_player.stream.loop = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Flashlight on/off check
	var is_toggle_key := false
	if event is InputEventKey:
		var key_event := event as InputEventKey
		is_toggle_key = key_event.pressed and key_event.keycode == KEY_F and not key_event.echo
		
	if event.is_action_pressed("toggle_flashlight") or is_toggle_key:
		if flashlight:
			is_flashlight_enabled = not is_flashlight_enabled
			flashlight.visible = is_flashlight_enabled
			AudioSynth.play_flashlight_click(self)

	# E key Interaction check
	var is_interact_key := false
	if event is InputEventKey:
		var key_event := event as InputEventKey
		is_interact_key = key_event.pressed and key_event.keycode == KEY_E and not key_event.echo
		
	if is_interact_key and _active_interactable:
		_active_interactable.interact(self)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Crouch input
	var crouch_pressed := Input.is_key_pressed(KEY_C) or Input.is_key_pressed(KEY_CTRL)
	
	# Overhead ceiling check before allowing the player to stand up
	if is_crouching and not crouch_pressed:
		var space_state := get_world_3d().direct_space_state
		var from := global_position + Vector3(0, 0.5, 0)
		var to := global_position + Vector3(0, 1.8, 0)
		var query := PhysicsRayQueryParameters3D.create(from, to, 1) # Layer 1 (Geometry)
		query.exclude = [get_rid()]
		var result := space_state.intersect_ray(query)
		if not result.is_empty():
			# Overhead obstacle detected, force player to stay crouched
			is_crouching = true
		else:
			is_crouching = false
	else:
		is_crouching = crouch_pressed

	# Smoothly interpolate collision shape height and camera height
	var target_height := 0.9 if is_crouching else 1.8
	var target_cam_y := 0.8 if is_crouching else 1.6
	
	var col_shape := $CollisionShape3D
	if col_shape and col_shape.shape is CapsuleShape3D:
		var capsule := col_shape.shape as CapsuleShape3D
		capsule.height = lerp(capsule.height, target_height, delta * 12.0)
		col_shape.position.y = capsule.height * 0.5
		
	if camera_pivot:
		camera_pivot.position.y = lerp(camera_pivot.position.y, target_cam_y, delta * 12.0)

	# Handle Jump (disabled when crouching)
	var is_jumping := false
	if not is_crouching:
		is_jumping = (InputMap.has_action("jump") and Input.is_action_just_pressed("jump")) or Input.is_key_pressed(KEY_SPACE)
	if is_jumping and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0
		
	if input_dir.length_squared() > 0.0:
		input_dir = input_dir.normalized()
		
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Crouch speed is halved
	var current_speed := speed * 0.5 if is_crouching else speed
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
	_process_interaction()
	_process_heartbeat()

func _process_interaction() -> void:
	var space_state := get_world_3d().direct_space_state
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * 3.0
	
	var query := PhysicsRayQueryParameters3D.create(from, to, 4)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var result := space_state.intersect_ray(query)
	if not result.is_empty():
		var collider = result.collider
		if collider is Interactable:
			if _active_interactable != collider:
				_active_interactable = collider
				EventBus.interaction_prompted.emit(_active_interactable.prompt_message)
			return
			
	if _active_interactable:
		_active_interactable = null
		EventBus.interaction_cleared.emit()

func take_damage(amount: int) -> void:
	if health_component:
		health_component.damage(amount)

func _on_health_changed(current: int, max_health: int) -> void:
	EventBus.player_health_changed.emit(current, max_health)

func _on_death() -> void:
	HorrorMusicSynth.play_sfx("res://assets/audio/sfx/death_scream.ogg")
	EventBus.player_died.emit()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	queue_free()

func _process_heartbeat() -> void:
	if not heartbeat_player:
		return
		
	if not _ghost_node:
		var ghosts := get_tree().get_nodes_in_group("ghost")
		if ghosts.size() > 0:
			_ghost_node = ghosts[0] as Ghost
		else:
			var parent = get_parent()
			if parent:
				_ghost_node = parent.get_node_or_null("Ghost") as Ghost
	
	if not _ghost_node or not _ghost_node.visible or _ghost_node.current_state == Ghost.State.DORMANT:
		if heartbeat_player.playing:
			heartbeat_player.stop()
		if flashlight:
			flashlight.visible = is_flashlight_enabled
		return
		
	var dist := global_position.distance_to(_ghost_node.global_position)
	var max_hear_distance: float = 18.0
	
	if dist < max_hear_distance:
		if not heartbeat_player.playing:
			heartbeat_player.play()
			
		# Proximity-based volume ratio (1.0 close, 0.0 far)
		var volume_ratio := 1.0 - (dist / max_hear_distance)
		
		# Heartbeat intensity boost if ghost is actively chasing the player
		if _ghost_node.current_state == Ghost.State.CHASE:
			volume_ratio = clamp(volume_ratio + 0.25, 0.0, 1.0)
			heartbeat_player.pitch_scale = 1.35
		else:
			heartbeat_player.pitch_scale = 1.0
			
		volume_ratio = volume_ratio * 0.85 # Max volume safety limit
		
		if volume_ratio > 0.01:
			heartbeat_player.volume_db = linear_to_db(volume_ratio)
		else:
			heartbeat_player.volume_db = -80.0
			
		# Proximity flashlight flicker
		if dist < 12.0:
			if flashlight and is_flashlight_enabled:
				if randf() < 0.12:
					flashlight.visible = not flashlight.visible
		else:
			if flashlight:
				flashlight.visible = is_flashlight_enabled
	else:
		if heartbeat_player.playing:
			heartbeat_player.stop()
		if flashlight:
			flashlight.visible = is_flashlight_enabled
