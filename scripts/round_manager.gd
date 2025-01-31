extends Node

signal round_changed(round_number: int, enemies_count: int)
signal round_completed

const BASE_ENEMIES = 25 # Starting number of enemies in round 1
const ENEMY_CURVE_POWER = 1.5 # Power for polynomial scaling (gentler than XP curve)
const ENEMY_MULTIPLIER = 1.5 # How many more enemies to add per round
const ROUND_DURATION = 60.0 # Duration of each round in seconds
const MIN_ROUND_DURATION = 30.0 # Minimum round duration as rounds progress
const ROUND_TIME_REDUCTION = 0.9 # Each round's duration is reduced by this factor

var current_round: int = 1
var enemies_remaining: int = 0
var total_enemies_for_round: int = 0
var round_timer: Timer
var time_remaining: float = 0.0

func _ready() -> void:
	round_timer = Timer.new()
	round_timer.one_shot = true
	round_timer.timeout.connect(_on_round_timer_timeout)
	add_child(round_timer)
	start_round(current_round)

func _process(delta: float) -> void:
	if round_timer.time_left > 0:
		time_remaining = round_timer.time_left

func calculate_enemies_for_round(round_num: int) -> int:
	# Similar to XP curve but gentler scaling
	# Formula: BASE_ENEMIES + (round^POWER * MULTIPLIER)
	return BASE_ENEMIES + int(pow(round_num, ENEMY_CURVE_POWER) * ENEMY_MULTIPLIER)

func calculate_round_duration(round_num: int) -> float:
	# Calculate round duration that decreases each round but never goes below minimum
	return max(ROUND_DURATION * pow(ROUND_TIME_REDUCTION, round_num - 1), MIN_ROUND_DURATION)

func start_round(round_num: int) -> void:
	current_round = round_num
	total_enemies_for_round = calculate_enemies_for_round(round_num)
	enemies_remaining = total_enemies_for_round
	
	# Start the round timer
	var duration = calculate_round_duration(round_num)
	round_timer.start(duration)
	time_remaining = duration
	
	print("Starting round: ", round_num, " with ", total_enemies_for_round, " enemies") # Debug info
	emit_signal("round_changed", current_round, total_enemies_for_round)

func enemy_defeated() -> void:
	enemies_remaining -= 1
	if enemies_remaining <= 0:
		emit_signal("round_completed")
		start_round(current_round + 1)

func _on_round_timer_timeout() -> void:
	# When time runs out, force start the next round
	emit_signal("round_completed")
	start_round(current_round + 1)

# Called by enemy spawner to know how many enemies to spawn
func get_max_enemies() -> int:
	return total_enemies_for_round

# Get the current round's remaining time (for UI display)
func get_time_remaining() -> float:
	return time_remaining