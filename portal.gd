extends Area3D

@onready var fade = $"/root/World/CanvasLayer/Fade"

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.locked = true
		await fade_out()
		GameState.entry_point = "south"
		get_tree().change_scene_to_file("res://world2.tscn")

func fade_out():
	var tween = create_tween()                                                                                                                                                                     
	tween.tween_property(fade, "color:a", 1.0, 0.8)
	# Use await to ensure the tween for the fade finishes before the changing the scene
	await tween.finished
