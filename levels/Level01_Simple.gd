#extends Node2D
#
#@onready var player: Player = $Player
#@onready var hud = $UI/GameHUD
#
#func _ready():
	#print("🌲 Level 1: Simple Version loaded")
	#
	## Set current level for persistence
	#Game.current_level = "Level01"
	#
	## Initialize systems
	#HealthSystem.reset_health()
	#Respawn.reset_checkpoints()
	#
	## Start game timer
	#if GameTimer:
		#GameTimer.start_timer()
		#print("⏱️ Game timer started")
	#
	## Reset score
	#if Game:
		#Game.score = 0
		#print("🎯 Score reset to 0")
	#
	## Set initial spawn position
	#if player:
		#Respawn.default_spawn_position = player.global_position
		#print("🏁 Level 1 spawn position set: ", player.global_position)
	#
	## Connect player signals
	#if player:
		#player.died.connect(_on_player_died)
	#
	## Connect health system to HUD
	#if HealthSystem and hud:
		## Disconnect any existing connections
		#if HealthSystem.health_changed.is_connected(hud.update_health):
			#HealthSystem.health_changed.disconnect(hud.update_health)
		#
		#HealthSystem.health_changed.connect(hud.update_health)
		#HealthSystem.player_died.connect(_on_game_over)
		#hud.update_health(HealthSystem.get_current_health(), HealthSystem.get_max_health())
		#print("💖 HUD connected to HealthSystem - Current health: ", HealthSystem.get_current_health())
	#
	#print("✅ Level 1 Simple systems initialized")
	#print("🎮 Jump to the platform, avoid death zones, reach the portal!")
#
#func _on_player_died():
	#print("💀 Player died in Level 1")
#
#func _on_game_over():
	#print("💀 Game Over in Level 1 - restarting level")
	#await get_tree().create_timer(1.0).timeout
	#get_tree().reload_current_scene()
#
#func _input(event):
	## ESC to return to menu
	#if Input.is_action_just_pressed("ui_cancel"):
		#print("🏠 Returning to main menu from Level 1")
		#get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
	#
	## R to restart level
	#if Input.is_action_just_pressed("restart"):
		#print("🔄 Restarting Level 1")
		#get_tree().reload_current_scene()
	#
	## Debug: Show level stats
	#if Input.is_action_just_pressed("ui_select"):
		#print("📊 LEVEL 1 SIMPLE STATISTICS:")
		#print("  Current score: ", Game.get_score() if Game else 0)
		#print("  Current health: ", HealthSystem.get_current_health() if HealthSystem else 0)
		#print("  Time elapsed: ", GameTimer.get_current_time() if GameTimer else 0)
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
	print("🎮 LEVEL ELEMENTS:")
	print("  📦 Crates: ", get_tree().get_nodes_in_group("crates").size())
	print("  🍎 Fruits: ", total_fruits)
	print("  💎 Gems: ", total_gems)
	print("  👹 Enemies: ", get_tree().get_nodes_in_group("enemies").size())
	print("  🔺 Spikes: ", get_tree().get_nodes_in_group("spikes").size())
	print("🎮 Jump across platforms, collect items, avoid hazards, and reach the portal!")

func _connect_available_elements():
	print("🔗 Connecting available elements...")
	
	# Connect collectibles manually since we're using simple Area2D nodes
	var collectibles_node = $Collectibles
	if collectibles_node:
		var fruits = []
		var gems = []
		
		for child in collectibles_node.get_children():
			if child.name.begins_with("Fruit"):
				fruits.append(child)
				child.body_entered.connect(_on_fruit_collected.bind(child))
				child.add_to_group("collectibles")
			elif child.name.begins_with("HiddenGem"):
				gems.append(child)
				child.body_entered.connect(_on_gem_collected.bind(child))
				child.add_to_group("gems")
		
		total_fruits = fruits.size()
		total_gems = gems.size()
		print("🍎 Found ", total_fruits, " fruits")
		print("💎 Found ", total_gems, " gems")
	
	# Connect interactive elements
	var interactive_node = $InteractiveElements
	if interactive_node:
		var crates = []
		for child in interactive_node.get_children():
			if child.name.contains("Crate"):
				crates.append(child)
				child.add_to_group("crates")
				if child.has_signal("crate_destroyed"):
					child.crate_destroyed.connect(_on_crate_destroyed)
		print("📦 Found ", crates.size(), " crates")
	
	# Connect hazards
	var hazards_node = $Hazards
	if hazards_node:
		var spikes = []
		for child in hazards_node.get_children():
			if child.name.begins_with("Spike"):
				spikes.append(child)
				child.add_to_group("spikes")
				if child.has_signal("player_damaged"):
					child.player_damaged.connect(_on_spike_damage)
		print("🔺 Found ", spikes.size(), " spikes")
	
	# Connect enemies
	var enemies_node = $Enemies
	if enemies_node:
		var enemies = []
		for child in enemies_node.get_children():
			if child.name.begins_with("Enemy"):
				enemies.append(child)
				child.add_to_group("enemies")
				if child.has_signal("enemy_defeated"):
					child.enemy_defeated.connect(_on_enemy_defeated)
				if child.has_signal("player_detected"):
					child.player_detected.connect(_on_player_detected)
		print("👹 Found ", enemies.size(), " enemies")

# COLLECTIBLE HANDLERS
func _on_fruit_collected(fruit_node: Area2D, body: Node2D):
	if not body.is_in_group("player"):
		return
	
	fruits_collected += 1
	var points = 50
	
	if Game:
		Game.add_score(points)
	
	print("🍎 Fruit collected! (", fruits_collected, "/", total_fruits, ") +", points, " points")
	
	# Visual feedback
	fruit_node.modulate.a = 0.3
	fruit_node.collision_layer = 0  # Disable collision
	
	# Check if all fruits collected
	if fruits_collected >= total_fruits:
		print("🎉 All fruits collected! Bonus: +500 points")
		if Game:
			Game.add_score(500)

func _on_gem_collected(gem_node: Area2D, body: Node2D):
	if not body.is_in_group("player"):
		return
	
	gems_collected += 1
	var points = 200
	
	if Game:
		Game.add_score(points)
	
	print("💎 Hidden gem found! (", gems_collected, "/", total_gems, ") +", points, " points")
	
	# Visual feedback
	gem_node.modulate.a = 0.3
	gem_node.collision_layer = 0  # Disable collision
	
	# Check if all gems collected
	if gems_collected >= total_gems:
		print("✨ All gems found! Bonus: +1000 points")
		if Game:
			Game.add_score(1000)

# INTERACTIVE ELEMENT HANDLERS
func _on_crate_destroyed(crate_type: String):
	print("📦 Crate destroyed: ", crate_type)
	
	var points = 50
	if crate_type == "tnt":
		points = 100
		print("💥 TNT explosion! +", points, " points")
		# Screen shake for explosion
		if FX:
			FX.shake(300)
	elif crate_type == "bounce":
		points = 75
		print("🦘 Bounce crate destroyed! +", points, " points")
	else:
		print("📦 Basic crate destroyed! +", points, " points")
	
	if Game:
		Game.add_score(points)

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
