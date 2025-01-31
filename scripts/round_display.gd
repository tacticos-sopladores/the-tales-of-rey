extends Label

@onready var round_manager = get_node("/root/Level-2/RoundManager")
@onready var time_display = get_parent().get_node("TimeDisplay")

var base_font_size = 48
var pulse_amount = 8
var pulse_speed = 5.0
var time_since_start = 0.0
var is_time_display = false

func _ready() -> void:
	if round_manager:
		round_manager.round_changed.connect(_on_round_changed)
	
	# Check if this is the time display label
	is_time_display = name == "TimeDisplay"

func _process(delta: float) -> void:
	if round_manager:
		if is_time_display:
			var time = round_manager.get_time_remaining()
			var minutes = floor(time / 60)
			var seconds = int(time) % 60
			text = "%d:%02d" % [minutes, seconds]
			
			# Apply pulsating effect when time is low
			if time <= 10:
				time_since_start += delta
				var pulse = sin(time_since_start * pulse_speed) * pulse_amount
				add_theme_font_size_override("font_size", base_font_size + int(pulse))
				add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0)) # Red color
			else:
				add_theme_font_size_override("font_size", base_font_size)
				add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0)) # White color
		else:
			# Regular round display
			text = "Round %d - Enemies: %d" % [
				round_manager.current_round,
				round_manager.enemies_remaining
			]

func _on_round_changed(round_number: int, enemies_count: int) -> void:
	if not is_time_display:
		text = "Round %d - Enemies: %d" % [round_number, enemies_count]