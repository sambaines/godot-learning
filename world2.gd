extends Node3D

@onready var fade = $CanvasLayer/Fade
@onready var player = $Player

func _ready():
	var entry = GameState.entry_point
	if entry != "":
		var marker = get_node_or_null(entry)
		if marker:
			player.global_position = marker.global_position
	fade_in()
	
func fade_in():
	var tween = create_tween()
	tween.tween_property(fade, "color:a", 0.0, 0.8)
