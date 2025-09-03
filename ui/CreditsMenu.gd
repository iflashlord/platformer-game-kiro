extends CanvasLayer
class_name CreditsMenu

@onready var back_button: Button = $UI/MainContainer/BackButton

func _ready():
	_setup_ui()
	_connect_signals()

func _setup_ui():
	back_button.grab_focus()

func _connect_signals():
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	"""Return to main menu with glitch effect"""
	if Audio:
		Audio.play_sfx("ui_select")
	_trigger_glitch_transition()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")

func _trigger_glitch_transition():
	"""Trigger dimension glitch effect for menu transitions"""
	if DimensionManager and DimensionManager.has_method("trigger_menu_glitch_effect"):
		DimensionManager.trigger_menu_glitch_effect()
		print("🌀 Triggered glitch transition effect")
	else:
		print("⚠️ DimensionManager not available for glitch effect")

func _input(event):
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"):
		_on_back_pressed()