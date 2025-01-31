extends CharacterBody2D

# Constants
const JUMP_DURATION = 0.50
const JUMP_HEIGHT = 20.0
const SQUISH_AMOUNT = 0.75 # Maximum squish (1 is no squish)
const BASE_XP_REQUIRED = 50 # Base XP for first level
const EARLY_XP_CURVE_POWER = 1.5 # Gentler curve for early levels (1-50)
const LATE_XP_CURVE_POWER = 2.5 # Steeper curve for later levels (51+)
const EARLY_XP_MULTIPLIER = 5 # Lower multiplier for early levels
const LATE_XP_MULTIPLIER = 15 # Higher multiplier for later levels
const LEVEL_THRESHOLD = 50 # Level at which the scaling changes
const XP_MULTIPLIER = 10 # Multiplier for the polynomial result

# Configurable variables
@export var speed: float = 100.0
@export var max_health: int = 100
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 100.0
@export var shoot_cooldown: float = 0.5
@export var jump_cooldown: float = 0.75
@export var invulnerability_duration: float = 1.0

var current_health: int
var can_jump := true
var can_move := true
var can_shoot := true
var last_angle := 0.0
var is_invulnerable := false
var is_dead := false

# Experience and level variables
var current_level: int = 1
var current_xp: int = 0
var xp_required_for_next_level: int = BASE_XP_REQUIRED

# Combat variables
var projectile_count: int = 1
var projectile_scale: float = 1.0

# Level up screen
var level_up_screen_scene = preload("res://scenes/ui/level_up_screen.tscn")
var level_up_screen: Control

@onready var jump_timer = $JumpTimer
@onready var jump_cooldown_timer = $JumpCooldownTimer
@onready var shoot_cooldown_timer = $ShootCooldownTimer
@onready var invulnerability_timer = $InvulnerabilityTimer
@onready var shadow = $Shadow
@onready var muzzle = $Sprite2D/Muzzle
@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var weapon_manager = $WeaponManager

func _ready():
	current_health = max_health
	# Create health label
	var label = Label.new()
	label.name = "HealthLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 8)
	add_child(label)
	update_health_display()
	
	# Create and setup level up screen
	level_up_screen = level_up_screen_scene.instantiate()
	# Add it to the UI layer
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100 # Make sure it's on top
	add_child(canvas_layer)
	canvas_layer.add_child(level_up_screen)
	level_up_screen.reward_selected.connect(_on_reward_selected)

func update_health_display() -> void:
	var label = get_node("HealthLabel")
	if label:
		if is_dead:
			label.text = ""
		else:
			label.text = str(current_health) + "/" + str(max_health)
			# Position the label above the player
			label.position = Vector2(-20, -30)

func update_xp_display() -> void:
	# Signal that XP has changed
	emit_signal("xp_changed", current_level, current_xp, xp_required_for_next_level)

# Add signal for XP changes
signal xp_changed(level: int, current_xp: int, required_xp: int)

func collect_xp(amount: int) -> void:
	current_xp += amount
	while current_xp >= xp_required_for_next_level:
		level_up()
	update_xp_display()

func level_up() -> void:
	current_level += 1
	current_xp -= xp_required_for_next_level
	
	# Calculate next level XP using piecewise scaling
	if current_level <= LEVEL_THRESHOLD:
		# Gentler curve for early levels
		xp_required_for_next_level = BASE_XP_REQUIRED + int(pow(current_level, EARLY_XP_CURVE_POWER) * EARLY_XP_MULTIPLIER)
	else:
		# Steeper curve for later levels
		var level_diff = current_level - LEVEL_THRESHOLD # How many levels past the threshold
		xp_required_for_next_level = BASE_XP_REQUIRED + int(pow(LEVEL_THRESHOLD, EARLY_XP_CURVE_POWER) * EARLY_XP_MULTIPLIER) + int(pow(level_diff, LATE_XP_CURVE_POWER) * LATE_XP_MULTIPLIER)
	
	# Restore health on level up
	current_health = max_health
	update_health_display()
	
	# Visual feedback for level up
	sprite.modulate = Color(2, 2, 0.5) # Golden flash
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.5)
	
	# Show level up screen
	level_up_screen.show_rewards()

func _on_reward_selected(reward_type: String, reward_value: float) -> void:
	print("Reward selected: ", reward_type, " with value: ", reward_value) # Debug print
	
	# Check if this is a weapon reward
	if level_up_screen.REWARD_TYPES[reward_type]["type"] == "weapon":
		weapon_manager.activate_weapon(reward_type)
		return
	
	# Handle player power-ups
	match reward_type:
		"health":
			max_health = int(max_health * (1 + reward_value))
			current_health = max_health
			update_health_display()
		"speed":
			speed *= (1 + reward_value)
		"fire_rate":
			shoot_cooldown *= (1 - reward_value)
		"projectile_size":
			projectile_scale *= (1 + reward_value)
		"multi_shot":
			projectile_count += int(reward_value)
			print("New projectile count: ", projectile_count) # Debug print

