extends Node2D

@onready var animation_player := $Sprite2D/AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func play_animation(jump_time: float) -> void:
	animation_player.play("jump")

func reset_animation() -> void:
	animation_player.play("RESET")
