extends BaseLevel
class_name Level02

# Forest Canopy - Swing through treetops with enemies

func _ready():
	level_id = "Level02"
	level_name = "Parallel Worlds"
	target_score = 400
	Game.current_level = level_id
	super._ready()

func setup_level():
	# Forest level specific setup
	pass
