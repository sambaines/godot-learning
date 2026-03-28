extends CharacterBody3D

const SPEED = 2.0
const GRAVITY = 9.81

# An enum is just a named set of constants - under the hood its the same as IDLE = 0 and WALKING = 1, but this is more readable
enum State { IDLE, WALKING }
var state = State.IDLE

var idle_timer = 0.0

# The @export makes the variable available in the Godot inspector per NPC
@export var wander_radius = 6.0

@onready var nav_agent = $NavigationAgent3D

func _ready():
	await get_tree().physics_frame
	pick_new_destination()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# Match is GDScript's version of a switch statement - cleaner than a set of if/elif statements. Each State.IDLE: / State.WALKING: block only runs when state matches it
	match state:
		# This is the IDLE branch => stop moving, count down a timer, when it hits zero, pick a new destination
		State.IDLE:
			velocity.x = 0
			velocity.z = 0
			idle_timer -= delta
			if idle_timer <= 0:
				pick_new_destination()
		
		# This is the WALKING branch => This is the key NavAgent bit. You don't move toward the final destination directly - get_next_path_position() returns the next waypoint
		# along a calculated path. If there is a bxo in the way, the navmesh routes around it and gives intermediate points. You just move toward whatever it hands each frame
		State.WALKING:
			var next_pos = nav_agent.get_next_path_position()
			var dir = (next_pos - global_position).normalized()

			var flat_dir = Vector3(dir.x, 0, dir.z).normalized()
			if flat_dir.length() > 0.001:
				rotation.y = lerp_angle(rotation.y, atan2(-flat_dir.x, -flat_dir.z), 5.0 * delta)
			# next_pos - global_position gives you a vector pointing from the NPC toward that wyapoint - .normalized() makes it length 1 so speed is consistent
			velocity.x = dir.x * SPEED
			velocity.z = dir.z * SPEED

			# When NPC reaches its destination (navigation is finished), flip state back to IDLE and set random wait time between 1-3 seconds before wandering again
			if nav_agent.is_navigation_finished():
				state = State.IDLE
				idle_timer = randf_range(1.0, 3.0)
		
	move_and_slide()

# This function picks a random point withing `wander-radius` units of the NPC's current position (X and Z only, no Y up) => Sets that as the nav agent's target
func pick_new_destination():
	var offset = Vector3(randf_range(-wander_radius, wander_radius), 0, randf_range(-wander_radius, wander_radius))
	nav_agent.target_position = global_position + offset

	# On picking a new destination, flip state to WALKING
	state = State.WALKING
