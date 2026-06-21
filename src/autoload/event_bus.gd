# event_bus.gd
# Global Signal Bus for decoupling game systems
extends Node

# Player Signals
signal player_spawned(player: CharacterBody3D)
signal player_died
signal player_health_changed(current: int, max_health: int)

# Game/Level Signals
signal level_started(level_name: String)
signal level_completed(level_name: String)
signal level_failed(reason: String)

# UI/Interactive Signals
signal interaction_prompted(text: String)
signal interaction_cleared
signal game_paused(is_paused: bool)
