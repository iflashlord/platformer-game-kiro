extends Node2D

@onready var player: Player = $Player
@onready var hud = $UI/GameHUD
@onready var level_manager: LevelManager = $LevelManager

# Advanced level state
var level_completed: bool = false
var combo_multiplier: float = 1.0
var combo_count: int = 0
var combo_timer: float = 0.0
var max_combo_time: float = 3.0
var secrets_found: int = 0
var total_secrets: int = 3
var teleporter_uses: int = 0

# Performance tracking
var start_time: float = 0.0
var completion_time: float = 0.0
var damage_taken: int = 0
var perfect_run: bool = true

func _ready():
	print("🌲 Level 1: ADVANCED Forest Adventure loaded")
	start_time = Time.get_unix_time_from_system()
	
	# Safely play music if Audio system is available and method exists
	if Audio and Audio.has_method("play_music"):
		Audio.play_music("level_1_theme")
	else:
		print("⚠️ Audio system or play_music method not available")
	
	# Set current level for persistence
	Game.current_level = "Level01_Advanced"
	
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
		print("🏁 Level 1 Advanced spawn position set: ", player.global_position)
	
	# Connect player signals
	if player:
		player.died.connect(_on_player_died)
		if player.has_signal("took_damage"):
			player.took_damage.connect(_on_player_took_damage)
	
	# Connect health system to HUD
	if HealthSystem and hud:
		# Disconnect any existing connections
		if HealthSystem.health_changed.is_connected(hud.update_health):
			HealthSystem.health_changed.disconnect(hud.update_health)
		
		HealthSystem.health_changed.connect(hud.update_health)
		HealthSystem.player_died.connect(_on_game_over)
		hud.update_health(HealthSystem.get_current_health(), HealthSystem.get_max_health())
		print("💖 HUD connected to HealthSystem - Current health: ", HealthSystem.get_current_health())
	
	# Connect EventBus signals for advanced features
	if EventBus:
		if EventBus.has_signal("collectible_collected"):
			EventBus.collectible_collected.connect(_on_collectible_collected)
		if EventBus.has_signal("enemy_defeated"):
			EventBus.enemy_defeated.connect(_on_enemy_defeated)
		if EventBus.has_signal("secret_found"):
			EventBus.secret_found.connect(_on_secret_found)
		print("📡 EventBus connected for advanced tracking")
	
	# Initialize level manager (handles all reusable components automatically)
	if level_manager:
		level_manager.initialize_level("Level01_Advanced")
	
	print("✅ Level 1 ADVANCED systems initialized")
	print("🎮 ADVANCED LEVEL ELEMENTS:")
	print("  📦 Crates: ", get_tree().get_nodes_in_group("crates").size())
	print("  🍎 Fruits: ", get_tree().get_nodes_in_group("fruits").size())
	print("  💎 Gems: ", get_tree().get_nodes_in_group("gems").size())
	print("  👹 Enemies: ", get_tree().get_nodes_in_group("enemies").size())
	print("  🦘 Jump Pads: ", get_tree().get_nodes_in_group("jump_pads").size())
	print("  🌀 Teleporters: ", get_tree().get_nodes_in_group("teleporters").size())
	print("  💀 Death Zones: ", get_tree().get_nodes_in_group("death_zones").size())
	print("  ✅ Checkpoints: ", get_tree().get_nodes_in_group("checkpoints").size())
	print("🎯 ADVANCED FEATURES:")
	print("  ✨ Combo system with multipliers")
	print("  🎯 Advanced AI behaviors")
	print("  🏆 Performance tracking and rating system")
	print("  🔍 Hidden secrets and bonus content")
	print("  🌀 Multi-teleporter network")
	print("  🎮 Strategic platforming challenges")
	print("🎮 Master the advanced mechanics to complete this epic forest adventure!")

func _process(delta):
	# Update combo timer
	if combo_count > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			reset_combo()
	
	# Update HUD with advanced info if methods exist
	if hud:
		if hud.has_method("update_combo"):
			hud.update_combo(combo_count, combo_multiplier)
		if hud.has_method("update_secrets"):
			hud.update_secrets(secrets_found, total_secrets)

func _on_collectible_collected(collectible_type: String, points: int):
	# Advanced combo system
	combo_count += 1
	combo_timer = max_combo_time
	combo_multiplier = 1.0 + (combo_count * 0.2)  # 20% increase per combo
	
	var bonus_points = int(points * combo_multiplier)
	if Game:
		Game.add_score(bonus_points)
	
	print("🎯 Combo x", combo_count, " - ", collectible_type, " collected for ", bonus_points, " points!")
	
	# Visual feedback for combo
	if combo_count >= 5:
		print("🔥 COMBO FIRE! x", combo_count)
	elif combo_count >= 3:
		print("⚡ COMBO! x", combo_count)

