extends CharacterBody2D

# Constants
const JUMP_DURATION = 0.50
const JUMP_HEIGHT = 20.0
const SQUISH_AMOUNT = 0.75 # Maximum squish (1 is no squish)

# Configurable variables
@export var speed: float = 100.0
@export var max_health: int = 100
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 200.0

var current_health: int
var jump_time := 0.0
var can_jump := true # Can jump is equivalent to not is_jumping
var can_shoot := true

@onready var jump_cooldown_timer = $JumpCooldownTimer
@onready var shoot_cooldown_timer = $ShootCooldownTimer
@onready var shadow = $Shadow
@onready var muzzle = $Muzzle
@onready var animation_player = $AnimationPlayer

func _ready():
	current_health = max_health

func _physics_process(delta: float) -> void:
	# Set horizontal direction
	var direction_x := Input.get_axis("move-left", "move-right")

	# Handle flip sprite for horizontal movement direction
	if direction_x < 0:
		$Sprite2D.flip_h = true 
	elif direction_x > 0:
		$Sprite2D.flip_h = false

	# Set vertical direction
	var direction_y := Input.get_axis("move-up", "move-down")

	# Allow movement if not jumping
	if can_jump:
		velocity.x = direction_x * speed
		velocity.y = direction_y * speed

	# Trigger the jump animation
	if Input.is_action_just_pressed("jump") and can_jump:
		jump()
		
	# Perform the jump animation
	if not can_jump:
		jump_time += delta
		#do_jump_animation(jump_time)
		enable_invulnerability(true)

		if jump_time >= JUMP_DURATION:
			can_jump = true # Reset ability to jump
			#$Sprite2D.scale = Vector2(1, 1) # Reset scale to normal
			#$Sprite2D.position = Vector2(0, 0) # Reset position to normal
			enable_invulnerability(false)
			shadow.reset_animation()

	if Input.is_action_just_pressed("shoot"):
		shoot(direction_x, direction_y)

	move_and_slide()

func shoot(direction_x: int, direction_y: int):
	if projectile_scene == null:
		printerr("Projectile scene not assigned!")
		return

	# Instantiate and add projectile to the scene
	var projectile_instance = projectile_scene.instantiate()
	get_tree().root.add_child(projectile_instance)

	projectile_instance.global_position = muzzle.global_position

	# Set projectile direction based on player facing direction
	if direction_x < 0:
		projectile_instance.rotation = PI # 180 degrees (facing left)
	elif direction_x > 0:
		projectile_instance.rotation = 0.0 # 0 degrees (facing right)
	
	projectile_instance.speed = projectile_speed
	projectile_instance.is_player_projectile = true

func jump() -> void:
	can_jump = false
	jump_cooldown_timer.start()
	jump_time = 0.0
	shadow.play_animation(JUMP_DURATION)
	animation_player.play("jump")

func enable_invulnerability(state: bool) -> void:
	$CollisionShape2D.disabled = state	

#func take_damage(damage_amount: int):
#	if not $CollisionShape2D.disabled: # Only take damage if not invulnerable
#		current_health -= damage_amount
#		print("Player took ", damage_amount, " damage. Current health: ", current_health)
#		if current_health <= 0:
#			die()

func die() -> void:
	print("Player died!")
	queue_free() # Or other death logic (e.g., game over screen)

func _on_jump_cooldown_timer_timeout() -> void:
	can_jump = true

func _on_shoot_cooldown_timer_timeout() -> void:
	can_shoot = true
