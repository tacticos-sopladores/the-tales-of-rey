extends Area2D

@export var speed: float
@export var lifetime: float
@export var is_player_projectile: bool = true
@export var damage: int = 10

@onready var projectile_lifetime_timer := $ProjectileLifetimeTimer
@onready var animation_player := $AnimationPlayer

var velocity := Vector2.ZERO

func _ready():
	animation_player.play("grow")
	projectile_lifetime_timer.start(lifetime)
	
func _physics_process(delta):
	velocity.x = cos(transform.get_rotation()) * speed
	velocity.y = sin(transform.get_rotation()) * speed
	
	position += velocity * delta
	
#func _on_area_entered(area):
#	if is_player_projectile:
#		if area.is_in_group("boss_hitbox"):
#			var boss = area.get_parent()
#			if boss.has_method("take_damage"):
#				boss.take_damage(damage)
#			queue_free()
#	else:
#		if area.is_in_group("player_hitbox"):
#			var player = area.get_parent()
#			if player.has_method("take_damage"):
#				player.take_damage(damage)
#			queue_free()

func _on_projectile_lifetime_timer_timeout() -> void:
	animation_player.play("pop")
	
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "pop":
		queue_free()
