# doll.gd
# The pickable sacrificial doll that triggers the ghost chase
class_name Doll
extends Node3D

@onready var interactable: Interactable = $Interactable

signal picked_up

func _ready() -> void:
	if interactable:
		interactable.prompt_message = "[E] Pick Up Doll"
		interactable.interacted.connect(_on_interact)

func _on_interact(player: Player) -> void:
	player.has_doll = true
	# Play click pickup sound
	AudioSynth.play_flashlight_click(self)
	
	# Emit pickup signal
	picked_up.emit()
	
	# Trigger the EventBus level change or spawn ghost
	EventBus.interaction_prompted.emit("Something has awakened...")
	await get_tree().create_timer(2.0).timeout
	EventBus.interaction_cleared.emit()
	
	queue_free()
