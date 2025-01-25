extends Area2D

@export var speed: float
@export var lifetime: float
@export var is_player_projectile: bool = true
@export var damage: int = 10

@onready var projectile_lifetime_timer: Timer = $ProjectileLifetimeTimer

func _ready():
	if is_player_projectile:
		collision_mask = 2 # PlayerProjectiles Layer
	else:
		collision_mask = 4 # EnemyProjectiles Layer
	projectile_lifetime_timer.wait_time = lifetime
	projectile_lifetime_timer.start()

func _physics_process(delta):
	position.x += cos(transform.get_rotation()) * speed * delta
	position.y += sin(transform.get_rotation()) * speed * delta

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
	queue_free()
