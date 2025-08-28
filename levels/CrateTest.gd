extends BaseLevel
class_name CrateTest

# Crate Chaos - Master different crate types and destruction mechanics

func _ready():
	level_id = "CrateTest"
	level_name = "Crate Chaos"
	target_score = 100
	super._ready()

func setup_level():
	# Crate test specific setup
	setup_crate_tutorial()

func setup_crate_tutorial():
	if ui and ui.has_method("show_hint"):
		ui.show_hint("Jump on crates to break them!")
		await get_tree().create_timer(2.0).timeout
		ui.show_hint("Different crates have different effects")
