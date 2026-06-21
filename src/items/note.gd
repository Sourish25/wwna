# note.gd
# Creepy text log note that provides backstory and triggers objectives
class_name Note
extends Node3D

@export_multiline var note_contents: String = "This is a note."
@onready var interactable: Interactable = $Interactable

func _ready() -> void:
	if interactable:
		interactable.prompt_message = "[E] Inspect Note"
		interactable.interacted.connect(_on_interact)

func _on_interact(player: Player) -> void:
	# Find HUD and display the note contents
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_note"):
		hud.show_note(note_contents)
