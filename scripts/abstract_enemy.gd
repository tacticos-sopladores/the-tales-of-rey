extends Node2D

@export var hitBox: Shape2D;
@export var sprite: Texture2D;
@export var life: int;
@export var damage: int;

@onready var body: Sprite2D = $"abstract-body/abstract-sprite";
@onready var soul: CollisionShape2D = $"abstract-body/abstract-soul"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body.set_texture(sprite);
	soul.set_shape(hitBox);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
