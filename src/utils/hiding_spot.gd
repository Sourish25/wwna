# hiding_spot.gd
# Node for managing areas where the player can crouch and hide from the ghost
class_name HidingSpot
extends Area3D

var _player_in_area: Player = null

func _ready() -> void:
	# Enable monitoring and monitorable
	monitoring = true
	monitorable = false
	
	# Connect overlap signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		_player_in_area = body

func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		if _player_in_area == body:
			_player_in_area.is_hidden = false
			_player_in_area = null

func _physics_process(_delta: float) -> void:
	if _player_in_area:
		# If the player is crouching inside this spot, they are hidden!
		if _player_in_area.is_crouching:
			_player_in_area.is_hidden = true
		else:
			_player_in_area.is_hidden = false
