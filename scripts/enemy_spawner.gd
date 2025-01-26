extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_radius: float = 300.0
@export var min_spawn_time: float = 2.0
@export var max_spawn_time: float = 5.0
@export var max_enemies: int = 10

@onready var spawn_timer := $SpawnTimer
@onready var player := get_tree().get_first_node_in_group("player")

func _ready() -> void:
	randomize()
	_start_spawn_timer()

func _start_spawn_timer() -> void:
	var spawn_time = randf_range(min_spawn_time, max_spawn_time)
	spawn_timer.start(spawn_time)

func _on_spawn_timer_timeout() -> void:
	if get_tree().get_nodes_in_group("enemies").size() < max_enemies and player:
		var spawn_position = _get_random_spawn_position()
		var enemy = enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_position = spawn_position
	
	_start_spawn_timer()

func _get_random_spawn_position() -> Vector2:
	var angle = randf_range(0, TAU)
	var spawn_point = Vector2.from_angle(angle) * spawn_radius
	
	if player:
		return player.global_position + spawn_point
	return spawn_point