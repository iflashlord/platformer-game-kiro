extends Node2D

@onready var player: Player = $Player
@onready var hud = $UI/GameHUD

func _ready():
	print("🌲 Level 1: Simple Version loaded")
	
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
	
	print("✅ Level 1 Simple systems initialized")
	print("🎮 Jump to the platform, avoid death zones, reach the portal!")

func _on_player_died():
	print("💀 Player died in Level 1")

func _on_game_over():
	print("💀 Game Over in Level 1 - restarting level")
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

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
		print("📊 LEVEL 1 SIMPLE STATISTICS:")
		print("  Current score: ", Game.get_score() if Game else 0)
		print("  Current health: ", HealthSystem.get_current_health() if HealthSystem else 0)
		print("  Time elapsed: ", GameTimer.get_current_time() if GameTimer else 0)
