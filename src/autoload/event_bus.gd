# event_bus.gd
# Global Signal Bus for decoupling game systems
@warning_ignore("unused_signal")
extends Node

# Player Signals
@warning_ignore("unused_signal")
signal player_spawned(player: CharacterBody3D)
@warning_ignore("unused_signal")
signal player_died
@warning_ignore("unused_signal")
signal player_health_changed(current: int, max_health: int)

# Game/Level Signals
@warning_ignore("unused_signal")
signal level_started(level_name: String)
@warning_ignore("unused_signal")
signal level_completed(level_name: String)
@warning_ignore("unused_signal")
signal level_failed(reason: String)

# UI/Interactive Signals
@warning_ignore("unused_signal")
signal interaction_prompted(text: String)
@warning_ignore("unused_signal")
signal interaction_cleared
@warning_ignore("unused_signal")
signal game_paused(is_paused: bool)
@warning_ignore("unused_signal")
signal dialog_triggered(text: String, duration: float, audio_path: String)
