extends CharacterBody3D

# SPEED is the speed at which the player moves
const SPEED = 5.0
# GRAVITY variable used to pull the player down to the ground
const GRAVITY = 9.81

func _physics_process(delta):
	var direction = Vector3.ZERO

	# INPUT actions against key bindings, the adds or subtracts from the direction value
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_up"):
		direction.z -= 1
	if Input.is_action_pressed("ui_down"):
		direction.z += 1

	# If the direction is not a true Vector3 ie. (1, 0, 1)
	# so 1 in right and 1 up, then the true distance would be ~1.41
	# this normalizes the movement to always be 1
	if direction != Vector3.ZERO:
		direction = direction.normalized()

	# These statements use SPEED to control the distance moved and how fast
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	# This statement removes the GRAVITY value per frame to the player body
	velocity.y -= GRAVITY * delta

	move_and_slide()
