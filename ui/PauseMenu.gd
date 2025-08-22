extends CanvasLayer
class_name PauseMenu

@onready var resume_button: Button = $UI/MenuContainer/ButtonContainer/ResumeButton
@onready var restart_button: Button = $UI/MenuContainer/ButtonContainer/RestartButton
@onready var level_select_button: Button = $UI/MenuContainer/ButtonContainer/LevelSelectButton
@onready var main_menu_button: Button = $UI/MenuContainer/ButtonContainer/MainMenuButton

signal resume_requested

var selected_button_index: int = 0
var menu_buttons: Array[Button] = []
var is_paused: bool = false

func _ready():
	# Setup button array for keyboard navigation
	menu_buttons = [resume_button, restart_button, level_select_button, main_menu_button]
	 
	# Connect button signals
	resume_button.pressed.connect(_on_resume_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	level_select_button.pressed.connect(_on_level_select_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	
	# Connect to game signals
	if Game:
		Game.game_paused.connect(_on_game_paused)
		Game.game_resumed.connect(_on_game_resumed)
	
	# Start hidden
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if not visible:
		return
	
	if event.is_action_pressed("ui_up"):
		navigate_menu(-1)
	elif event.is_action_pressed("ui_down"):
		navigate_menu(1)
	elif event.is_action_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		activate_selected_button()
	elif Input.is_action_just_pressed("pause"):
		_on_resume_button_pressed()

func navigate_menu(direction: int):
	selected_button_index = (selected_button_index + direction) % menu_buttons.size()
	if selected_button_index < 0:
		selected_button_index = menu_buttons.size() - 1
	
	update_button_focus()

func update_button_focus():
	for i in range(menu_buttons.size()):
		var button = menu_buttons[i]
		if i == selected_button_index:
			button.grab_focus()
			button.modulate = Color.YELLOW
		else:
			button.modulate = Color.WHITE

func activate_selected_button():
	if selected_button_index < menu_buttons.size():
		menu_buttons[selected_button_index].pressed.emit()

func show_pause_menu():
	visible = true
	is_paused = true
	selected_button_index = 0
	update_button_focus()
	
	# Animate entrance
	var menu_container = $UI/MenuContainer
	menu_container.scale = Vector2.ZERO
	menu_container.modulate.a = 0.0
	
	var tween = create_tween()
	tween.parallel().tween_property(menu_container, "scale", Vector2.ONE, 0.3)
	tween.parallel().tween_property(menu_container, "modulate:a", 1.0, 0.3)

func hide_pause_menu():
	visible = false
	is_paused = false

func _on_game_paused():
	show_pause_menu()

func _on_game_resumed():
	hide_pause_menu()

func _on_resume_button_pressed():
	emit_signal("resume_requested")

func _on_restart_button_pressed():
	emit_signal("resume_requested") # Unpause
	LevelLoader.restart()

func _on_level_select_button_pressed():
	emit_signal("resume_requested") # Unpause
	get_tree().change_scene_to_file("res://ui/LevelMap.tscn")

func _on_main_menu_button_pressed():
	emit_signal("resume_requested") # Unpause
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
