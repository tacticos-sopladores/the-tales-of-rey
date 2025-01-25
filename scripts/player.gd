extends CharacterBody2D


const SPEED = 150.0
const JUMP_DURATION = 0.2 # Total duration of the jump in seconds
const JUMP_HEIGHT = 10.0 # Maximum height of the jump
const SQUISH_AMOUNT = 0.95 # Maximum squish (1 is no squish)

var jump_time := 0.0
var is_jumping := false
var can_jump := true

@onready var jump_cooldown_timer = $JumpCooldownTimer

func _physics_process(delta: float) -> void:
	# Set horizontal direction
	var direction_x := Input.get_axis("move-left", "move-right")
	
	# Handle flip sprite for movement direction
	if direction_x < 0:
		$Sprite2D.flip_h = true 
	elif direction_x > 0:
		$Sprite2D.flip_h = false
		
	# Set vertical direction
	var direction_y := Input.get_axis("move-up", "move-down")
	
	# Allow movement if not jumping
	if not is_jumping:
		velocity.x = direction_x * SPEED
		velocity.y = direction_y * SPEED
	
	# Trigger the jump animation
	if Input.is_action_just_pressed("jump") and not is_jumping and can_jump:
		is_jumping = true
		can_jump = false
		jump_cooldown_timer.start()
		jump_time = 0.0

	# Perform the jump animation
	if is_jumping:
		jump_time += delta
		do_jump_animation(jump_time)

		if jump_time >= JUMP_DURATION:
			is_jumping = false
			$Sprite2D.scale = Vector2(1, 1) # Reset scale to normal
			$Sprite2D.position = Vector2(0, 0) # Reset position to normal

	move_and_slide()

func do_jump_animation(time: float) -> void:
	# Calculate normalized time (0 to 1)
	var t := time / JUMP_DURATION

	# Calculate the vertical harmonic position (sinusoidal arc)
	var vertical_position := -sin(t * PI) * JUMP_HEIGHT

	# Calculate the squish/stretch effect
	var squish: float = lerp(1.0, SQUISH_AMOUNT, abs(sin(t * PI)))

	# Apply transformations
	$Sprite2D.position.y = vertical_position
	$Sprite2D.scale = Vector2(1.0, squish)

func _on_jump_cooldown_timer_timeout():
	can_jump = true
	
