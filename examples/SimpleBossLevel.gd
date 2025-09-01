extends Node2D
class_name SimpleBossLevel

@onready var boss: Node = get_node_or_null("GiantBoss")
@onready var player: CharacterBody2D = get_node_or_null("Player")

func _ready():
	# Connect boss signals if boss exists
	if boss and boss.has_signal("boss_defeated"):
		boss.boss_defeated.connect(_on_boss_defeated)
	if boss and boss.has_signal("boss_damaged"):
		boss.boss_damaged.connect(_on_boss_damaged)
	if boss and boss.has_signal("tnt_placed"):
		boss.tnt_placed.connect(_on_tnt_placed)

func _on_boss_defeated():
	print("🎉 BOSS DEFEATED! 🎉")
	# Simple victory message
	var victory_label = Label.new()
	victory_label.text = "VICTORY!"
	victory_label.position = Vector2(640, 200)
	victory_label.add_theme_font_size_override("font_size", 64)
	victory_label.add_theme_color_override("font_color", Color.GOLD)
	add_child(victory_label)
	
	# Optional: Add score
	if Game:
		Game.add_score(1000)

func _on_boss_damaged(health: int, max_health: int):
	print("Boss health: %d/%d" % [health, max_health])

func _on_tnt_placed(tnt_position: Vector2):
	print("TNT placed at: ", tnt_position)
