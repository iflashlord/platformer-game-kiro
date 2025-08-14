extends Node2D

@onready var player: Player = $Player
@onready var hud = $UI/GameHUD

func _ready():
	print("🎓 Tutorial level loaded")
	
	# Set current level for persistence
	Game.current_level = "Tutorial"
	
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
		print("🏁 Tutorial spawn position set: ", player.global_position)
	
	# Connect player signals
	if player:
		player.died.connect(_on_player_died)
	
	# Connect health system to HUD
	if HealthSystem and hud:
		HealthSystem.health_changed.connect(hud.update_health)
		HealthSystem.player_died.connect(_on_game_over)
		# Also update HUD directly to ensure it shows current health
		hud.update_health(HealthSystem.get_current_health(), HealthSystem.get_max_health())
	
	print("✅ Tutorial systems initialized")
	print("🎮 Use WASD/Arrow keys to move, Space to jump!")
	print("💀 Avoid the red death zones!")
	print("🏁 Reach checkpoints to save your progress!")

func _on_player_died():
	print("💀 Player died in tutorial")

func _on_game_over():
	print("💀 Game Over in tutorial - restarting level")
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

func _input(event):
	# ESC to return to menu
	if Input.is_action_just_pressed("ui_cancel"):
		print("🏠 Returning to main menu from tutorial")
		get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
	
	# R to restart level
	if Input.is_action_just_pressed("restart"):
		print("🔄 Restarting tutorial")
		get_tree().reload_current_scene()
	
	# N to go to next level (for testing)
	if Input.is_action_just_pressed("ui_accept") and Input.is_action_pressed("ui_select"):
		print("➡️ Going to Level 1")
		get_tree().change_scene_to_file("res://levels/Level01.tscn")