func _on_enemy_defeated(enemy_type: String):
	print("👹 ", enemy_type, " defeated!")
	if Game:
		Game.add_score(200)  # Bonus points for defeating enemies

func _on_secret_found():
	secrets_found += 1
	print("🔍 Secret found! (", secrets_found, "/", total_secrets, ")")
	if Game:
		Game.add_score(500)  # Big bonus for secrets

func _on_player_took_damage(amount: int):
	damage_taken += amount
	perfect_run = false
	reset_combo()  # Damage breaks combo
	print("💔 Player took ", amount, " damage (total: ", damage_taken, ")")

func reset_combo():
	if combo_count > 0:
		print("💥 Combo reset! Was at x", combo_count)
	combo_count = 0
	combo_multiplier = 1.0
	combo_timer = 0.0

func calculate_level_rating() -> String:
	var rating_score = 0
	
	# Time bonus (faster = better)
	if completion_time < 90:
		rating_score += 30
	elif completion_time < 120:
		rating_score += 20
	elif completion_time < 180:
		rating_score += 10
	
	# Damage penalty
	rating_score -= damage_taken * 5
	
	# Combo bonus
	rating_score += combo_count * 2
	
	# Secrets bonus
	rating_score += secrets_found * 15
	
	# Perfect run bonus
	if perfect_run:
		rating_score += 25
	
	# Teleporter usage bonus (shows exploration)
	if teleporter_uses >= 3:
		rating_score += 10
	
	# Determine rating
	if rating_score >= 80:
		return "S"
	elif rating_score >= 65:
		return "A"
	elif rating_score >= 50:
		return "B"
	elif rating_score >= 35:
		return "C"
	else:
		return "D"

# LEVEL EVENT HANDLERS
func _on_player_died():
	print("💀 Player died in Advanced Level 1")
	perfect_run = false

func _on_game_over():
	print("💀 Game Over in Advanced Level 1 - restarting level")
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

func _on_level_completed():
	level_completed = true
	completion_time = Time.get_unix_time_from_system() - start_time
	
	var rating = calculate_level_rating()
	print("🏆 ADVANCED LEVEL COMPLETED!")
	print("  Rating: ", rating)
	print("  Time: ", completion_time, "s")
	print("  Damage taken: ", damage_taken)
	print("  Secrets found: ", secrets_found, "/", total_secrets)
	print("  Max combo: ", combo_count)
	print("  Teleporter uses: ", teleporter_uses)
	print("  Perfect run: ", perfect_run)

# INPUT HANDLING
func _input(event):
	# ESC to return to menu
	if Input.is_action_just_pressed("ui_cancel"):
		print("🏠 Returning to main menu from Advanced Level 1")
		get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
	
	# R to restart level
	if Input.is_action_just_pressed("restart"):
		print("🔄 Restarting Advanced Level 1")
		get_tree().reload_current_scene()
	
	# Debug: Show advanced level stats
	if Input.is_action_just_pressed("ui_select"):
		_show_advanced_level_stats()
	
	# Toggle instructions
	if Input.is_action_just_pressed("ui_accept"):
		var instructions = $Instructions/InstructionLabel
		if instructions:
			instructions.visible = !instructions.visible

# UTILITY FUNCTIONS
func _show_advanced_level_stats():
	if level_manager:
		var stats = level_manager.get_level_stats()
		print("📊 ADVANCED LEVEL 1 STATISTICS:")
		print("  Fruits: ", stats.fruits_collected, "/", stats.total_fruits)
		print("  Gems: ", stats.gems_collected, "/", stats.total_gems)
		print("  Enemies defeated: ", stats.enemies_defeated, "/", stats.total_enemies)
		print("  Crates destroyed: ", stats.crates_destroyed, "/", stats.total_crates)
		print("  Damage taken: ", damage_taken)
		print("  Current combo: x", combo_count, " (", combo_multiplier, "x multiplier)")
		print("  Secrets found: ", secrets_found, "/", total_secrets)
		print("  Teleporter uses: ", teleporter_uses)
		print("  Completion: ", level_manager.get_completion_percentage(), "%")
		print("  Perfect run: ", perfect_run)
		print("  Current score: ", Game.get_score() if Game else 0)
		print("  Current health: ", HealthSystem.get_current_health() if HealthSystem else 0)
		print("  Time elapsed: ", stats.completion_time, " seconds")
		print("  Projected rating: ", calculate_level_rating())

func get_level_metrics() -> Dictionary:
	return {
		"completion_time": completion_time,
		"damage_taken": damage_taken,
		"secrets_found": secrets_found,
		"total_secrets": total_secrets,
		"max_combo": combo_count,
		"teleporter_uses": teleporter_uses,
		"perfect_run": perfect_run,
		"rating": calculate_level_rating()
	}