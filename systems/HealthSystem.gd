extends Node

signal health_changed(current_health: int, max_health: int)
signal player_died()
signal heart_lost()

var max_health: int = 5
var current_health: int = 5
var is_processing_death: bool = false

func _ready():
	print("💖 HealthSystem: Initializing...")
	
	# Connect to player death events with error handling
	if EventBus:
		if not EventBus.player_died.is_connected(_on_player_died):
			EventBus.player_died.connect(_on_player_died)
			print("💖 HealthSystem: Connected to EventBus.player_died")
		else:
			print("💖 HealthSystem: Already connected to EventBus.player_died")
	else:
		print("❌ HealthSystem: EventBus not found!")
	
	# Initialize health display
	reset_health()
	print("💖 HealthSystem: Ready with ", current_health, "/", max_health, " hearts")

func reset_health():
	print("💖 HealthSystem: Resetting health to full")
	current_health = max_health
	is_processing_death = false
	health_changed.emit(current_health, max_health)

func lose_heart():
	print("💖 HealthSystem: lose_heart() called - Current health: ", current_health)
	
	# Prevent multiple simultaneous heart losses
	if is_processing_death:
		print("⚠️ HealthSystem: Already processing death, ignoring duplicate")
		return
	
	if current_health > 0:
		is_processing_death = true
		current_health -= 1
		heart_lost.emit()
		health_changed.emit(current_health, max_health)
		
		# Visual feedback
		_play_heart_loss_effects()
		
		print("💔 Heart lost! Health: ", current_health, "/", max_health)
		
		# Check for game over
		if current_health <= 0:
			print("💀 No hearts left - triggering game over")
			_trigger_game_over()
		else:
			print("💖 Still have ", current_health, " hearts remaining")
			# Reset processing flag if not game over
			is_processing_death = false
	else:
		print("⚠️ Already at 0 health - cannot lose more hearts")

func _play_heart_loss_effects():
	# Visual feedback with error handling
	if FX:
		FX.shake(100)
		FX.flash_screen(Color.RED * 0.4, 0.2)
	else:
		print("⚠️ FX system not available")
	
	# Audio feedback with error handling
	# if Audio:
	# 	Audio.play_sfx("disappear")
	# else:
	# 	print("⚠️ Audio system not available")

func gain_heart():
	if current_health < max_health:
		current_health += 1
		health_changed.emit(current_health, max_health)
		
		# Visual feedback
		if FX:
			FX.flash_screen(Color.GREEN * 0.3, 0.2)
		
		# Audio feedback
		if Audio:
			Audio.play_sfx("heart_gained")
		
		print("💚 Heart gained! Health: ", current_health, "/", max_health)

func get_current_health() -> int:
	return current_health

func get_max_health() -> int:
	return max_health

func is_alive() -> bool:
	return current_health > 0

func _on_player_died(player = null):
	print("💖 HealthSystem: Player death event received from: ", player)
	lose_heart()

func _trigger_game_over():
	print("💀 HealthSystem: Triggering game over sequence")
	player_died.emit()
	
	# Disable further processing during game over
	is_processing_death = true
	
	# Wait for effects to play
	print("⏱️ Waiting 1.5 seconds for death effects...")
	await get_tree().create_timer(1.5).timeout
	
	# Reset everything for fresh start
	print("🔄 Resetting game state...")
	reset_health()
	
	# Reset checkpoints so player starts from beginning
	if Respawn:
		Respawn.reset_checkpoints()
		print("🏁 Checkpoints reset")
	else:
		print("⚠️ Respawn system not available")
	
	# Always restart the current scene instead of going to menu
	print("🔄 Restarting current level/scene")
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene_path = current_scene.scene_file_path
		if scene_path != "":
			print("🔄 Reloading scene: ", scene_path)
			get_tree().reload_current_scene()
		else:
			# Fallback: if no scene path, still reload
			print("🔄 No scene path found, reloading current scene")
			get_tree().reload_current_scene()
	else:
		# Last resort: reload current scene
		print("🔄 No current scene found, attempting reload anyway")
		get_tree().reload_current_scene()

# Debug method to manually test heart loss
func debug_lose_heart():
	print("🔧 DEBUG: Manually losing heart")
	lose_heart()

# Debug method to check system status
func debug_status():
	print("🔧 DEBUG HealthSystem Status:")
	print("  Current Health: ", current_health, "/", max_health)
	print("  Is Alive: ", is_alive())
	print("  Processing Death: ", is_processing_death)
	print("  EventBus Connected: ", EventBus != null and EventBus.player_died.is_connected(_on_player_died))
