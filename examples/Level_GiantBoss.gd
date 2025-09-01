extends Node2D
class_name BossLevel

@onready var boss: Node = $GiantBoss
@onready var boss_ui: Control = $UI/BossHealthUI
@onready var player: CharacterBody2D = $Player
@onready var victory_ui: Control = $UI/VictoryUI

func _ready():
	# Connect boss signals
	boss.boss_defeated.connect(_on_boss_defeated)
	boss.boss_damaged.connect(_on_boss_damaged)
	boss.tnt_placed.connect(_on_tnt_placed)
	
	# Show boss UI when level starts
	boss_ui.show_boss_ui("GIANT BOSS")
	
	# Connect to EventBus for global communication
	if not EventBus.has_signal("boss_health_changed"):
		EventBus.add_user_signal("boss_health_changed", [
			{"name": "health", "type": TYPE_INT},
			{"name": "max_health", "type": TYPE_INT}
		])

func _on_boss_defeated():
	print("Boss defeated!")
	boss_ui.hide_boss_ui()
	_show_victory()
	
	# Award points
	if Game:
		Game.add_score(1000)

func _on_boss_damaged(health: int, max_health: int):
	print("Boss damaged! Health: ", health, "/", max_health)
	
	# Screen shake on damage
	if FX:
		FX.screen_shake(0.5)

func _on_tnt_placed(tnt_position: Vector2):
	print("TNT placed at: ", tnt_position)
	
	# Optional: Show warning indicator
	_show_tnt_warning(tnt_position)

func _show_victory():
	if victory_ui:
		victory_ui.visible = true
		var tween = create_tween()
		victory_ui.modulate.a = 0.0
		tween.tween_property(victory_ui, "modulate:a", 1.0, 1.0)

func _show_tnt_warning(pos: Vector2):
	# Create a temporary warning indicator
	var warning = preload("res://ui/TNTWarning.tscn").instantiate()
	add_child(warning)
	warning.global_position = pos - Vector2(20, 40)  # Position above TNT
	warning.show_warning(3.0)  # Show for 3 seconds (TNT fuse time)
