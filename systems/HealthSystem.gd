extends Node

signal health_changed(current_health: int, max_health: int)
signal player_died()
signal heart_lost()

var max_health: int = 5
var current_health: int = 5

func _ready():
	# Connect to player death events
	if EventBus:
		EventBus.player_died.connect(_on_player_died)

func reset_health():
	current_health = max_health
	health_changed.emit(current_health, max_health)

func lose_heart():
	if current_health > 0:
		current_health -= 1
		heart_lost.emit()
		health_changed.emit(current_health, max_health)
		
		# Visual feedback
		FX.screen_shake(150, 0.3)
		FX.flash_screen(Color.RED * 0.4, 0.2)
		
		# Audio feedback
		Audio.play_sfx("heart_lost")
		
		print("Heart lost! Health: ", current_health, "/", max_health)
		
		# Check for game over
		if current_health <= 0:
			_trigger_game_over()

func gain_heart():
	if current_health < max_health:
		current_health += 1
		health_changed.emit(current_health, max_health)
		
		# Visual feedback
		FX.flash_screen(Color.GREEN * 0.3, 0.2)
		
		# Audio feedback
		Audio.play_sfx("heart_gained")
		
		print("Heart gained! Health: ", current_health, "/", max_health)

func get_current_health() -> int:
	return current_health

func get_max_health() -> int:
	return max_health

func is_alive() -> bool:
	return current_health > 0

func _on_player_died():
	lose_heart()

func _trigger_game_over():
	player_died.emit()
	
	# Wait a moment for effects to play
	await get_tree().create_timer(1.0).timeout
	
	# Show game over screen or restart level
	if Game.current_level != "":
		print("Game Over! Restarting level...")
		LevelLoader.restart()
	else:
		print("Game Over! Returning to menu...")
		get_tree().change_scene_to_file("res://ui/MainMenu.tscn")