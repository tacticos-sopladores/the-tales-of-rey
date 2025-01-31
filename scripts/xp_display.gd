# XP Display script
extends Control

@onready var progress_bar = $ProgressBar
@onready var label = $Label

func _ready() -> void:
	# Connect to player's XP changed signal
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.xp_changed.connect(_on_xp_changed)

func _on_xp_changed(level: int, current_xp: int, required_xp: int) -> void:
	# Update progress bar
	progress_bar.value = float(current_xp) / float(required_xp)
	# Update level text to only show level number
	label.text = "Level %d" % level