func _physics_process(delta: float) -> void:
	# Set horizontal direction
	var direction_x := Input.get_axis("move-left", "move-right")

	# Handle flip sprite for horizontal movement direction
	if direction_x < 0:
		$Sprite2D.flip_h = true
		muzzle.position.x = -abs(muzzle.position.x)
	elif direction_x > 0:
		$Sprite2D.flip_h = false
		muzzle.position.x = abs(muzzle.position.x)
		
	# Set vertical direction
	var direction_y := Input.get_axis("move-up", "move-down")

	# Movement vector for moving the player
	var movement_vector := Vector2(direction_x, direction_y)

	# Allow movement if not jumping
	if can_move:
		velocity = movement_vector.normalized() * speed

	# Handle jump action
	if Input.is_action_just_pressed("jump") and can_jump:
		jump()

	# Handle shoot action
	if Input.is_action_just_pressed("shoot") and can_shoot and not is_dead:
		shoot()

	if not is_dead:
		move_and_slide()

func shoot():
	if projectile_scene == null:
		printerr("Projectile scene not assigned!")
		return

	print("Shooting with projectile_count: ", projectile_count) # Debug print

	# Calculate direction to mouse
	var mouse_pos = get_global_mouse_position()
	var shoot_direction = (mouse_pos - global_position).normalized()
	var base_angle = shoot_direction.angle()

	# For multi-shot, we'll use fixed angles instead of spread
	var angles = []
	match projectile_count:
		1:
			angles = [0] # Single shot straight ahead
		2:
			angles = [-0.2, 0.2] # Two shots, slightly spread
		3:
			angles = [-0.3, 0, 0.3] # Three shots, one straight, two spread
		4:
			angles = [-0.4, -0.15, 0.15, 0.4] # Four shots spread
		5:
			angles = [-0.5, -0.25, 0, 0.25, 0.5] # Five shots spread
		_:
			# For more than 5 shots, use dynamic calculation
			var spread = PI / 6 # 30 degrees total spread
			var step = spread / (projectile_count - 1)
			for i in range(projectile_count):
				angles.append(-spread / 2 + step * i)

	print("Number of angles: ", len(angles)) # Debug print

	# Spawn all projectiles
	for i in range(len(angles)):
		var projectile_instance = projectile_scene.instantiate()
		get_tree().root.add_child(projectile_instance)
		
		projectile_instance.global_position = muzzle.global_position
		
		# Add the spread angle to the base angle
		projectile_instance.rotation = base_angle + angles[i]
		
		# Main projectile (middle one) gets full scale, others are smaller
		var is_main_projectile = (i == len(angles) / 2) if len(angles) % 2 == 1 else false
		var base_scale = 0.4 # Make all projectiles 60% smaller (0.4 = 40% of original size)
		var scale_multiplier = 1.0 if is_main_projectile else 0.7
		projectile_instance.scale = Vector2(base_scale * scale_multiplier * projectile_scale, base_scale * scale_multiplier * projectile_scale)
		
		print("Spawning projectile ", i, " with scale: ", projectile_instance.scale) # Debug print
		
		projectile_instance.speed = projectile_speed
		projectile_instance.is_player_projectile = true

	# Start cooldown
	can_shoot = false
	shoot_cooldown_timer.start(shoot_cooldown)

func jump() -> void:
	can_jump = false
	can_move = false
	is_invulnerable = true
	jump_timer.start(JUMP_DURATION)
	shadow.play_animation(1 / JUMP_DURATION)
	animation_player.speed_scale = 1 / JUMP_DURATION
	animation_player.play("jump")

func take_damage(damage_amount: int):
	if not is_invulnerable:
		current_health -= damage_amount
		update_health_display()
		
		# Flash the sprite white
		sprite.modulate = Color(1.5, 1.5, 1.5, 1) # Slightly white
		create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.2)
		
		# Start invulnerability
		is_invulnerable = true
		invulnerability_timer.start(invulnerability_duration)
		
		if current_health <= 0:
			die()

func die() -> void:
	is_dead = true
	self.visible = false

func _on_jump_timer_timeout() -> void:
	can_move = true
	is_invulnerable = false
	jump_cooldown_timer.start(jump_cooldown)
	
func _on_jump_cooldown_timer_timeout() -> void:
	can_jump = true

func _on_shoot_cooldown_timer_timeout() -> void:
	can_shoot = true

func _on_invulnerability_timer_timeout() -> void:
	is_invulnerable = false
