# base_level.gd
# Manages gameplay triggers, doll pickups, ghost spawns, and altar sacrifice
class_name BaseLevel
extends Node3D

@export var level_name: String = "The Facility"

@onready var ghost: Ghost = $Ghost
@onready var doll: Doll = $Props/Doll
@onready var altar_interactable: Interactable = $Props/Altar/Interactable
@onready var altar_doll_mesh: CSGCombiner3D = $Props/Altar/SacrificedDoll

func _ready() -> void:
	# Add player to group for ghost AI queries
	var player = $Player
	if player:
		player.add_to_group("player")
		
	# Spawn HUD in player
	var hud_scene := load("res://src/ui/hud.tscn")
	if hud_scene and player:
		var hud = hud_scene.instantiate()
		player.add_child(hud)
		hud.name = "HUD"
		
	EventBus.player_died.connect(_on_player_died)
	
	if doll:
		doll.picked_up.connect(_on_doll_picked_up)
		
	if altar_interactable:
		altar_interactable.prompt_message = "[E] Sacrificial Altar"
		altar_interactable.interacted.connect(_on_altar_interacted)
		
	if altar_doll_mesh:
		altar_doll_mesh.visible = false
		
	if ghost:
		ghost.visible = false
		ghost.current_state = Ghost.State.DORMANT

func _on_doll_picked_up() -> void:
	# Wake up the presence!
	if ghost:
		ghost.trigger_spawn()

func _on_altar_interacted(player: Player) -> void:
	if player.has_doll:
		player.has_doll = false
		if altar_doll_mesh:
			altar_doll_mesh.visible = true
		# Trigger Level Victory via EventBus
		EventBus.level_completed.emit(level_name)
	else:
		EventBus.interaction_prompted.emit("The Altar demands a vessel...")
		await get_tree().create_timer(2.5).timeout
		EventBus.interaction_cleared.emit()

func _on_player_died() -> void:
	# Disable processing
	set_process(false)
