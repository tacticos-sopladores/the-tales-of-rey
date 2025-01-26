extends Label

func _process(_delta: float) -> void:
	var enemy_count = get_tree().get_nodes_in_group("enemies").size()
	text = "Enemies: %d" % enemy_count