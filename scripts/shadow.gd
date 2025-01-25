extends Node2D

@onready var animation_player := $Sprite2D/AnimationPlayer

func play_animation(jump_duration: float) -> void:
	animation_player.speed_scale = jump_duration
	animation_player.play("jump")
