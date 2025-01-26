extends CharacterBody2D

@export var speed: float = 50.0
@export var max_health: int = 30
@export var damage: int = 10
@export var detection_radius: float = 100.0 # Distance at which enemy detects player

enum State {SLEEP, APPEAR, IDLE, WALK, ATTACK, HURT, DEATH}
enum Direction {DOWN, SIDE, UP}

var enemy_id: String
var current_health: int
var target: Node2D
var current_frame := 0
var animation_timer := 0.0
var frame_duration := 0.1
var current_state := State.SLEEP # Changed initial state to SLEEP
var current_direction := Direction.DOWN
var state_timer := 0.0
var appear_duration := 1.4 # 7 frames × 0.2 seconds
var hurt_duration := 0.5
var attack_duration := 0.6
var is_dead := false
var has_detected_player := false # Track if player has been detected

# Animation frames configuration
const FRAMES_PER_ROW := 7

# Row indices for each animation state and direction
const SLEEP_ROWS := [0, 1, 2] # Down, Side, Up - 3 frames each
const APPEAR_ROWS := [3, 4, 5] # Down, Side, Up - 7 frames each
const IDLE_ROWS := [6, 7, 8] # Down, Side, Up - 4 frames each
const WALK_ROWS := [9, 10, 11] # Down, Side, Up - 4 frames each
const ATTACK_ROWS := [12, 13, 14] # Down, Side, Up - 6 frames each
const HURT_ROWS := [15, 16, 17] # Down, Side, Up - 5 frames each
const DEATH_ROWS := [18, 19, 20] # Down, Side, Up - 6 frames each

# Frame counts for each animation state
const SLEEP_FRAMES := 3
const APPEAR_FRAMES := 7
const IDLE_FRAMES := 4
const WALK_FRAMES := 4
const ATTACK_FRAMES := 6
const HURT_FRAMES := 5
const DEATH_FRAMES := 6

@onready var sprite := $Sprite2D

func _ready() -> void:
	# Assign a unique ID to this enemy
	enemy_id = str(randi())
	current_health = max_health
	# Find the player node
	target = get_tree().get_first_node_in_group("player")
	# Create health label
	var label = Label.new()
	label.name = "HealthLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Make the label smaller
	label.add_theme_font_size_override("font_size", 8)
	add_child(label)
	update_health_display()
	# print("Enemy ", enemy_id, " spawned")

func update_health_display() -> void:
	var label = get_node("HealthLabel")
	if label:
		label.text = str(current_health) + "/" + str(max_health)
		# Position the label above the enemy
		label.position = Vector2(-20, -20)

func _physics_process(delta: float) -> void:
	if is_dead:
		# Don't return immediately if dead - let the death animation play
		if current_state != State.DEATH:
			current_state = State.DEATH
			current_frame = 0
			state_timer = 0
		
	if target and !is_dead:
		var distance_to_player = global_position.distance_to(target.global_position)
		
		# Check if player is in detection range and enemy hasn't detected them yet
		if distance_to_player <= detection_radius and !has_detected_player and current_state == State.SLEEP:
			# print("Enemy ", enemy_id, " detected player - Transitioning from SLEEP to APPEAR")
			current_state = State.APPEAR
			current_frame = 0
			state_timer = 0
			has_detected_player = true
		
		# Only move if player has been detected and appear animation is complete
		if has_detected_player and current_state not in [State.SLEEP, State.HURT, State.ATTACK, State.APPEAR, State.DEATH]:
			# Move towards player
			var direction = (target.global_position - global_position).normalized()
			velocity = direction * speed
			
			# Update direction based on movement
			if abs(direction.y) > abs(direction.x):
				current_direction = Direction.DOWN if direction.y > 0 else Direction.UP
			else:
				current_direction = Direction.SIDE
				sprite.flip_h = direction.x < 0
			
			# Update state based on movement
			var new_state = State.WALK if velocity.length() > 0 else State.IDLE
			if new_state != current_state:
				# print("Enemy ", enemy_id, " state changing from ", State.keys()[current_state], " to ", State.keys()[new_state])
				current_state = new_state
			move_and_slide()
			
		elif !has_detected_player:
			velocity = Vector2.ZERO
	
	# Handle state timers
	state_timer += delta
	match current_state:
		State.APPEAR:
			if state_timer >= appear_duration:
				# print("Enemy ", enemy_id, " APPEAR animation complete - Transitioning to IDLE")
				state_timer = 0
				current_state = State.IDLE
		State.HURT:
			if state_timer >= hurt_duration:
				state_timer = 0
				current_state = State.IDLE
		State.ATTACK:
			if state_timer >= attack_duration:
				state_timer = 0
				current_state = State.IDLE
		State.DEATH:
			if current_frame >= DEATH_FRAMES - 1:
				# print("Enemy ", enemy_id, " death animation complete - removing")
				queue_free()
			else:
				# Keep playing death animation
				animation_timer += delta
				if animation_timer >= frame_duration:
					animation_timer = 0
					current_frame = min(current_frame + 1, DEATH_FRAMES - 1)
					var row = DEATH_ROWS[current_direction]
					sprite.frame = (row * FRAMES_PER_ROW) + current_frame
				return
	
	# Handle animation timing
	animation_timer += delta
	if animation_timer >= frame_duration:
		animation_timer = 0
		update_animation()

func update_animation() -> void:
	var row: int
	var frame_count: int
	var row_offset: int = current_direction
	
	match current_state:
		State.SLEEP:
			row = SLEEP_ROWS[row_offset]
			frame_count = SLEEP_FRAMES
		State.APPEAR:
			row = APPEAR_ROWS[row_offset]
			frame_count = APPEAR_FRAMES
		State.IDLE:
			row = IDLE_ROWS[row_offset]
			frame_count = IDLE_FRAMES
		State.WALK:
			row = WALK_ROWS[row_offset]
			frame_count = WALK_FRAMES
		State.ATTACK:
			row = ATTACK_ROWS[row_offset]
			frame_count = ATTACK_FRAMES
		State.HURT:
			row = HURT_ROWS[row_offset]
			frame_count = HURT_FRAMES
		State.DEATH:
			row = DEATH_ROWS[row_offset]
			frame_count = DEATH_FRAMES
	
	current_frame = (current_frame + 1) % frame_count
	sprite.frame = (row * FRAMES_PER_ROW) + current_frame

func take_damage(amount: int) -> void:
	if current_state == State.DEATH:
		return
		
	current_health -= amount
	update_health_display()
	# print("Enemy ", enemy_id, " took damage, health: ", current_health, "/", max_health)
	
	if current_health <= 0:
		# print("Enemy ", enemy_id, " died - starting death animation")
		is_dead = true
		current_state = State.DEATH
		current_frame = 0
		state_timer = 0
	else:
		current_state = State.HURT
		current_frame = 0
		state_timer = 0

func attack() -> void:
	if current_state not in [State.HURT, State.DEATH, State.APPEAR]:
		current_state = State.ATTACK
		current_frame = 0
		state_timer = 0

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.get_script() and area.is_player_projectile:
		take_damage(area.damage)
	elif area.get_parent() is CharacterBody2D and area.get_parent().is_in_group("player"):
		var player = area.get_parent()
		if player.has_method("take_damage"):
			player.take_damage(damage)
			attack() # Trigger attack animation when hitting player
