extends Area2D

@export var speed: float
@export var lifetime: float
@export var is_player_projectile: bool = true
@export var damage: int = 10
@export var is_orbiting: bool = false

@onready var projectile_lifetime_timer := $ProjectileLifetimeTimer
@onready var animation_player := $AnimationPlayer
@onready var sprite := $Sprite2D
@onready var collision := $CollisionShape2D

var velocity := Vector2.ZERO
var base_scale := Vector2.ONE

func _ready():
	base_scale = scale
	
	if is_orbiting:
		# For orbiting projectiles, just set the scale directly and use first frame
		sprite.scale = base_scale
		collision.scale = base_scale
		sprite.frame = 0 # Use the first frame for orbiting bubbles
		sprite.pause() # Prevent animation from playing
	else:
		# Reset to small scale for grow animation
		sprite.scale = Vector2(0.2, 0.2)
		collision.scale = Vector2(0.2, 0.2)
		# Start grow animation
		animation_player.play("grow")
		projectile_lifetime_timer.start(lifetime)
	
func _physics_process(delta):
	if not is_orbiting:
		# Use rotation to determine velocity direction
		var direction = Vector2(cos(rotation), sin(rotation))
		velocity = direction * speed
		position += velocity * delta

func _on_area_entered(area):
	if is_player_projectile:
		if area.is_in_group("enemies"):
			var enemy = area.get_parent()
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
			if not is_orbiting:
				animation_player.play("pop")
	elif not is_player_projectile:
		if area.is_in_group("player"):
			var player = area.get_parent()
			if player.has_method("take_damage"):
				player.take_damage(damage)
			animation_player.play("pop")

func _on_projectile_lifetime_timer_timeout() -> void:
	if not is_orbiting:
		animation_player.play("pop")
	
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "grow":
		# After grow animation, apply the scale from the player
		sprite.scale = base_scale
		collision.scale = base_scale
	elif anim_name == "pop" and not is_orbiting:
		queue_free()
