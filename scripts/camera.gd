extends Camera2D

@onready var target_node = get_parent().get_node("Player/CharacterBody2D")

func _process(_delta):
	position = target_node.global_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.g
