extends Node
class_name LevelManager

signal level_completed(level_name: String, completion_data: Dictionary)
signal collectible_gathered(type: String, points: int)
signal enemy_defeated(enemy_type: String, points: int)
signal player_damaged(damage_source: String, damage: int)

var level_name: String = ""
var level_stats: Dictionary = {
	"fruits_collected": 0,
	"gems_collected": 0,
	"enemies_defeated": 0,
	"crates_destroyed": 0,
	"total_fruits": 0,
	"total_gems": 0,
	"total_enemies": 0,
	"total_crates": 0,
	"damage_taken": 0,
	"completion_time": 0.0
}

var start_time: float

func _ready():
	start_time = Time.get_time_dict_from_system()["second"]

func initialize_level(name: String):
	level_name = name
	start_time = Time.get_time_dict_from_system()["second"]
	
	# Add to group for easy finding
	add_to_group("level_managers")
	
	# Debug: Track LevelManager instances
	var existing_managers = get_tree().get_nodes_in_group("level_managers")
	print("🚨 LevelManager initialized! Total managers: ", existing_managers.size())
	print("🚨 This manager for level: ", level_name)
	
	# Reset stats
	for key in level_stats.keys():
		level_stats[key] = 0
	
	# Auto-connect to all reusable components
	auto_connect_components()
	
	print("🎮 Level Manager initialized for: ", level_name)

func auto_connect_components():
	print("🔗 Auto-connecting reusable components...")
	
	# Connect to all CollectibleFruit instances
	var fruits = get_tree().get_nodes_in_group("fruits")
	level_stats.total_fruits = fruits.size()
	for fruit in fruits:
		if fruit.has_signal("fruit_collected"):
			fruit.fruit_collected.connect(_on_fruit_collected)
	print("🍎 Connected to ", fruits.size(), " fruits")
	
	# Connect to all CollectibleGem instances
	var gems = get_tree().get_nodes_in_group("gems")
	level_stats.total_gems = gems.size()
	for gem in gems:
		if gem.has_signal("gem_collected"):
			gem.gem_collected.connect(_on_gem_collected)
	print("💎 Connected to ", gems.size(), " gems")
	
	# Connect to all InteractiveCrate instances
	var crates = get_tree().get_nodes_in_group("crates")
	level_stats.total_crates = crates.size()
	for crate in crates:
		if crate.has_signal("crate_destroyed"):
			crate.crate_destroyed.connect(_on_crate_destroyed)
		if crate.has_signal("player_bounced"):
			crate.player_bounced.connect(_on_player_bounced)
	print("📦 Connected to ", crates.size(), " crates")
	
	# Connect to all PatrolEnemy instances
	var enemies = get_tree().get_nodes_in_group("enemies")
	level_stats.total_enemies = enemies.size()
	for enemy in enemies:
		if enemy.has_signal("enemy_defeated"):
			enemy.enemy_defeated.connect(_on_enemy_defeated)
		if enemy.has_signal("player_damaged"):
			enemy.player_damaged.connect(_on_player_damaged_by_enemy)
	print("👹 Connected to ", enemies.size(), " enemies")
	
	# Connect to all DangerousSpike instances
	var spikes = get_tree().get_nodes_in_group("spikes")
	for spike in spikes:
		if spike.has_signal("player_damaged"):
			spike.player_damaged.connect(_on_player_damaged_by_spike)
	print("🔺 Connected to ", spikes.size(), " spikes")
	
	# Connect to all JumpPad instances
	var jump_pads = get_tree().get_nodes_in_group("jump_pads")
	for pad in jump_pads:
		if pad.has_signal("player_bounced"):
			pad.player_bounced.connect(_on_jump_pad_used)
	print("🦘 Connected to ", jump_pads.size(), " jump pads")
	
	# Connect to all DeathZone instances
	var death_zones = get_tree().get_nodes_in_group("death_zones")
	for zone in death_zones:
		if zone.has_signal("player_killed"):
			zone.player_killed.connect(_on_player_killed_by_death_zone)
	print("💀 Connected to ", death_zones.size(), " death zones")
	
	# Connect to all BounceCrate instances (fruit boxes)
	var fruit_boxes = get_tree().get_nodes_in_group("fruit_boxes")
	for box in fruit_boxes:
		if box.has_signal("fruit_collected"):
			box.fruit_collected.connect(_on_fruit_box_collected)
		if box.has_signal("box_depleted"):
			box.box_depleted.connect(_on_fruit_box_depleted)
	print("🍊 Connected to ", fruit_boxes.size(), " fruit boxes")

