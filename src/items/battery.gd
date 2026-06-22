# battery.gd
# Pickup battery item that recharges the player's flashlight power
class_name Battery
extends Node3D

@onready var interactable: Interactable = $Interactable

func _ready() -> void:
	if interactable:
		interactable.prompt_message = "[E] Take Flashlight Battery"
		interactable.interacted.connect(_on_interact)

func _on_interact(player: Player) -> void:
	# Add battery to player
	player.flashlight_battery = min(player.flashlight_battery + 0.45, 1.0)
	
	# Play mechanical click sound
	AudioSynth.play_flashlight_click(self)
	
	# Trigger HUD alert
	EventBus.interaction_prompted.emit("Picked up battery (+45%)")
	await get_tree().create_timer(1.8).timeout
	EventBus.interaction_cleared.emit()
	
	queue_free()
