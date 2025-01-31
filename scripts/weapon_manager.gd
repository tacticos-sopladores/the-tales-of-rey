extends Node2D

const WEAPON_TYPES = {
	"single_shot": {
		"name": "Auto Bubble",
		"description": "Shoots 1 bubble at nearby enemies",
		"cooldown": 2.0,
		"damage": 10,
		"speed": 100,
		"upgrades": {
			"cooldown": 0.8, # Multiplier per level (lower is faster)
			"damage": 1.2, # Multiplier per level
			"speed": 1.2 # Multiplier per level
		}
	},
	"dual_shot": {
		"name": "Dual Bubbles",
		"description": "Shoots bubbles above and below",
		"cooldown": 3.0,
		"damage": 8,
		"speed": 80,
		"upgrades": {
			"cooldown": 0.8,
			"damage": 1.2,
			"speed": 1.2
		}
	},
	"orbit_shot": {
		"name": "Orbit Bubble",
		"description": "A bubble that orbits around you",
		"damage": 5,
		"orbit_speed": 2.0,
		"orbit_radius": 30.0,
		"orbit_direction": 1.0, # 1.0 for clockwise, -1.0 for counter-clockwise
		"upgrades": {
			"damage": 1.2,
			"orbit_speed": 1.2,
			"orbit_radius": 1.1
		}
	},
	"reverse_orbit_shot": {
		"name": "Reverse Orbit Bubble",
		"description": "A bubble that orbits around you in the opposite direction",
		"damage": 5,
		"orbit_speed": 2.0,
		"orbit_radius": 45.0, # Starts further away
		"orbit_direction": - 1.0, # Opposite direction
		"upgrades": {
			"damage": 1.2,
			"orbit_speed": 1.2,
			"orbit_radius": 1.1
		}
	}
}

var active_weapons = {}
var projectile_scene = preload("res://scenes/projectile.tscn")
var orbit_bubble_scene = preload("res://scenes/projectile.tscn") # We'll modify this for orbit bubble

@onready var player = get_parent()

func _ready():
	# Initialize timers for automatic weapons
	for weapon_type in WEAPON_TYPES.keys():
		if weapon_type != "orbit_shot" and weapon_type != "reverse_orbit_shot":
			print("DEBUG: Creating timer for weapon type:", weapon_type)
			var timer = Timer.new()
			timer.name = weapon_type + "_Timer"
			timer.one_shot = false
			timer.autostart = false
			add_child(timer)
			timer.timeout.connect(_on_weapon_timer_timeout.bind(weapon_type))
	print("DEBUG: Available weapon types:", WEAPON_TYPES.keys())

func _physics_process(delta):
	if "orbit_shot" in active_weapons or "reverse_orbit_shot" in active_weapons:
		_update_orbit_bubbles(delta)

func activate_weapon(weapon_type: String) -> void:
	print("DEBUG: Attempting to activate weapon:", weapon_type)
	if weapon_type in WEAPON_TYPES:
		if weapon_type in active_weapons:
			# Upgrade existing weapon
			print("DEBUG: Upgrading existing weapon:", weapon_type)
			var weapon_data = active_weapons[weapon_type]
			_apply_weapon_upgrade(weapon_type, weapon_data)
		else:
			# Activate new weapon
			print("DEBUG: Activating new weapon:", weapon_type)
			active_weapons[weapon_type] = WEAPON_TYPES[weapon_type].duplicate(true)
			# Check if it's an orbiting weapon
			if weapon_type == "orbit_shot" or weapon_type == "reverse_orbit_shot":
				print("DEBUG: Spawning orbit weapon:", weapon_type)
				_spawn_orbit_bubble(weapon_type)
			else:
				# Only set up timer for non-orbiting weapons
				print("DEBUG: Setting up timer for weapon:", weapon_type)
				var timer = get_node(weapon_type + "_Timer")
				if "cooldown" in active_weapons[weapon_type]:
					timer.wait_time = active_weapons[weapon_type]["cooldown"]
					timer.start()
	else:
		print("DEBUG: Invalid weapon type:", weapon_type)

func _apply_weapon_upgrade(weapon_type: String, weapon_data: Dictionary) -> void:
	var upgrades = WEAPON_TYPES[weapon_type]["upgrades"]
	
	for stat in upgrades.keys():
		if stat in weapon_data:
			if stat == "cooldown" and (weapon_type != "orbit_shot" and weapon_type != "reverse_orbit_shot"):
				weapon_data[stat] *= upgrades[stat]
				var timer = get_node(weapon_type + "_Timer")
				timer.wait_time = weapon_data[stat]
			else:
				weapon_data[stat] *= upgrades[stat]

