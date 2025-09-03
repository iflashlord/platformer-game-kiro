extends Node

# Singleton for managing pause menu across the game

var pause_menu_scene: PackedScene
var current_pause_menu: PauseMenu
var is_pause_menu_loaded: bool = false

func _ready():
	# Load pause menu scene
	pause_menu_scene = preload("res://ui/PauseMenu.tscn")
	
	# Connect to game events
	if Game:
		Game.game_paused.connect(_on_game_paused)
		Game.game_resumed.connect(_on_game_resumed)

func _on_game_paused():
	"""Handle game pause event"""
	show_pause_menu()

func _on_game_resumed():
	"""Handle game resume event"""
	hide_pause_menu()

func _on_level_results_shown():
	"""Handle level results being shown - hide pause menu"""
	print("🔧 PauseManager: Level results shown, hiding pause menu")
	hide_pause_menu()

func show_pause_menu():
	"""Show the pause menu"""
	if current_pause_menu:
		current_pause_menu.show_pause_menu()
		return
	
	# Create pause menu if it doesn't exist
	if not pause_menu_scene:
		if ErrorHandler:
			ErrorHandler.error("Pause menu scene not loaded", "PauseManager")
		return
	
	current_pause_menu = pause_menu_scene.instantiate()
	if not current_pause_menu:
		if ErrorHandler:
			ErrorHandler.error("Failed to instantiate pause menu", "PauseManager")
		return
	
	# Connect pause menu signals
	_connect_pause_menu_signals()
	
	# Add to current scene
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(current_pause_menu)
		current_pause_menu.show_pause_menu()
		is_pause_menu_loaded = true
		if ErrorHandler:
			ErrorHandler.debug("Pause menu shown successfully", "PauseManager")
	else:
		if ErrorHandler:
			ErrorHandler.error("No current scene to add pause menu to", "PauseManager")

func hide_pause_menu():
	"""Hide the pause menu"""
	print("🔧 PauseManager: hide_pause_menu called")
	if current_pause_menu:
		print("🔧 PauseManager: Hiding pause menu instance")
		current_pause_menu.hide_pause_menu()
		# Remove from scene to prevent conflicts
		if current_pause_menu.get_parent():
			print("🔧 PauseManager: Removing pause menu from parent")
			current_pause_menu.get_parent().remove_child(current_pause_menu)
		current_pause_menu.queue_free()
		current_pause_menu = null
		is_pause_menu_loaded = false
		print("🔧 PauseManager: Pause menu cleaned up")
	else:
		print("🔧 PauseManager: No pause menu to hide")

func _connect_pause_menu_signals():
	"""Connect pause menu signals to appropriate handlers"""
	if not current_pause_menu:
		return
	
	current_pause_menu.resume_requested.connect(_on_resume_requested)
	current_pause_menu.restart_requested.connect(_on_restart_requested)
	current_pause_menu.level_select_requested.connect(_on_level_select_requested)
	current_pause_menu.main_menu_requested.connect(_on_main_menu_requested)
	current_pause_menu.quit_requested.connect(_on_quit_requested)

# Signal handlers
func _on_resume_requested():
	"""Handle resume request"""
	if Game:
		Game.toggle_pause()  # This will unpause and hide menu

func _on_restart_requested():
	"""Handle restart request"""
	# Unpause and clean up
	if Game:
		Game.is_paused = false
		get_tree().paused = false
	
	hide_pause_menu()
	
	# Clean up pause menu
	if current_pause_menu:
		current_pause_menu.queue_free()
		current_pause_menu = null
		is_pause_menu_loaded = false
	
	# Restart the game
	if Game and Game.has_method("restart_game"):
		Game.restart_game()
	else:
		_restart_current_scene()



func _on_level_select_requested():
	"""Handle level select request"""
	# Unpause and go to level select
	if Game:
		Game.is_paused = false
		get_tree().paused = false
	
	_transition_to_scene("res://ui/LevelMapPro.tscn")

func _on_main_menu_requested():
	"""Handle main menu request"""
	# Unpause and go to main menu
	if Game:
		Game.is_paused = false
		get_tree().paused = false
	
	_transition_to_scene("res://ui/MainMenu.tscn")

func _on_quit_requested():
	"""Handle quit request"""
	get_tree().quit()

# Helper functions
func _transition_to_scene(scene_path: String):
	"""Safely transition to a scene"""
	# Trigger glitch effect
	_trigger_glitch_transition()
	
	# Clean up pause menu first
	if current_pause_menu:
		current_pause_menu.queue_free()
		current_pause_menu = null
		is_pause_menu_loaded = false
	
	# Wait for glitch effect
	await get_tree().create_timer(0.3).timeout
	
	# Use SceneManager for better transitions
	if SceneManager:
		SceneManager.change_scene(scene_path)
	else:
		# Fallback
		if not FileAccess.file_exists(scene_path):
			if ErrorHandler:
				ErrorHandler.error("Scene not found: " + scene_path, "PauseManager")
			return
		
		var result = get_tree().change_scene_to_file(scene_path)
		if result != OK and ErrorHandler:
			ErrorHandler.report_scene_load_error(scene_path, result)

func _trigger_glitch_transition():
	"""Trigger dimension glitch effect for menu transitions"""
	if DimensionManager and DimensionManager.has_method("trigger_menu_glitch_effect"):
		DimensionManager.trigger_menu_glitch_effect()
		print("🌀 Triggered glitch transition effect from PauseManager")
	else:
		print("⚠️ DimensionManager not available for glitch effect")

func _restart_current_scene():
	"""Restart the current scene as fallback"""
	var current_scene = get_tree().current_scene
	if not current_scene:
		if ErrorHandler:
			ErrorHandler.error("No current scene to restart", "PauseManager")
		return
	
	var scene_path = current_scene.scene_file_path
	if scene_path == "":
		if ErrorHandler:
			ErrorHandler.error("Current scene has no file path", "PauseManager")
		return
	
	if ErrorHandler:
		ErrorHandler.debug("Restarting scene: " + scene_path, "PauseManager")
	_transition_to_scene(scene_path)

func cleanup():
	"""Clean up pause menu resources"""
	if current_pause_menu:
		current_pause_menu.queue_free()
		current_pause_menu = null
		is_pause_menu_loaded = false

func is_pause_menu_active() -> bool:
	"""Check if pause menu is currently active"""
	return current_pause_menu != null and current_pause_menu.is_active()
