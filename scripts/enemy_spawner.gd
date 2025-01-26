extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_radius: float = 300.0
@export var min_spawn_time: float = 2.0
@export var max_spawn_time: float = 5.0
@export var max_enemies: int = 10

const BUG_NAMES := [
	"AcidAnt", "BlazingSlug", "BloatedBedbug", "CrimsonLadybug",
	"DiseasedFly", "DungBeetle", "EmeraldViper", "ForagingMaggot",
	"GapingLeech", "GiantRat", "LethalScorpion", "MischievousRacoon",
	"OnyxWidow", "OvergrownEarthworm", "RavenousMosquito", "RummagingOpossum",
	"ScroungingSquirrel", "SlimySnail", "SlitheringSnail", "TaintedCockroach",
	"ToxicSlug", "UmberMoth", "ViciousWasp", "VividGrasshopper",
	"VoraciousMouse"
]

@onready var spawn_timer := $SpawnTimer
@onready var player := get_tree().get_first_node_in_group("player")

var bug_enemy_scene: PackedScene

func _ready() -> void:
	randomize()
	bug_enemy_scene = preload("res://scenes/bug_enemy.tscn")
	_start_spawn_timer()

func _start_spawn_timer() -> void:
	var spawn_time = randf_range(min_spawn_time, max_spawn_time)
	spawn_timer.start(spawn_time)

func _on_spawn_timer_timeout() -> void:
	if get_tree().get_nodes_in_group("enemies").size() <= max_enemies and player:
		var spawn_position = _get_random_spawn_position()
		
		# Randomly choose between original enemy and bug enemy
		var enemy
		if randf() < 0.7: # 70% chance for bug enemy
			enemy = bug_enemy_scene.instantiate()
			# Load random bug sprite
			var bug_name = BUG_NAMES[randi() % BUG_NAMES.size()]
			var texture = load("res://assets/bugs/" + bug_name + ".png")
			if texture:
				enemy.get_node("Sprite2D").texture = texture
				enemy.get_node("Sprite2D").hframes = 4 # All bug sprites have 4 frames
		else:
			enemy = enemy_scene.instantiate()
		
		add_child(enemy)
		enemy.global_position = spawn_position
	
	_start_spawn_timer()

func _get_random_spawn_position() -> Vector2:
	var valid := false
	var spawn_point: Vector2
	var left_border = null
	var right_border = null
	var top_border = null
	var bottom_border = null
	var borders = get_tree().get_nodes_in_group("borders")

	for border in borders:
		if border.name == "LeftBorder":
			left_border = border
		elif border.name == "RightBorder":
			right_border = border
		elif border.name == "TopBorder":
			top_border = border
		elif border.name == "BottomBorder":
			bottom_border = border

	var global_spawn_point: Vector2
	while not valid:
		var angle = randf_range(0, TAU)
		spawn_point = Vector2.from_angle(angle) * spawn_radius

		# Convert to global coordinates (important!)
		global_spawn_point = player.global_position + spawn_point if player else spawn_point
		
		# Check if spawn point is within the borders
		var left_bound = left_border.global_position.x
		var right_bound = right_border.global_position.x
		var top_bound = top_border.global_position.y
		var bottom_bound = bottom_border.global_position.y
		
		if (global_spawn_point.x > left_bound and
			global_spawn_point.x < right_bound and
			global_spawn_point.y > top_bound and
			global_spawn_point.y < bottom_bound):
			valid = true

	return global_spawn_point
