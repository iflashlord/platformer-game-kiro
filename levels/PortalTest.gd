extends Node2D

@onready var player: Player = $Player
@onready var hud = $UI/GameHUD

func _ready():
	print("🌀 Portal Test level loaded")
	
	# Set current level for persistence
	Game.current_level = "PortalTest"
	
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
		print("🏁 Portal test spawn position set: ", player.global_position)
	
	# Connect health system to HUD
	if HealthSystem and hud:
		# Disconnect any existing connections to avoid duplicates
		if HealthSystem.health_changed.is_connected(hud.update_health):
			HealthSystem.health_changed.disconnect(hud.update_health)
		
		# Connect the signal
		HealthSystem.health_changed.connect(hud.update_health)
		print("💖 HUD connected to HealthSystem")
		
		# Update HUD to show current health
		hud.update_health(HealthSystem.get_current_health(), HealthSystem.get_max_health())
		print("💖 Initial health display updated: ", HealthSystem.get_current_health(), "/", HealthSystem.get_max_health())
	else:
		if not HealthSystem:
			print("❌ HealthSystem not available")
		if not hud:
			print("❌ HUD not available")
	
	print("✅ Portal test systems initialized")
	print("🎮 Walk to the cyan portal to test completion!")
	print("💀 Fall off the platform to test the heart system!")

func _input(event):
	# ESC to return to menu
	if Input.is_action_just_pressed("ui_cancel"):
		print("🏠 Returning to level map from portal test")
		get_tree().change_scene_to_file("res://ui/LevelMap.tscn")
	
	# Debug keys for testing health system
	if Input.is_action_just_pressed("ui_accept"):  # Enter key
		print("🔧 DEBUG: Manually testing heart loss")
		if HealthSystem:
			HealthSystem.debug_lose_heart()
	
	if Input.is_action_just_pressed("ui_select"):  # Space key (if not jumping)
		print("🔧 DEBUG: Health system status")
		if HealthSystem:
			HealthSystem.debug_status()