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

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	EventBus.player_spawned.emit(self)
	if health_component:
		health_component.died.connect(_on_death)
		health_component.health_changed.connect(_on_health_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))
		
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
			flashlight.visible = not flashlight.visible
			AudioSynth.play_flashlight_click(self)

	# E key Interaction check
	var is_interact_key := event is InputEventKey and event.pressed and event.keycode == KEY_E and not event.echo
	if is_interact_key and _active_interactable:
		_active_interactable.interact(self)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	var is_jumping := Input.is_action_just_pressed("jump") or Input.is_key_pressed(KEY_SPACE)
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
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	_process_interaction()

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
	EventBus.player_died.emit()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	queue_free()
