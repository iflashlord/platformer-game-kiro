extends BaseLevel
class_name CollectibleTest

# Treasure Hunt - Collect all fruits and gems

func _ready():
	level_id = "CollectibleTest"
	level_name = "Treasure Hunt"
	target_score = 150
	super._ready()

func setup_level():
	setup_collectible_tutorial()

func setup_collectible_tutorial():
	if ui and ui.has_method("show_hint"):
		ui.show_hint("Collect all fruits and find hidden gems!")
		await get_tree().create_timer(2.0).timeout
		ui.show_hint("Gems are worth more points than fruits")