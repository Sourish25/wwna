# game_manager.gd
# General game state and session coordinator
extends Node

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

var current_state: GameState = GameState.MENU
var current_level_name: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_game() -> void:
	current_state = GameState.PLAYING
	current_level_name = "level_01"
	EventBus.level_started.emit(current_level_name)

func set_paused(paused: bool) -> void:
	if current_state == GameState.PLAYING and paused:
		current_state = GameState.PAUSED
		get_tree().paused = true
		EventBus.game_paused.emit(true)
	elif current_state == GameState.PAUSED and not paused:
		current_state = GameState.PLAYING
		get_tree().paused = false
		EventBus.game_paused.emit(false)

func end_game(won: bool) -> void:
	current_state = GameState.GAME_OVER
	if won:
		EventBus.level_completed.emit(current_level_name)
	else:
		EventBus.level_failed.emit("player_died")
