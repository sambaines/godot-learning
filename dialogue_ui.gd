extends CanvasLayer

@onready var label = $Panel/MarginContainer/Label

func show_prompt():
	label.text = "Press E to talk"
	visible = true

func show_dialogue(text: String):
	label.text = text
	visible = true
	
func hide_ui():
	visible = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide_ui()
