extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0


#func do_jump_animation(void) -> void:
#	$Sprite2D

func _physics_process(delta: float) -> void:
	# Apply gravity while not on the floor.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		velocity.y = move_toward(velocity.y, 0, SPEED)

	# Handle horizontal movement
	var direction_x := Input.get_axis("move-left", "move-right")
	if direction_x:
		velocity.x = direction_x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Handle vertical movement
	var direction_y := Input.get_axis("move-up", "move-down")
	if direction_y:
		velocity.y = direction_y * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()
