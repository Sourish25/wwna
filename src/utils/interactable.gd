# interactable.gd
# Reusable interaction component for Godot 3D
class_name Interactable
extends Area3D

signal interacted(player: Player)

@export var prompt_message: String = "Interact"

func _ready() -> void:
	# Programmatically assign to Layer 3 (bit mask 4) for interaction raycasting
	collision_layer = 4
	collision_mask = 0

func interact(player: Player) -> void:
	interacted.emit(player)
