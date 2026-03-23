extends Area3D

@onready var fade = $"/root/World/CanvasLayer/Fade"

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		fade_out()

func fade_out():
	var tween = create_tween()                                                                                                                                                                     
	tween.tween_property(fade, "color:a", 1.0, 0.8)
