extends CanvasLayer
class_name HUD

@onready var checkpoint_label: Label = $UI/TopPanel/CheckpointLabel
@onready var score_label: Label = $UI/StatusPanel/ScoreLabel
@onready var deaths_label: Label = $UI/StatusPanel/DeathsLabel
@onready var level_label: Label = $UI/TopPanel/LevelLabel
@onready var fruit_icon: Sprite2D = $UI/CollectiblePanel/FruitContainer/FruitIcon
@onready var fruit_label: Label = $UI/CollectiblePanel/FruitContainer/FruitLabel
@onready var gem_icon: Sprite2D = $UI/CollectiblePanel/GemContainer/GemIcon
@onready var gem_label: Label = $UI/CollectiblePanel/GemContainer/GemLabel

func _ready():
	# Add to HUD group
	add_to_group("hud")
	
	# Connect to respawn system
	if Respawn:
		Respawn.checkpoint_set.connect(_on_checkpoint_set)
		Respawn.player_respawned.connect(_on_player_respawned)
	
	# Connect to game system
	if Game:
		Game.game_restarted.connect(_on_game_restarted)
		Game.score_changed.connect(_on_score_changed)
		Game.time_changed.connect(_on_time_changed)
		Game.fruit_collected.connect(_on_fruit_collected)
		Game.gem_collected.connect(_on_gem_collected)
	
	# Connect to dimension system
	if DimensionManager:
		DimensionManager.layer_changed.connect(_on_dimension_changed)
	
	# Initialize display
	update_checkpoint("Start")
	update_deaths(0)
	update_score(0)
	update_level(Game.current_level if Game.current_level != "" else "Level01")
	update_collectibles()

func _on_checkpoint_set(checkpoint_name: String):
	update_checkpoint(checkpoint_name)

func _on_player_respawned(position: Vector2):
	# Could add respawn animation or feedback here
	pass

func _on_game_restarted():
	update_deaths(0)
	update_score(0)
	update_checkpoint("Start")
	update_collectibles()

func _on_score_changed(new_score: int):
	update_score(new_score)

func _on_time_changed(new_time: float):
	# Update time display if we have a timer label
	var timer_label = get_node_or_null("UI/StatusPanel/TimerLabel")
	if timer_label:
		timer_label.text = "Time: %.1fs" % new_time

func _on_fruit_collected(fruit_type: int, total_count: int):
	update_collectibles()
	# Animate fruit collection
	animate_collectible_pickup(fruit_icon)

func _on_gem_collected(gem_type: int, total_count: int):
	update_collectibles()
	# Animate gem collection
	animate_collectible_pickup(gem_icon)

func animate_collectible_pickup(icon: Sprite2D):
	var tween = create_tween()
	tween.tween_property(icon, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.1)

func _on_dimension_changed(active_layer: int):
	# Visual feedback for dimension changes
	var flash_color = Color.MAGENTA if active_layer == 0 else Color.CYAN
	var tween = create_tween()
	tween.tween_property(self, "modulate", flash_color, 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)

func update_checkpoint(checkpoint_name: String):
	checkpoint_label.text = "Checkpoint: " + checkpoint_name

func update_deaths(count: int):
	deaths_label.text = "Deaths: " + str(count)

func update_score(score: int):
	score_label.text = "Score: " + str(score)

func update_level(level_name: String):
	level_label.text = "Level: " + level_name

func update_collectibles():
	# Update fruit display
	var total_fruits = Game.get_total_fruits()
	fruit_label.text = str(total_fruits)
	fruit_icon.modulate = Color.ORANGE if total_fruits > 0 else Color.GRAY
	
	# Update gem display
	var total_gems = Game.get_total_gems()
	gem_label.text = str(total_gems)
	gem_icon.modulate = Color.CYAN if total_gems > 0 else Color.GRAY
