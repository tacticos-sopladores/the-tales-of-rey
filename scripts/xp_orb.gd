extends Area2D

@export var xp_value: int = 10
@export var move_speed: float = 150.0
@export var attraction_radius: float = 100.0
@export var attraction_speed: float = 300.0

var player: Node2D = null
var being_attracted: bool = false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance < attraction_radius:
			being_attracted = true
			var direction = (player.global_position - global_position).normalized()
			var speed = lerp(move_speed, attraction_speed, 1.0 - (distance / attraction_radius))
			global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Call collect_xp on player
		if body.has_method("collect_xp"):
			body.collect_xp(xp_value)
		queue_free()
