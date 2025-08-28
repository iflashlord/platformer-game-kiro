extends BaseLevel
class_name Level01Simple

func _ready():
	level_id = "Level01"
	level_name = "Forest Adventure"
	target_score = 200
	super._ready()

func setup_level():
	# Level-specific setup after BaseLevel initialization
	print("🌲 Level 1: Forest Adventure loaded")
	
	# Safely play music if Audio system is available and method exists
	if Audio and Audio.has_method("play_music"):
		Audio.play_music("level_1_theme")
	else:
		print("⚠️ Audio system or play_music method not available")
	
	# Set current level for persistence (override BaseLevel's Game.current_level)
	Game.current_level = level_id
	
	print("✅ Level 1 systems initialized")
	print("🎮 LEVEL ELEMENTS:")
	print("  📦 Crates: ", get_tree().get_nodes_in_group("crates").size())
	print("  🍎 Fruits: ", get_tree().get_nodes_in_group("fruits").size())
	print("  💎 Gems: ", get_tree().get_nodes_in_group("gems").size())
	print("  👹 Enemies: ", get_tree().get_nodes_in_group("enemies").size())
	print("  🔺 Spikes: ", get_tree().get_nodes_in_group("spikes").size())
	print("  🦘 Jump Pads: ", get_tree().get_nodes_in_group("jump_pads").size())
	print("  💀 Death Zones: ", get_tree().get_nodes_in_group("death_zones").size())
	print("🎮 Jump across platforms, collect items, avoid hazards, and reach the portal!")


func setup_layer_examples():
	# Wait a frame to ensure DimensionManager is ready
	await get_tree().process_frame
	
	var dim_manager = get_node("DimensionManager")
	if not dim_manager:
		print("❌ DimensionManager not found!")
		return
	
	print("🌀 Setting up layer examples...")
	
	# Make Platform1 only visible in Layer A
	if has_node("Level/Platform1"):
		dim_manager.register_layer_object($Level/Platform1, "A")
		print("✅ Platform1 registered to Layer A")
	
	# Make Platform2 only visible in Layer B  
	if has_node("Level/Platform2"):
		dim_manager.register_layer_object($Level/Platform2, "B")
		print("✅ Platform2 registered to Layer B")
	
	# Platform3 stays visible in both layers (don't register it)
	print("✅ Platform3 remains visible in both layers")
	
	# Connect to layer changes for debugging
	dim_manager.layer_changed.connect(_on_layer_changed)
	
	print("🌀 Layer system ready! Current layer: ", dim_manager.get_current_layer())

func _on_layer_changed(new_layer: String):
	print("🌀 LEVEL: Layer changed to ", new_layer)
	
	# Optional: Add visual feedback
	if new_layer == "A":
		modulate = Color(1, 1, 1, 1)  # Normal
	else:
		modulate = Color(1, 0.9, 1, 1)  # Slight purple tint
	
	
	
# Level completion is now handled by the LevelPortal directly

# LEVEL EVENT HANDLERS - BaseLevel handles the core events
# Override these if you need level-specific behavior

func _on_player_died():
	super._on_player_died()  # Call BaseLevel's handler
	print("💀 Player died in Level 1")

func _on_game_over():
	print("💀 Game Over in Level 1 - restarting level")
	super._on_game_over()  # Call BaseLevel's handler

# INPUT HANDLING
func _input(event):
	# ESC to return to menu
	if Input.is_action_just_pressed("ui_cancel"):
		print("🏠 Returning to main menu from Level 1")
		get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
	
	# R to restart level
	if Input.is_action_just_pressed("restart"):
		print("🔄 Restarting Level 1")
		get_tree().reload_current_scene()
	
	# # Debug: Show level stats
	# if Input.is_action_just_pressed("ui_select"):
	# 	_show_level_stats()

# UTILITY FUNCTIONS
# func _show_level_stats():
# 	if level_manager:
# 		var stats = level_manager.get_level_stats()
# 		print("📊 LEVEL 1 STATISTICS:")
# 		print("  Fruits: ", stats.fruits_collected, "/", stats.total_fruits)
# 		print("  Gems: ", stats.gems_collected, "/", stats.total_gems)
# 		print("  Enemies defeated: ", stats.enemies_defeated, "/", stats.total_enemies)
# 		print("  Crates destroyed: ", stats.crates_destroyed, "/", stats.total_crates)
# 		print("  Damage taken: ", stats.damage_taken)
# 		print("  Completion: ", level_manager.get_completion_percentage(), "%")
# 		print("  Perfect run: ", level_manager.is_perfect_completion())
# 		print("  Current score: ", Game.get_score() if Game else 0)
# 		print("  Current health: ", HealthSystem.get_current_health() if HealthSystem else 0)
# 		print("  Time elapsed: ", stats.completion_time, " seconds")
