# hurtbox_component.gd
# 3D Area that receives damage from HitboxComponent and applies to HealthComponent
class_name HurtboxComponent
extends Area3D

@export var health_component: HealthComponent

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D) -> void:
	if not health_component:
		return
		
	if area is HitboxComponent:
		health_component.damage(area.damage)
