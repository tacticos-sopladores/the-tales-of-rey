extends Node

const BUG_SCENE = preload("res://scenes/bug_enemy.tscn")

@export var spawn_radius: float = 100.0
@export var min_spawn_time: float = 2.0
@export var max_spawn_time: float = 5.0
@export var max_enemies: int = 3

var spawn_timer: float = 0.0
var current_spawn_time: float = 2.0
var player: Node2D

# Bug types with their properties
const BUG_TYPES = {
	"UmberMoth": {
		"sprite_path": "res://assets/bugs/UmberMoth.png",
		"health": 25,
		"speed": 45.0,
		"damage": 8
	},
	"VividGrasshopper": {
		"sprite_path": "res://assets/bugs/VividGrasshopper.png",
		"health": 15,
		"speed": 60.0,
		"damage": 5
	},
	"SlimySnail": {
		"sprite_path": "res://assets/bugs/SlimySnail.png",
		"health": 40,
		"speed": 20.0,
		"damage": 12
	},
	"ViciousWasp": {
		"sprite_path": "res://assets/bugs/ViciousWasp.png",
		"health": 18,
		"speed": 70.0,
		"damage": 10
	},
	"OnyxWidow": {
		"sprite_path": "res://assets/bugs/OnyxWidow.png",
		"health": 22,
		"speed": 50.0,
		"damage": 15
	}
}

func _ready() -> void:
	# Find the player node
	player = get_tree().get_first_node_in_group("player")
	current_spawn_time = randf_range(min_spawn_time, max_spawn_time)

func _process(delta: float) -> void:
	if player == null:
		return
		
	spawn_timer += delta
	if spawn_timer >= current_spawn_time:
		spawn_timer = 0
		current_spawn_time = randf_range(min_spawn_time, max_spawn_time)
		
		# Only spawn if we haven't reached max enemies
		var current_enemies = get_tree().get_nodes_in_group("enemies").size()
		if current_enemies < max_enemies:
			# Calculate random spawn position around player
			var angle = randf() * 2 * PI
			var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_radius
			
			# Spawn random bug
			var bug = spawn_random_bug(spawn_pos)
			get_parent().add_child(bug)

# Function to spawn a specific bug type at a position
func spawn_bug(bug_type: String, position: Vector2) -> CharacterBody2D:
	if not BUG_TYPES.has(bug_type):
		push_error("Invalid bug type: " + bug_type)
		return null
		
	var bug = BUG_SCENE.instantiate()
	bug.position = position
	
	# Set bug properties
	var properties = BUG_TYPES[bug_type]
	bug.max_health = properties["health"]
	bug.speed = properties["speed"]
	bug.damage = properties["damage"]
	
	# Set sprite texture
	var sprite = bug.get_node("Sprite2D")
	sprite.texture = load(properties["sprite_path"])
	
	return bug

# Function to spawn a random bug type
func spawn_random_bug(position: Vector2) -> CharacterBody2D:
	var bug_types = BUG_TYPES.keys()
	var random_type = bug_types[randi() % bug_types.size()]
	return spawn_bug(random_type, position)
