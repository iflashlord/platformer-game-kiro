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
	if Audio:
		Audio.play_sfx("ui_select")
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")

func _input(event):
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"):
		_on_back_pressed()