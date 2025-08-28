extends BaseLevel
class_name EnemyGauntlet

# Enemy Gauntlet - Survive waves of enemies and hazards

func _ready():
	level_id = "EnemyGauntlet"
	level_name = "Enemy Gauntlet"
	target_score = 250
	super._ready()

func setup_level():
	setup_combat_tutorial()

func setup_combat_tutorial():
	if ui and ui.has_method("show_hint"):
		ui.show_hint("Jump on enemies to defeat them!")
		await get_tree().create_timer(2.0).timeout
		ui.show_hint("Avoid spikes and hazards!")