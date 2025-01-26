extends CharacterBody2D

@export var speed: float = 60.0
@export var max_health: int = 20
@export var damage: int = 8
@export var detection_radius: float = 150.0
@export var knockback_force: float = 200.0 # How strong the knockback is
@export var knockback_duration: float = 0.2 # How long the knockback lasts

var enemy_id: String
var current_health: int
var target: Node2D
var current_frame := 0
var animation_timer := 0.0
var frame_duration := 0.15
var is_dead := false
var hit_flash_timer := 0.0
var hit_flash_duration := 0.25 # Increased to 0.25 seconds
var original_color: Color
var knockback_velocity := Vector2.ZERO
var knockback_timer := 0.0

# Predefined colors for enemy tinting
const ENEMY_COLORS := [
	Color(1, 0.5, 0.5, 1), # Light red
	Color(0.5, 1, 0.5, 1), # Light green
	Color(0.5, 0.5, 1, 1), # Light blue
	Color(1, 1, 0.5, 1), # Light yellow
	Color(1, 0.5, 1, 1), # Light purple
	Color(0.5, 1, 1, 1), # Light cyan
]

# Health multipliers for each color
const COLOR_HEALTH_MULTIPLIERS := [
	1.5, # Red enemies are tougher
	1.0, # Green enemies are normal
	0.8, # Blue enemies are weaker
	1.2, # Yellow enemies are slightly tough
	1.3, # Purple enemies are moderately tough
	0.9, # Cyan enemies are slightly weak
]

@onready var sprite := $Sprite2D

func _ready() -> void:
	enemy_id = str(randi())
	
	# Choose random color index
	var color_index = randi() % ENEMY_COLORS.size()
	
	# Apply random color tint
	sprite.modulate = ENEMY_COLORS[color_index]
	original_color = ENEMY_COLORS[color_index]
	
	# Set health based on color
	max_health = int(max_health * COLOR_HEALTH_MULTIPLIERS[color_index])
	current_health = max_health
	
	# Find the player node
	target = get_tree().get_first_node_in_group("player")
	
	# Create health label
	var label = Label.new()
	label.name = "HealthLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 8)
	add_child(label)
	update_health_display()

func update_health_display() -> void:
	var label = get_node("HealthLabel")
	if label:
		label.text = str(current_health) + "/" + str(max_health)
		label.position = Vector2(-20, -20)

func _physics_process(delta: float) -> void:
	if is_dead:
		queue_free()
		return
	
	# Handle knockback
	if knockback_timer > 0:
		knockback_timer -= delta
		velocity = knockback_velocity
		move_and_slide()
		return # Don't move towards player while being knocked back
		
	if target:
		# Move towards player
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		
		# Flip sprite based on movement direction
		sprite.flip_h = direction.x < 0
		
		move_and_slide()
	
	# Handle animation timing
	animation_timer += delta
	if animation_timer >= frame_duration:
		animation_timer = 0
		current_frame = (current_frame + 1) % 4 # 4 frames for idle animation
		sprite.frame = current_frame
	
	# Handle hit flash
	if hit_flash_timer > 0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0:
			sprite.modulate = original_color

func apply_knockback(source: Node2D, projectile_velocity: Vector2 = Vector2.ZERO) -> void:
	if projectile_velocity != Vector2.ZERO:
		# For projectiles, use their velocity direction
		knockback_velocity = projectile_velocity.normalized() * knockback_force
	else:
		# For melee hits, knockback away from the source
		var knockback_direction = (global_position - source.global_position).normalized()
		knockback_velocity = knockback_direction * knockback_force
	
	knockback_timer = knockback_duration

func take_damage(amount: int) -> void:
	current_health -= amount
	update_health_display()
	
	# Flash white
	sprite.modulate = Color.WHITE
	hit_flash_timer = hit_flash_duration
	
	if current_health <= 0:
		is_dead = true

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.get_script() and area.is_player_projectile:
		take_damage(area.damage)
		apply_knockback(area, area.velocity)
	elif area.get_parent() is CharacterBody2D and area.get_parent().is_in_group("player"):
		var player = area.get_parent()
		if player.has_method("take_damage"):
			player.take_damage(damage)
			apply_knockback(player) # Knockback when touching player
