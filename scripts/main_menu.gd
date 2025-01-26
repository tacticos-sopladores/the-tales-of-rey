extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/StartButton.grab_focus()
	
func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level-2.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
