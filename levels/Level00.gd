extends BaseLevel
class_name Level00

# Tutorial Level - Learn basic controls and mechanics

func _ready():
	level_id = "Level00"
	level_name = "Tutorial"
	Game.current_level = level_id
	target_score = 50
	super._ready()

func setup_level():
	# Tutorial-specific setup
	show_tutorial_hints()

func show_tutorial_hints():
	# Display movement hints
	if ui and ui.has_method("show_hint"):
		ui.show_hint("Use WASD or Arrow Keys to move")
		await get_tree().create_timer(3.0).timeout
		ui.show_hint("Press SPACE to jump")
		await get_tree().create_timer(3.0).timeout
		ui.show_hint("Collect fruits for points!")
