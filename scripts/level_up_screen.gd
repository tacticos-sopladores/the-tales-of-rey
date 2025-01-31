extends Control

signal reward_selected(reward_type: String, reward_value: float)

const REWARD_TYPES = {
	# Player power-ups
	"health": {"name": "Max Health +20%", "value": 0.2, "type": "player"},
	"speed": {"name": "Movement Speed +10%", "value": 0.1, "type": "player"},
	"fire_rate": {"name": "Fire Rate +15%", "value": 0.15, "type": "player"},
	"projectile_size": {"name": "Projectile Size +20%", "value": 0.2, "type": "player"},
	"multi_shot": {"name": "Add Projectile", "value": 1.0, "type": "player"},
	
	# Weapon rewards
	"single_shot": {"name": "Auto Bubble", "value": 1.0, "type": "weapon",
		"description": "Shoots 1 bubble at nearby enemies"},
	"dual_shot": {"name": "Dual Bubbles", "value": 1.0, "type": "weapon",
		"description": "Shoots bubbles above and below"},
	"orbit_shot": {"name": "Orbit Bubble", "value": 1.0, "type": "weapon",
		"description": "A bubble that orbits around you"},
	"reverse_orbit_shot": {"name": "Reverse Orbit Bubble", "value": 1.0, "type": "weapon",
		"description": "A bubble that orbits around you in the opposite direction"}
}

# Store button to reward type mapping
var button_rewards: Array[Dictionary] = []

func _ready() -> void:
	# Hide the screen initially
	hide()
	get_tree().paused = false
	
	print("DEBUG: Initializing reward buttons") # Debug print
	
	# Create reward buttons
	var options_container = $Panel/VBoxContainer/RewardOptions
	
	# Change VBoxContainer to HBoxContainer for horizontal layout
	var horizontal_container = HBoxContainer.new()
	horizontal_container.alignment = BoxContainer.ALIGNMENT_CENTER
	horizontal_container.add_theme_constant_override("separation", 20) # Space between buttons
	options_container.add_child(horizontal_container)
	
	for i in range(5): # Create 5 buttons, one for each potential reward
		var button = Button.new()
		button.custom_minimum_size = Vector2(200, 50) # Made buttons slightly smaller to fit horizontally
		button.pressed.connect(_on_reward_button_pressed.bind(i)) # Pass the button index
		horizontal_container.add_child(button)
		button_rewards.append({"button": button, "type": ""}) # Empty type initially
		print("DEBUG: Created button ", i) # Debug print

func show_rewards() -> void:
	print("\nDEBUG: ---- Starting show_rewards ----") # Debug print
	
	# Show 3 random unique rewards, mixing both player and weapon rewards
	var available_rewards = REWARD_TYPES.keys()
	available_rewards.shuffle()
	print("DEBUG: Shuffled rewards: ", available_rewards) # Debug print
	
	# Hide all buttons first
	for reward_data in button_rewards:
		reward_data["button"].hide()
	
	print("DEBUG: Showing 3 random rewards:") # Debug print
	# Show only 3 random rewards and update their text/data
	for i in range(min(3, available_rewards.size())):
		var reward_type = available_rewards[i]
		var reward_data = button_rewards[i]
		var reward_info = REWARD_TYPES[reward_type]
		
		# Set button text based on reward type
		var button_text = reward_info["name"]
		if reward_info["type"] == "weapon" and reward_info.has("description"):
			button_text += "\n" + reward_info["description"]
		
		reward_data["button"].text = button_text
		reward_data["type"] = reward_type # Update the reward type for this button
		reward_data["button"].show()
		print("DEBUG: Button ", i, ": type=", reward_data["type"], ", text=", reward_data["button"].text) # Debug print
	
	print("DEBUG: ---- Finished show_rewards ----\n") # Debug print
	
	# Show the screen and pause the game
	show()
	get_tree().paused = true

func _on_reward_button_pressed(button_index: int) -> void:
	print("\nDEBUG: ---- Button Pressed ----") # Debug print
	print("DEBUG: Button index pressed: ", button_index) # Debug print
	
	var reward_data = button_rewards[button_index]
	var selected_type = reward_data["type"]
	
	print("DEBUG: Selected reward type: ", selected_type) # Debug print
	print("DEBUG: Current visible button states:")
	for data in button_rewards:
		if data["button"].visible:
			print("DEBUG: Button type=", data["type"], ", text=", data["button"].text) # Debug print
	
	# Emit the signal with the selected reward
	emit_signal("reward_selected", selected_type, REWARD_TYPES[selected_type]["value"])
	
	print("DEBUG: ---- Button Press Complete ----\n") # Debug print
	
	# Hide the screen and unpause the game
	hide()
	get_tree().paused = false
