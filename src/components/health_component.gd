# health_component.gd
# Component to manage health, damage, healing, and death state
class_name HealthComponent
extends Node

signal health_changed(current_health: int, max_health: int)
signal died

@export var max_health: int = 100
@onready var current_health: int = max_health:
	set(value):
		current_health = clampi(value, 0, max_health)
		health_changed.emit(current_health, max_health)
		if current_health <= 0:
			died.emit()

func damage(amount: int) -> void:
	current_health -= amount

func heal(amount: int) -> void:
	current_health += amount
