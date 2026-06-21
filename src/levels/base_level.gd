# base_level.gd
# Base level scene script that handles initialization, setup, and cleanup
class_name BaseLevel
extends Node3D

@export var level_name: String = "Base Level"

func _ready() -> void:
	print("Level '%s' loaded" % level_name)
	
	# Connect to event bus signals if needed
	EventBus.player_died.connect(_on_player_died)
	
func _on_player_died() -> void:
	print("Player died in '%s'. Restarting level..." % level_name)
	# Wait for 3 seconds before restarting
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
