extends CharacterBody2D

# TODO: make cooldown start after landing

# Constants
const JUMP_DURATION = 0.50
const JUMP_HEIGHT = 20.0
const SQUISH_AMOUNT = 0.75 # Maximum squish (1 is no squish)

# Configurable variables
@export var speed: float = 100.0
@export var max_health: int = 100
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 200.0
@export var shoot_cooldown: float = 0.5
@export var jump_cooldown: float = 0.75

var current_health: int
var can_jump := true
var can_move := true
var can_shoot := true
var last_angle := 0.0

@onready var jump_timer = $JumpTimer
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

	# Update last_movement_angle ONLY if there is movement
	var movement_vector := Vector2(direction_x, direction_y)
	if movement_vector.length() > 0:
		last_angle = movement_vector.angle()	

	# Allow movement if not jumping
	if can_move:
		velocity.x = direction_x * speed
		velocity.y = direction_y * speed

	# Trigger the jump animation
	if Input.is_action_just_pressed("jump") and can_jump:
		jump()

	if Input.is_action_just_pressed("shoot") and can_shoot:
		shoot(movement_vector)

	move_and_slide()

func shoot(direction: Vector2):
	if projectile_scene == null:
		printerr("Projectile scene not assigned!")
		return

	# Instantiate and add projectile to the scene
	var projectile_instance = projectile_scene.instantiate()
	get_tree().root.add_child(projectile_instance)

	projectile_instance.global_position = muzzle.global_position
	projectile_instance.rotation = last_angle
	projectile_instance.speed = projectile_speed
	projectile_instance.is_player_projectile = true
	
	# Start cooldown
	can_shoot = false
	shoot_cooldown_timer.start(shoot_cooldown)

func jump() -> void:
	can_jump = false
	can_move = false
	jump_timer.start(JUMP_DURATION)
	shadow.play_animation(JUMP_DURATION)
	animation_player.speed_scale = 1/JUMP_DURATION
	animation_player.play("jump")

#func take_damage(damage_amount: int):
#	if not $CollisionShape2D.disabled: # Only take damage if not invulnerable
#		current_health -= damage_amount
#		print("Player took ", damage_amount, " damage. Current health: ", current_health)
#		if current_health <= 0:
#			die()

func die() -> void:
	print("Player died!")
	queue_free() # Or other death logic (e.g., game over screen)

func _on_jump_timer_timeout() -> void:
	can_move = true
	jump_cooldown_timer.start(jump_cooldown)
	
func _on_jump_cooldown_timer_timeout() -> void:
	can_jump = true

func _on_shoot_cooldown_timer_timeout() -> void:
	can_shoot = true
