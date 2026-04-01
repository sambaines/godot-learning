extends CharacterBody3D

const SPEED = 2.0
const GRAVITY = 9.81

# An enum is just a named set of constants - under the hood its the same as IDLE = 0 and WALKING = 1, but this is more readable
enum State { IDLE, WALKING, TALKING }
var state = State.IDLE

var player_ref = null # holds a refernce to the player node when nearby
var dialogue_index = 0 # tracks which line of dialogue we're on

const DIALOGUE = [
	"Hey there, travller.",
	"Lovely weather for wandering, isn't it?",
	"Safe travels."
]

var idle_timer = 0.0

# The @export makes the variable available in the Godot inspector per NPC
@export var wander_radius = 6.0

@export var dialogue_ui: CanvasLayer

@onready var nav_agent = $NavigationAgent3D

func _ready():
	await get_tree().physics_frame
	pick_new_destination()
	$InteractionZone.body_entered.connect(_on_player_entered)
	$InteractionZone.body_exited.connect(_on_player_exited)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if player_ref and Input.is_action_just_pressed("interact"):
		if state == State.TALKING:
			advance_dialogue()
		else:
			start_dialogue()
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
		
		State.TALKING:
			velocity.x = 0
			velocity.z = 0
			# face the player
			var dir_to_player = (player_ref.global_position - global_position)
			dir_to_player.y = 0
			if dir_to_player.length() > 0.01:
				var target_angle = atan2(-dir_to_player.x, -dir_to_player.z)
				rotation.y = lerp_angle(rotation.y, target_angle, 5.0 * delta)
		
	move_and_slide()

# This function picks a random point withing `wander-radius` units of the NPC's current position (X and Z only, no Y up) => Sets that as the nav agent's target
func pick_new_destination():
	var offset = Vector3(randf_range(-wander_radius, wander_radius), 0, randf_range(-wander_radius, wander_radius))
	nav_agent.target_position = global_position + offset

	# On picking a new destination, flip state to WALKING
	state = State.WALKING

func _on_player_entered(body):
	if body.name == "Player":
		player_ref = body # store a reference so other functions can access the player
		dialogue_ui.show_prompt() # tell the UI to show the "Press E to talk"

func _on_player_exited(body):
	if body.name == "Player":
		player_ref = null # clear the reference, player is no longer nearby
		dialogue_ui.hide_ui()
		end_dialogue() # clean up any in progress conversation

func start_dialogue():
	dialogue_index = 0 # Always start from the first dialogue line
	state = State.TALKING
	dialogue_ui.show_dialogue(DIALOGUE[dialogue_index])
	# DIALOGUE is an array - [dialogue_index] is the index operator, it fetches the item at that position
	# DIALOGUE[0] = "Hey there, traveller." from the const above
	# dialogue_index starts at 0

func advance_dialogue():
	dialogue_index += 1 # move dialogue to next line on button press
	if dialogue_index >= DIALOGUE.size():
		# if size() returns a number >= to total items in array
		# then the conversation is over
		end_dialogue()
	else:
		dialogue_ui.show_dialogue(DIALOGUE[dialogue_index]) # show next line

func end_dialogue():
	state = State.IDLE
	dialogue_index = 0 # reset so next conversation starts from 0
	dialogue_ui.hide_ui()
	pick_new_destination() # NPC resumes wandering
