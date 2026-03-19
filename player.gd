extends CharacterBody3D

# SPEED is the speed at which the player moves
const SPEED = 5.0
# GRAVITY variable used to pull the player down to the ground
const GRAVITY = 9.81

# We need a reference to the camera so we can read its own orientation
@onready var camera = $Camera

func _physics_process(delta):
	var direction = Vector3.ZERO

	# Read raw input as a 2D vector (-1 to 1 on each axis)
	var input_dir = Vector2.ZERO
	# INPUT actions against key bindings, the adds or subtracts from the direction value
	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.y += 1

	# If the direction is not a true Vector3 ie. (1, 0, 1)
	# so 1 in right and 1 up, then the true distance would be ~1.41
	# this normalizes the movement to always be 1
	if input_dir != Vector2.ZERO:
		# Get camera's forward and right vectors, flattened to the XZ plane
		var cam_forward = -camera.global_basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()

		var cam_right = camera.global_basis.x 
		cam_right.y = 0
		cam_right = cam_right.normalized()

		# Combine: input_dir.y drives forward/back, input_dir.x drives left/right
		direction = (cam_forward * -input_dir.y + cam_right * input_dir.x).normalized()

	# These statements use SPEED to control the distance moved and how fast
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	# This statement removes the GRAVITY value per frame to the player body
	velocity.y -= GRAVITY * delta

	move_and_slide()
