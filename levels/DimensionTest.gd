extends BaseLevel
class_name DimensionTest

# Dimension Shift - Master reality manipulation

func _ready():
	level_id = "DimensionTest"
	level_name = "Dimension Shift"
	target_score = 200
	super._ready()

func setup_level():
	setup_dimension_tutorial()

func setup_dimension_tutorial():
	if ui and ui.has_method("show_hint"):
		ui.show_hint("Press F to shift between dimensions!")
		await get_tree().create_timer(3.0).timeout
		ui.show_hint("Some platforms only exist in certain dimensions")