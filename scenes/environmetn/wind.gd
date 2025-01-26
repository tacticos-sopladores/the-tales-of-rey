extends Node2D

@export var num_points: int = 20  # Number of points in the path
@export var gust_length: float = 500.0 # Approximate length of the gust
@export var gust_width: float = 100.0  # Maximum deviation (width) of the gust
@export var curve_tightness: float = 0.5 # Controls how tight the curves are

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
