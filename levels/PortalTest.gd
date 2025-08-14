extends Node2D

@onready var player: Player = $Player

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
	
	print("✅ Portal test systems initialized")
	print("🎮 Walk to the cyan portal to test completion!")

func _input(event):
	# ESC to return to menu
	if Input.is_action_just_pressed("ui_cancel"):
		print("🏠 Returning to level map from portal test")
		get_tree().change_scene_to_file("res://ui/LevelMap.tscn")