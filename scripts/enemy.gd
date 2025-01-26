extends CharacterBody2D

@export var speed: float = 50.0
@export var max_health: int = 30
@export var damage: int = 10

enum State {IDLE, WALK, HURT}

var current_health: int
var target: Node2D
var current_frame := 0
var animation_timer := 0.0
var frame_duration := 0.1
var current_state := State.IDLE
var hurt_timer := 0.0
var hurt_duration := 0.3

# Animation frames configuration
# Row indices in the spritesheet
const IDLE_ROW := 0 # First row for idle
const WALK_ROW := 1 # Second row for walking
const HURT_ROW := 2 # Third row for hurt
const FRAMES_PER_ROW := 7

# Frame counts for each animation
const IDLE_FRAMES := 7
const WALK_FRAMES := 7
const HURT_FRAMES := 7

@onready var sprite := $Sprite2D

func _ready() -> void:
	current_health = max_health
	# Find the player node
	target = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if target and current_state != State.HURT:
		# Move towards player
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		# Update state based on movement
		current_state = State.WALK if velocity.length() > 0 else State.IDLE
		
		# Flip sprite based on movement direction
		sprite.flip_h = velocity.x < 0
	
	# Handle hurt state timer
	if current_state == State.HURT:
		hurt_timer += delta
		if hurt_timer >= hurt_duration:
			hurt_timer = 0
			current_state = State.IDLE
	
	# Handle animation
	animation_timer += delta
	if animation_timer >= frame_duration:
		animation_timer = 0
		update_animation()

func update_animation() -> void:
	var row: int
	var frame_count: int
	
	match current_state:
		State.IDLE:
			row = IDLE_ROW
			frame_count = IDLE_FRAMES
		State.WALK:
			row = WALK_ROW
			frame_count = WALK_FRAMES
		State.HURT:
			row = HURT_ROW
			frame_count = HURT_FRAMES
	
	current_frame = (current_frame + 1) % frame_count
	sprite.frame = (row * FRAMES_PER_ROW) + current_frame

func take_damage(amount: int) -> void:
	current_health -= amount
	current_state = State.HURT
	hurt_timer = 0
	current_frame = 0
	
	if current_health <= 0:
		queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.get_parent() is CharacterBody2D and area.get_parent().is_player_projectile:
		take_damage(area.get_parent().damage)