func _on_weapon_timer_timeout(weapon_type: String) -> void:
	match weapon_type:
		"single_shot":
			_shoot_at_nearest_enemy()
		"dual_shot":
			_shoot_dual_bubbles()

func _shoot_at_nearest_enemy() -> void:
	var nearest_enemy = _find_nearest_enemy()
	if nearest_enemy:
		var weapon_data = active_weapons["single_shot"]
		var direction = (nearest_enemy.global_position - player.global_position).normalized()
		_spawn_projectile(player.global_position, direction, weapon_data, Vector2(0.4, 0.4), Color(1.0, 0.7, 0.3, 1.0)) # Orange tint for auto bubble

func _shoot_dual_bubbles() -> void:
	var up_direction = Vector2.UP
	var down_direction = Vector2.DOWN
	
	var weapon_data = active_weapons["dual_shot"]
	# Changed to purple tint (more vibrant with increased RGB values)
	var dual_color = Color(1.2, 0.4, 1.4, 1.0) # Bright purple
	_spawn_projectile(player.global_position, up_direction, weapon_data, Vector2(0.3, 0.3), dual_color)
	_spawn_projectile(player.global_position, down_direction, weapon_data, Vector2(0.3, 0.3), dual_color)

func _spawn_projectile(pos: Vector2, direction: Vector2, weapon_data: Dictionary, custom_scale: Vector2 = Vector2.ONE, custom_color: Color = Color.WHITE) -> void:
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	projectile.global_position = pos
	projectile.rotation = direction.angle()
	projectile.speed = weapon_data["speed"]
	projectile.damage = weapon_data["damage"]
	projectile.is_player_projectile = true
	projectile.scale = custom_scale
	
	# Make the sprite brighter by increasing the modulate values above 1.0
	var sprite = projectile.get_node("Sprite2D")
	sprite.modulate = custom_color
	# Add a glow effect by setting the self_modulate to a brighter value
	sprite.self_modulate = Color(1.2, 1.2, 1.2, 1.0) # Makes the whole sprite slightly brighter

var orbit_angle = 0.0
var orbit_bubbles = []

func _spawn_orbit_bubble(weapon_type: String) -> void:
	var weapon_data = active_weapons[weapon_type]
	
	print("DEBUG: Spawning orbit bubble - Type:", weapon_type)
	print("DEBUG: Orbit parameters - Speed:", weapon_data["orbit_speed"],
		  ", Radius:", weapon_data["orbit_radius"],
		  ", Direction:", weapon_data["orbit_direction"])
	
	var bubble = orbit_bubble_scene.instantiate()
	get_tree().root.add_child(bubble)
	bubble.is_player_projectile = true
	bubble.is_orbiting = true
	bubble.lifetime = 999999 # Very long lifetime since we don't want it to disappear
	bubble.damage = weapon_data["damage"]
	
	# Store the weapon type and initial angle as metadata
	bubble.set_meta("weapon_type", weapon_type)
	bubble.set_meta("angle", orbit_angle)
	
	# Make the orbit bubble smaller and add a color tint based on type
	bubble.scale = Vector2(0.25, 0.25)
	if weapon_type == "orbit_shot":
		bubble.get_node("Sprite2D").modulate = Color(0.3, 1.4, 0.5, 1.0) # Bright green
	else:
		bubble.get_node("Sprite2D").modulate = Color(1.4, 0.3, 1.0, 1.0) # Bright magenta
	
	orbit_bubbles.append(bubble)
	
	# Set initial position
	var radius = weapon_data["orbit_radius"]
	var angle = orbit_angle
	var offset = Vector2(cos(angle), sin(angle)) * radius
	bubble.global_position = player.global_position + offset

func _update_orbit_bubbles(delta: float) -> void:
	if "orbit_shot" in active_weapons or "reverse_orbit_shot" in active_weapons:
		for bubble in orbit_bubbles:
			if is_instance_valid(bubble):
				var weapon_type = bubble.get_meta("weapon_type")
				var weapon_data = active_weapons[weapon_type]
				var angle = bubble.get_meta("angle")
				
				# Update angle based on weapon-specific direction and speed
				angle += weapon_data["orbit_speed"] * weapon_data["orbit_direction"] * delta
				bubble.set_meta("angle", angle)
				
				var radius = weapon_data["orbit_radius"]
				var offset = Vector2(cos(angle), sin(angle)) * radius
				bubble.global_position = player.global_position + offset

func _find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_enemy = null
	var nearest_distance = INF
	
	for enemy in enemies:
		if enemy.has_method("take_damage") and not enemy.is_dead: # Only target living enemies
			var distance = player.global_position.distance_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_enemy = enemy
	
	return nearest_enemy
