# locked_door.gd
# Static body representing locked doors that swing open when unlocked with a key
class_name LockedDoor
extends StaticBody3D

@export var key_id: String = "security_key"
@export var door_name: String = "Security Door"
@export var locked_message: String = "Locked. Needs Security Key."
@export var unlock_message: String = "Unlocked Security Door."

@onready var interactable: Interactable = $Interactable

var is_unlocked: bool = false
var _is_opening: bool = false
var _start_rotation: float = 0.0

func _ready() -> void:
	_start_rotation = rotation.y
	if interactable:
		interactable.prompt_message = "[E] Open " + door_name
		interactable.interacted.connect(_on_interact)

func _on_interact(player: Player) -> void:
	if is_unlocked:
		_toggle_door()
		return
		
	# Check if player has the key
	if key_id in player.keys:
		is_unlocked = true
		player.keys.erase(key_id) # Consume key
		AudioSynth.play_flashlight_click(self) # Unlock click
		EventBus.interaction_prompted.emit(unlock_message)
		_toggle_door()
		await get_tree().create_timer(1.8).timeout
		EventBus.interaction_cleared.emit()
	else:
		# Door is locked
		EventBus.interaction_prompted.emit(locked_message)
		await get_tree().create_timer(1.8).timeout
		EventBus.interaction_cleared.emit()

func _toggle_door() -> void:
	_is_opening = not _is_opening

func _physics_process(delta: float) -> void:
	var target_angle = _start_rotation + deg_to_rad(90.0) if _is_opening else _start_rotation
	rotation.y = rotate_toward(rotation.y, target_angle, delta * 3.0)