# Event handlers for reusable components
func _on_fruit_collected(fruit: CollectibleFruit, points: int):
	level_stats.fruits_collected += 1
	collectible_gathered.emit("fruit", points)
	
	print("🍎 Fruit collected! (", level_stats.fruits_collected, "/", level_stats.total_fruits, ")")
	
	# Check for completion bonus
	if level_stats.fruits_collected >= level_stats.total_fruits:
		print("🎉 All fruits collected! Bonus: +500 points")
		Game.add_score(500)

func _on_gem_collected(gem: CollectibleGem, points: int):
	level_stats.gems_collected += 1
	collectible_gathered.emit("gem", points)
	
	print("💎 Gem collected! (", level_stats.gems_collected, "/", level_stats.total_gems, ")")
	
	# Check for completion bonus
	if level_stats.gems_collected >= level_stats.total_gems:
		print("✨ All gems found! Bonus: +1000 points")
		Game.add_score(1000)

func _on_crate_destroyed(crate: InteractiveCrate, points: int):
	level_stats.crates_destroyed += 1
	print("📦 Crate destroyed! (", level_stats.crates_destroyed, "/", level_stats.total_crates, ")")

func _on_player_bounced(crate: InteractiveCrate, player: Node2D):
	print("🦘 Player bounced by crate!")

func _on_enemy_defeated(enemy: PatrolEnemy, points: int):
	level_stats.enemies_defeated += 1
	enemy_defeated.emit(enemy.enemy_type, points)
	
	print("👹 Enemy defeated! (", level_stats.enemies_defeated, "/", level_stats.total_enemies, ")")

func _on_player_damaged_by_enemy(enemy: PatrolEnemy, player: Node2D, damage: int):
	level_stats.damage_taken += damage
	player_damaged.emit("enemy", damage)
	
	print("💔 Player damaged by enemy! Total damage: ", level_stats.damage_taken)

func _on_player_damaged_by_spike(spike: DangerousSpike, player: Node2D, damage: int):
	level_stats.damage_taken += damage
	player_damaged.emit("spike", damage)
	
	print("💔 Player damaged by spike! Total damage: ", level_stats.damage_taken)

func _on_jump_pad_used(jump_pad: JumpPad, player: Node2D, force: float):
	print("🦘 Jump pad used! Force: ", force)

func _on_player_killed_by_death_zone(death_zone: DeathZone, player: Node2D):
	level_stats.damage_taken += 999  # Mark as death
	player_damaged.emit("death_zone", 999)
	
	print("💀 Player killed by death zone: ", death_zone.zone_type)

func _on_fruit_box_collected(position: Vector2, fruits_remaining: int, points: int):
	level_stats.fruits_collected += 1
	collectible_gathered.emit("fruit_box", points)
	
	print("🍊 Fruit collected from box! Points: ", points, " Remaining: ", fruits_remaining)

func _on_fruit_box_depleted(position: Vector2):
	print("🍊 Fruit box depleted at position: ", position)

# Utility functions
func get_completion_percentage() -> float:
	var total_objectives = level_stats.total_fruits + level_stats.total_gems
	if total_objectives == 0:
		return 100.0
	
	var completed_objectives = level_stats.fruits_collected + level_stats.gems_collected
	return (float(completed_objectives) / float(total_objectives)) * 100.0

func is_perfect_completion() -> bool:
	return (level_stats.fruits_collected >= level_stats.total_fruits and 
			level_stats.gems_collected >= level_stats.total_gems and 
			level_stats.damage_taken == 0)

func get_level_stats() -> Dictionary:
	level_stats.completion_time = Time.get_time_dict_from_system()["second"] - start_time
	return level_stats.duplicate()

func complete_level():
	print("🚨 LevelManager: complete_level() called!")
	print("🚨 Level name: ", level_name)
	
	var completion_data = get_level_stats()
	completion_data["completion_percentage"] = get_completion_percentage()
	completion_data["perfect_completion"] = is_perfect_completion()
	
	print("🚨 About to emit level_completed signal")
	level_completed.emit(level_name, completion_data)
	print("🚨 level_completed signal emitted")
	
	print("🏆 Level completed: ", level_name)
	print("📊 Final stats: ", completion_data)

# This should be called by the level portal, not automatically
func trigger_level_completion():
	print("🚨 LevelManager: trigger_level_completion() called!")
	print("🚨 Level name: ", level_name)
	complete_level()
