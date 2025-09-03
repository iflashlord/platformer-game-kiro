extends BaseLevel
class_name Level01

# First Steps - Navigate platforms with dimension gates

func _ready():
	level_id = "Level01"
	level_name = "Mystic Realms"
	Game.current_level = level_id
	target_score = 300
	super._ready()

func setup_level():
	# Level01 specific setup - first real adventure level
	pass
