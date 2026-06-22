# main_menu.gd
# Controls starting the game, options, volume control, and quitting
extends Control

@onready var play_btn: Button = $MenuControl/VBoxContainer/PlayButton
@onready var options_btn: Button = $MenuControl/VBoxContainer/OptionsButton
@onready var quit_btn: Button = $MenuControl/VBoxContainer/QuitButton

@onready var options_menu: Panel = $OptionsMenu
@onready var volume_slider: HSlider = $OptionsMenu/VBoxContainer/VolumeSlider
@onready var back_btn: Button = $OptionsMenu/VBoxContainer/BackButton

func _ready() -> void:
	# Ensure mouse cursor is visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	options_menu.visible = false
	
	# Connect menu buttons
	play_btn.pressed.connect(_on_play_pressed)
	options_btn.pressed.connect(_on_options_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	
	# Connect options buttons
	back_btn.pressed.connect(_on_back_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	
	# Dynamic hover visual feedback and click sounds
	for btn in [play_btn, options_btn, quit_btn, back_btn]:
		# Set pivot offset to center so button scales from center
		btn.pivot_offset = btn.size * 0.5
		btn.mouse_entered.connect(func():
			# Play subtle procedural click
			AudioSynth.play_flashlight_click(btn)
			# Scale button slightly
			var tween := create_tween()
			tween.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.12)
		)
		btn.mouse_exited.connect(func():
			var tween := create_tween()
			tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)
		)

func _on_play_pressed() -> void:
	AudioSynth.play_flashlight_click(self)
	# Start game
	get_tree().change_scene_to_file("res://src/levels/room.tscn")

func _on_options_pressed() -> void:
	AudioSynth.play_flashlight_click(self)
	options_menu.visible = true

func _on_quit_pressed() -> void:
	AudioSynth.play_flashlight_click(self)
	get_tree().quit()

func _on_back_pressed() -> void:
	AudioSynth.play_flashlight_click(self)
	options_menu.visible = false

func _on_volume_changed(value: float) -> void:
	# Scale slider value (0-100) to decibels
	var db := linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
