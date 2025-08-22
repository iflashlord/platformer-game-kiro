extends Node2D

@onready var player: Player = $Player
@onready var hud = $UI/GameHUD
@onready var level_manager: LevelManager = $LevelManager

# Level state
var level_completed: bool = false

func _ready():
	print("🌲 Level 1: Forest Adventure loaded")
	
	# Safely play music if Audio system is available and method exists
	if Audio and Audio.has_method("play_music"):
		Audio.play_music("level_1_theme")
	else:
		print("⚠️ Audio system or play_music method not available")
	
	# Add dimension manager TO BE FIXED
	#var dimension_manager = preload("res://systems/DimensionManager.gd").new()
	#dimension_manager.name = "DimensionManager"
	#add_child(dimension_manager)
	#
	## Example: Make some platforms layer-specific
	#setup_layer_examples()
	
	
	# Set current level for persistence
	Game.current_level = "Level01"
	
	# Initialize systems
	HealthSystem.reset_health()
	Respawn.reset_checkpoints()
	
	# Start game timer
	if GameTimer:
		GameTimer.start_timer()
		print("⏱️ Game timer started")
	
	# Reset score
	if Game:
		Game.score = 0
		print("🎯 Score reset to 0")
	
	# Set initial spawn position
	if player:
		Respawn.default_spawn_position = player.global_position
		print("🏁 Level 1 spawn position set: ", player.global_position)
	
	# Connect player signals
	if player:
		player.died.connect(_on_player_died)
	
	# Connect health system to HUD
	if HealthSystem and hud:
		# Disconnect any existing connections
		if HealthSystem.health_changed.is_connected(hud.update_health):
			HealthSystem.health_changed.disconnect(hud.update_health)
		
		HealthSystem.health_changed.connect(hud.update_health)
		HealthSystem.player_died.connect(_on_game_over)
		hud.update_health(HealthSystem.get_current_health(), HealthSystem.get_max_health())
		print("💖 HUD connected to HealthSystem - Current health: ", HealthSystem.get_current_health())
	
	# Initialize level manager (handles all reusable components automatically)
	if level_manager:
		level_manager.initialize_level("Level01_Simple")
	
	print("✅ Level 1 systems initialized")
	print("🎮 LEVEL ELEMENTS:")
	print("  📦 Crates: ", get_tree().get_nodes_in_group("crates").size())
	print("  🍎 Fruits: ", get_tree().get_nodes_in_group("fruits").size())
	print("  💎 Gems: ", get_tree().get_nodes_in_group("gems").size())
	print("  👹 Enemies: ", get_tree().get_nodes_in_group("enemies").size())
	print("  🔺 Spikes: ", get_tree().get_nodes_in_group("spikes").size())
	print("  🦘 Jump Pads: ", get_tree().get_nodes_in_group("jump_pads").size())
	print("  💀 Death Zones: ", get_tree().get_nodes_in_group("death_zones").size())
	print("🔧 COLLISION LAYERS:")
	print("  Player: Layer 2, Mask 1")
	print("  Ground: Layer 1, Mask 0")
	print("  Enemies: Layer 4, Mask 3")
	print("  Collectibles: Layer 8, Mask 2")
	print("  Interactive: Layer 16, Mask 2")
	print("  Hazards: Layer 32, Mask 2")
	print("  Death Zones: Layer 64, Mask 2")
	print("  Checkpoints: Layer 128, Mask 2")
	print("  Portals: Layer 256, Mask 2")
	print("🎮 FEATURES:")
	print("  ✨ Reusable components with self-contained logic")
	print("  🎯 Automatic level management and statistics")
	print("  💥 TNT crates with 3-second countdown")
	print("  🦘 Bounce crates and jump pads")
	print("  💔 Damage system with visual feedback")
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

# LEVEL EVENT HANDLERS
func _on_player_died():
	print("💀 Player died in Level 1")

func _on_game_over():
	print("💀 Game Over in Level 1 - restarting level")
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

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
	
	# Debug: Show level stats
	if Input.is_action_just_pressed("ui_select"):
		_show_level_stats()

# UTILITY FUNCTIONS
func _show_level_stats():
	if level_manager:
		var stats = level_manager.get_level_stats()
		print("📊 LEVEL 1 STATISTICS:")
		print("  Fruits: ", stats.fruits_collected, "/", stats.total_fruits)
		print("  Gems: ", stats.gems_collected, "/", stats.total_gems)
		print("  Enemies defeated: ", stats.enemies_defeated, "/", stats.total_enemies)
		print("  Crates destroyed: ", stats.crates_destroyed, "/", stats.total_crates)
		print("  Damage taken: ", stats.damage_taken)
		print("  Completion: ", level_manager.get_completion_percentage(), "%")
		print("  Perfect run: ", level_manager.is_perfect_completion())
		print("  Current score: ", Game.get_score() if Game else 0)
		print("  Current health: ", HealthSystem.get_current_health() if HealthSystem else 0)
		print("  Time elapsed: ", stats.completion_time, " seconds")
