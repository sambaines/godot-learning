extends MultiMeshInstance3D

@export var flowers_count: int = 500
@export var field_size: float = 20.0 # scatter radius from centre
@export var flower_scale: float = 0.3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = flowers_count

	mm.mesh = _make_quad_mesh()

	multimesh = mm

	for i in flowers_count:
		var x := randf_range(-field_size, field_size)
		var z := randf_range(-field_size, field_size)
		var t := Transform3D()
		t = t.scaled(Vector3.ONE * flower_scale)
		t.origin = Vector3(x, 0.15, z) # slightly above ground
		mm.set_instance_transform(i, t)

		# Random color - white, orange, purple
		var colours := [Color.WHITE, Color(1, 0.5, 0), Color(0.6, 0.2, 0.9)]
		mm.set_instance_color(i, colours[randi() % 3])

func _make_quad_mesh() -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)

	var mat := StandardMaterial3D.new()
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true # use per-instance colour
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.albedo_color = Color.WHITE

	q.material = mat
	return q
