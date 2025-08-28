extends BaseLevel
class_name Level03

# Crystal Caves - Navigate dangerous caves with spikes and enemies

func _ready():
	level_id = "Level03"
	level_name = "Crystal Caves"
	target_score = 500
	super._ready()

func setup_level():
	# Cave level specific setup
	pass