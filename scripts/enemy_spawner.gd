extends Node2D

@export var enemy_scene: PackedScene
@export var min_spawn_radius: float = 250.0 # Minimum safe distance from player
@export var max_spawn_radius: float = 500.0 # Maximum spawn distance
@export var min_spawn_time: float = 2.0
@export var max_spawn_time: float = 5.0

const BASE_MIN_SPAWN_TIME := 1.0
const BASE_MAX_SPAWN_TIME := 3.0
const MIN_POSSIBLE_SPAWN_TIME := 0.3 # Fastest possible spawn time
const SPAWN_TIME_REDUCTION := 0.15 # Reduction factor per round

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
@onready var round_manager = get_node("/root/Level-2/RoundManager")

var bug_enemy_scene: PackedScene
var current_round_bug_types := [] # Holds the current bug sprite names
var available_bug_types := [] # Pool of unlocked bug types
var current_tint_pool_size := 1 # Start with 1 easiest tint

# Track the current tint index for regular enemies (every 10th round)
var current_tint_index := 0

# Sort enemy colors by difficulty (from easiest to hardest based on health multipliers)
const SORTED_COLOR_INDICES = [
	2, # Blue (0.8)
	5, # Cyan (0.9)
	1, # Green (1.0)
	3, # Yellow (1.2)
	4, # Purple (1.3)
	0, # Red (1.5)
]

func _ready() -> void:
	randomize()
	bug_enemy_scene = preload("res://scenes/bug_enemy.tscn")
	_start_spawn_timer()
	# Initialize with just 1 bug type
	_select_initial_bug_types()
	
	# Connect to round manager signals
	if round_manager:
		round_manager.round_changed.connect(_on_round_changed)

func _on_round_changed(round_number: int, enemies_count: int) -> void:
	print("Round changed to: ", round_number)
	_select_bug_types_for_round(round_number)

func _select_initial_bug_types() -> void:
	available_bug_types.clear()
	var temp_bug_names = BUG_NAMES.duplicate()
	# Select initial 1 random bug type
	if temp_bug_names.size() > 0:
		var idx = randi() % temp_bug_names.size()
		available_bug_types.append(temp_bug_names[idx])
	current_round_bug_types = available_bug_types.duplicate()
	print("Initial bug type: ", available_bug_types[0]) # Debug info
	print("Initial tint: ", SORTED_COLOR_INDICES[0], " (Blue - 0.8x health)") # Debug info for initial tint

func _should_add_new_bug_type(round_number: int) -> bool:
	# Add new bug type on every non-special round
	return round_number % 10 != 0

func _add_new_bug_type(round_number: int) -> void:
	# Only add new bug type on non-special rounds
	if not _should_add_new_bug_type(round_number):
		return
		
	# Get unused bug types
	var unused_bugs = BUG_NAMES.duplicate()
	for bug in available_bug_types:
		var idx = unused_bugs.find(bug)
		if idx != -1:
			unused_bugs.remove_at(idx)
	
	# Add a new bug type if possible
	if unused_bugs.size() > 0:
		var new_bug = unused_bugs[randi() % unused_bugs.size()]
		available_bug_types.append(new_bug)
		print("Round ", round_number, ": Added new bug type: ", new_bug) # Debug info
		print("Available bug types are now: ", available_bug_types)

func _select_bug_types_for_round(round_number: int) -> void:
	# Add new bug type first (if appropriate round)
	if round_number > 1:
		_add_new_bug_type(round_number)
	
	# Update tint pool size after each special round (11-19, 21-29, etc.)
	if round_number > 10 and (round_number - 1) % 10 == 0:
		current_tint_pool_size = min(current_tint_pool_size + 1, SORTED_COLOR_INDICES.size())
		print("Round ", round_number, ": Increased tint pool size to: ", current_tint_pool_size) # Debug info
	
	# Only select new bug types if it's not a special round
	if round_number % 10 != 0:
		current_round_bug_types = available_bug_types.duplicate()
		print("Round ", round_number, ": Available bug types for this round: ", current_round_bug_types) # Debug info

func _is_special_round(round_number: int) -> bool:
	return round_number % 10 == 0

func _get_color_index_for_special_round(round_number: int) -> int:
	# Calculate which color to use based on the round number
	var progression_index = (round_number / 10 - 1) % SORTED_COLOR_INDICES.size()
	return SORTED_COLOR_INDICES[progression_index]

func _start_spawn_timer() -> void:
	var current_round = round_manager.current_round if round_manager else 1
	
	# Calculate spawn times that decrease with each round
	var adjusted_min = max(BASE_MIN_SPAWN_TIME * pow(SPAWN_TIME_REDUCTION, current_round - 1), MIN_POSSIBLE_SPAWN_TIME)
	var adjusted_max = max(BASE_MAX_SPAWN_TIME * pow(SPAWN_TIME_REDUCTION, current_round - 1), adjusted_min + 0.2)
	
	var spawn_time = randf_range(adjusted_min, adjusted_max)
	spawn_timer.start(spawn_time)

func _on_spawn_timer_timeout() -> void:
	if round_manager and player:
		var current_enemies = get_tree().get_nodes_in_group("enemies").size()
		var max_enemies = round_manager.get_max_enemies()
		
		if current_enemies < max_enemies:
			var spawn_position = _get_random_spawn_position()
			var current_round = round_manager.current_round
			
			var enemy
			if _is_special_round(current_round):
				# Spawn regular enemy with specific tint based on round progression
				enemy = enemy_scene.instantiate()
				var color_index = _get_color_index_for_special_round(current_round)
				# Set the color before adding to scene so _ready() uses correct color
				var enemy_color = enemy.ENEMY_COLORS[color_index]
				enemy.get_node("Sprite2D").modulate = enemy_color
				print("Spawning regular enemy with tint index: ", color_index, " (", enemy_color, ")")
			else:
				# Spawn bug enemy with one of the available bug types and tints
				enemy = bug_enemy_scene.instantiate()
				
				# Select random bug type from current pool
				var bug_name = current_round_bug_types[randi() % current_round_bug_types.size()]
				var texture = load("res://assets/bugs/" + bug_name + ".png")
				
				# Select random tint from current difficulty pool
				var available_tints = SORTED_COLOR_INDICES.slice(0, current_tint_pool_size)
				var color_index = available_tints[randi() % available_tints.size()]
				
				if texture:
					enemy.get_node("Sprite2D").texture = texture
					enemy.get_node("Sprite2D").hframes = 4
					# Set the color before adding to scene so _ready() uses correct color
					var enemy_color = enemy.ENEMY_COLORS[color_index]
					enemy.get_node("Sprite2D").modulate = enemy_color
					print("Spawning bug type: ", bug_name, " with tint index: ", color_index, " (", enemy_color, ")")
			
			add_child(enemy)
			enemy.global_position = spawn_position
	
	_start_spawn_timer()

func _get_random_spawn_position() -> Vector2:
	var angle = randf() * 2 * PI
	var random_distance = randf_range(min_spawn_radius, max_spawn_radius)
	return player.global_position + Vector2(cos(angle), sin(angle)) * random_distance
