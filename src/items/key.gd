# key.gd
# Pickable keys that unlock locked doors in the facility
class_name KeyItem
extends Node3D

@export var key_id: String = "security_key"
@export var key_name: String = "Security Key"

@onready var interactable: Interactable = $Interactable

func _ready() -> void:
	if interactable:
		interactable.prompt_message = "[E] Take " + key_name
		interactable.interacted.connect(_on_interact)

func _on_interact(player: Player) -> void:
	# Add key to player's keys list
	player.keys.append(key_id)
	
	# Play key click sound
	AudioSynth.play_flashlight_click(self)
	
	# Prompt HUD message
	EventBus.interaction_prompted.emit("Found " + key_name)
	await get_tree().create_timer(1.8).timeout
	EventBus.interaction_cleared.emit()
	
	queue_free()
