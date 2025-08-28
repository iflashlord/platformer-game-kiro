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
	
	print("🎮 PauseManager initialized")

func _on_game_paused():
	"""Handle game pause event"""
	show_pause_menu()

func _on_game_resumed():
	"""Handle game resume event"""
	hide_pause_menu()

func show_pause_menu():
	"""Show the pause menu"""
	if current_pause_menu:
		current_pause_menu.show_pause_menu()
		return
	
	# Create pause menu if it doesn't exist
	if not pause_menu_scene:
		print("❌ Pause menu scene not loaded")
		return
	
	current_pause_menu = pause_menu_scene.instantiate()
	if not current_pause_menu:
		print("❌ Failed to instantiate pause menu")
		return
	
	# Connect pause menu signals
	_connect_pause_menu_signals()
	
	# Add to current scene
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(current_pause_menu)
		current_pause_menu.show_pause_menu()
		is_pause_menu_loaded = true
		print("✅ Pause menu shown")
	else:
		print("❌ No current scene to add pause menu to")

func hide_pause_menu():
	"""Hide the pause menu"""
	if current_pause_menu:
		current_pause_menu.hide_pause_menu()

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
	print("🎮 Resume requested")
	if Game:
		Game.toggle_pause()  # This will unpause and hide menu

func _on_restart_requested():
	"""Handle restart request"""
	print("🎮 Restart requested")
	
	# Unpause first
	if Game:
		Game.is_paused = false
		get_tree().paused = false
	
	# Hide pause menu
	hide_pause_menu()
	
	# Clean up pause menu
	if current_pause_menu:
		current_pause_menu.queue_free()
		current_pause_menu = null
		is_pause_menu_loaded = false
	
	# Use Game singleton restart method (most reliable)
	if Game and Game.has_method("restart_game"):
		print("🔄 Using Game.restart_game()")
		Game.restart_game()
	else:
		# Fallback: reload current scene
		print("🔄 Using scene reload fallback")
		_restart_current_scene()



func _on_level_select_requested():
	"""Handle level select request"""
	print("🎮 Level select requested")
	
	# Unpause and go to level select
	if Game:
		Game.is_paused = false
		get_tree().paused = false
	
	_transition_to_scene("res://ui/LevelMapPro.tscn")

func _on_main_menu_requested():
	"""Handle main menu request"""
	print("🎮 Main menu requested")
	
	# Unpause and go to main menu
	if Game:
		Game.is_paused = false
		get_tree().paused = false
	
	_transition_to_scene("res://ui/MainMenu.tscn")

func _on_quit_requested():
	"""Handle quit request"""
	print("🎮 Quit requested")
	get_tree().quit()

# Helper functions
func _transition_to_scene(scene_path: String):
	"""Safely transition to a scene"""
	if not FileAccess.file_exists(scene_path):
		print("❌ Scene not found: ", scene_path)
		return
	
	# Clean up pause menu
	if current_pause_menu:
		current_pause_menu.queue_free()
		current_pause_menu = null
		is_pause_menu_loaded = false
	
	# Change scene
	var result = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		print("❌ Failed to load scene: ", scene_path)

func _restart_current_scene():
	"""Restart the current scene as fallback"""
	var current_scene = get_tree().current_scene
	if not current_scene:
		print("❌ No current scene to restart")
		return
	
	var scene_path = current_scene.scene_file_path
	if scene_path == "":
		print("❌ Current scene has no file path")
		return
	
	print("🔄 Restarting scene: ", scene_path)
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