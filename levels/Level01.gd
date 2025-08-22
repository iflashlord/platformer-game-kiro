extends Node2D

@onready var player: Player = $Player
@onready var hud = $UI/GameHUD

# Level statistics
var total_fruits: int = 0
var total_gems: int = 0
var fruits_collected: int = 0
var gems_collected: int = 0
var enemies_defeated: int = 0
var level_start_time: float

# Level state
var level_completed: bool = false

func _ready():
	print("🌲 Level 1: Forest Adventure loaded")
	
	# Set current level for persistence
	Game.current_level = "Level01"
	level_start_time = Time.get_time_dict_from_system()["second"]
	
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
	
	# Connect available elements
	_connect_available_elements()
	
	print("✅ Level 1 systems initialized")
	print("🎮 Jump across platforms, use checkpoints, and reach the portal!")

func _connect_available_elements():
	print("🔗 Connecting available elements...")
	
	# Connect collectibles if they exist
	var fruits = get_tree().get_nodes_in_group("fruits")
	if fruits.size() > 0:
		total_fruits = fruits.size()
		print("🍎 Found ", fruits.size(), " fruits")
		for fruit in fruits:
			if fruit and fruit.has_signal("collected"):
				fruit.collected.connect(_on_fruit_collected)
				print("✅ Connected fruit: ", fruit.name)
	
	var gems = get_tree().get_nodes_in_group("hidden_gems")
	if gems.size() > 0:
		total_gems = gems.size()
		print("💎 Found ", gems.size(), " gems")
		for gem in gems:
			if gem and gem.has_signal("gem_collected"):
				gem.gem_collected.connect(_on_gem_collected)
				print("✅ Connected gem: ", gem.name)
	
	# Connect interactive elements if they exist
	var crates = get_tree().get_nodes_in_group("crates")
	if crates.size() > 0:
		print("📦 Found ", crates.size(), " crates")
		for crate in crates:
			if crate:
				if crate.has_signal("crate_destroyed"):
					crate.crate_destroyed.connect(_on_crate_destroyed)
				if crate.has_signal("player_bounced"):
					crate.player_bounced.connect(_on_player_bounced)
				print("✅ Connected crate: ", crate.name)
	
	# Connect enemies if they exist
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() > 0:
		print("👹 Found ", enemies.size(), " enemies")
		for enemy in enemies:
			if enemy:
				if enemy.has_signal("enemy_defeated"):
					enemy.enemy_defeated.connect(_on_enemy_defeated)
				if enemy.has_signal("player_detected"):
					enemy.player_detected.connect(_on_player_detected)
				print("✅ Connected enemy: ", enemy.name)
	
	# Connect spikes if they exist
	var spikes = get_tree().get_nodes_in_group("spikes")
	if spikes.size() > 0:
		print("🔺 Found ", spikes.size(), " spikes")
		for spike in spikes:
			if spike and spike.has_signal("player_damaged"):
				spike.player_damaged.connect(_on_spike_damage)
				print("✅ Connected spike: ", spike.name)

# COLLECTIBLE HANDLERS
func _on_fruit_collected(fruit):
	fruits_collected += 1
	var points = fruit.score_value if "score_value" in fruit else 50
	
	if Game:
		Game.add_score(points)
	
	print("🍎 Fruit collected! (", fruits_collected, "/", total_fruits, ") +", points, " points")
	
	# Check if all fruits collected
	if fruits_collected >= total_fruits:
		print("🎉 All fruits collected! Bonus: +500 points")
		if Game:
			Game.add_score(500)

func _on_gem_collected(gem):
	gems_collected += 1
	var points = 200
	
	if Game:
		Game.add_score(points)
	
	print("💎 Hidden gem found! (", gems_collected, "/", total_gems, ") +", points, " points")
	
	# Check if all gems collected
	if gems_collected >= total_gems:
		print("✨ All gems found! Bonus: +1000 points")
		if Game:
			Game.add_score(1000)

# INTERACTIVE ELEMENT HANDLERS
func _on_crate_destroyed(crate_type: String, position: Vector2):
	print("📦 Crate destroyed: ", crate_type, " at ", position)
	
	if crate_type == "tnt":
		print("💥 TNT explosion! +100 points")
		if Game:
			Game.add_score(100)
		
		# Screen shake for explosion
		if FX:
			FX.shake(100)

func _on_player_bounced(position: Vector2):
	print("🦘 Player bounced at: ", position)
	if Game:
		Game.add_score(25)

func _on_spike_damage(player: Player):
	print("🔺 Player hit spike!")

# ENEMY HANDLERS
func _on_enemy_defeated(enemy):
	enemies_defeated += 1
	var points = 150
	
	if Game:
		Game.add_score(points)
	
	print("👹 Enemy defeated! +", points, " points (Total: ", enemies_defeated, ")")

func _on_player_detected(player: Player):
	print("👁️ Player detected by enemy!")

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
	print("📊 LEVEL 1 STATISTICS:")
	print("  Fruits: ", fruits_collected, "/", total_fruits)
	print("  Gems: ", gems_collected, "/", total_gems)
	print("  Enemies defeated: ", enemies_defeated)
	print("  Current score: ", Game.get_score() if Game else 0)
	print("  Current health: ", HealthSystem.get_current_health() if HealthSystem else 0)
	print("  Time elapsed: ", GameTimer.get_current_time() if GameTimer else 0)

func get_completion_percentage() -> float:
	if total_fruits + total_gems == 0:
		return 100.0
	var total_objectives = total_fruits + total_gems
	var completed_objectives = fruits_collected + gems_collected
	return (float(completed_objectives) / float(total_objectives)) * 100.0

func is_perfect_completion() -> bool:
	return fruits_collected >= total_fruits and gems_collected >= total_gems and HealthSystem.get_current_health() >= 5
