# flickering_light.gd
# Creepy flickering light effect for horror atmosphere
extends Light3D

@export var min_energy: float = 0.1
@export var max_energy: float = 1.2
@export var flicker_speed: float = 0.15
@export var dead_bulb_chance: float = 0.02 # Chance to turn off completely for a moment

var _timer: float = 0.0
var _base_energy: float = 1.0

func _ready() -> void:
	_base_energy = light_energy

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= flicker_speed:
		_timer = 0.0
		
		# Randomly decide if the bulb goes dead momentarily
		if randf() < dead_bulb_chance:
			light_energy = 0.0
			# Wait a very brief random time
			await get_tree().create_timer(randf_range(0.1, 0.4)).timeout
		else:
			# Otherwise oscillate between min and max energy
			light_energy = randf_range(min_energy, max_energy) * _base_energy
