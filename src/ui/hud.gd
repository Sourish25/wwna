# hud.gd
# Manages UI prompt overlays, reading notes, death, and victory screens
extends CanvasLayer

@onready var prompt_label: Label = $HUDControl/PromptLabel
@onready var note_overlay: ColorRect = $HUDControl/NoteOverlay
@onready var note_text: Label = $HUDControl/NoteOverlay/NoteText
@onready var jumpscare_overlay: ColorRect = $HUDControl/JumpscareOverlay
@onready var jumpscare_text: Label = $HUDControl/JumpscareOverlay/JumpscareText
@onready var victory_overlay: ColorRect = $HUDControl/VictoryOverlay
@onready var subtitle_label: Label = $HUDControl/SubtitleLabel

var _is_reading: bool = false
var _active_note_text: String = ""
var dialog_audio_player: AudioStreamPlayer

func _ready() -> void:
	# Create dialog audio player dynamically
	dialog_audio_player = AudioStreamPlayer.new()
	dialog_audio_player.bus = &"Master"
	add_child(dialog_audio_player)
	
	# Register UI nodes to the EventBus or listen to custom interactions
	EventBus.interaction_prompted.connect(_on_interaction_prompted)
	EventBus.interaction_cleared.connect(_on_interaction_cleared)
	EventBus.player_died.connect(_on_player_died)
	EventBus.level_completed.connect(_on_victory)
	EventBus.dialog_triggered.connect(_on_dialog_triggered)
	
	prompt_label.text = ""
	note_overlay.visible = false
	jumpscare_overlay.visible = false
	victory_overlay.visible = false
	subtitle_label.text = ""

func _unhandled_input(event: InputEvent) -> void:
	if _is_reading and (event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_E)):
		# Close the note
		_is_reading = false
		note_overlay.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_tree().paused = false
		# Yield input so player doesn't instantly re-interact
		get_viewport().set_input_as_handled()

func show_note(text: String) -> void:
	_active_note_text = text
	note_text.text = text
	note_overlay.visible = true
	_is_reading = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func _on_interaction_prompted(text: String) -> void:
	if not _is_reading:
		prompt_label.text = text

func _on_interaction_cleared() -> void:
	prompt_label.text = ""

func _on_player_died() -> void:
	prompt_label.text = ""
	jumpscare_overlay.visible = true
	
	# Creepy red screen fade
	var tween := create_tween()
	tween.tween_property(jumpscare_overlay, "color", Color(0.5, 0, 0, 0.95), 0.15)
	tween.parallel().tween_property(jumpscare_text, "modulate:a", 1.0, 0.1)
	
	# Wait and reload
	await get_tree().create_timer(3.5).timeout
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_victory(_level_name: String) -> void:
	prompt_label.text = ""
	victory_overlay.visible = true
	var tween := create_tween()
	tween.tween_property(victory_overlay, "color", Color(0, 0, 0, 0.95), 2.0)
	
	# Leave mouse visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(6.0).timeout
	get_tree().quit()

func _on_dialog_triggered(text: String, duration: float, audio_path: String) -> void:
	subtitle_label.text = text
	subtitle_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.35)
	
	# Play dialog voice line if path is provided
	if dialog_audio_player:
		dialog_audio_player.stop()
		if audio_path != "" and FileAccess.file_exists(audio_path):
			var stream = load(audio_path)
			if stream:
				dialog_audio_player.stream = stream
				dialog_audio_player.play()
	
	await get_tree().create_timer(duration).timeout
	
	# Fade out only if subtitle text hasn't been changed by a newer dialog
	if subtitle_label.text == text:
		var fade := create_tween()
		fade.tween_property(subtitle_label, "modulate:a", 0.0, 0.45)
