extends CanvasLayer

@onready var play_button: Button = $UI/MenuContainer/ButtonContainer/PlayButton
@onready var level_select_button: Button = $UI/MenuContainer/ButtonContainer/LevelSelectButton
@onready var options_button: Button = $UI/MenuContainer/ButtonContainer/OptionsButton
@onready var quit_button: Button = $UI/MenuContainer/ButtonContainer/QuitButton

func _ready():
	print("🏠 MainMenu _ready() called")
	
	# Check if buttons exist
	print("🔍 Button references:")
	print("  Play button: ", play_button != null)
	print("  Level select button: ", level_select_button != null)
	print("  Options button: ", options_button != null)
	print("  Quit button: ", quit_button != null)
	
	# Connect button signals with test
	if play_button:
		# Add a simple test connection first
		play_button.pressed.connect(func(): print("🔥 BUTTON CLICK DETECTED!"))
		play_button.pressed.connect(_on_play_pressed)
		print("✅ Play button connected with test")
		
		# Test button properties
		print("🔍 Play button properties:")
		print("  Disabled: ", play_button.disabled)
		print("  Visible: ", play_button.visible)
		print("  Modulate: ", play_button.modulate)
		print("  Text: ", play_button.text)
	else:
		print("❌ Play button is null!")
		
	if level_select_button:
		level_select_button.pressed.connect(_on_level_select_pressed)
		print("✅ Level select button connected")
	else:
		print("❌ Level select button is null!")
		
	if options_button:
		options_button.pressed.connect(_on_options_pressed)
		print("✅ Options button connected")
	else:
		print("❌ Options button is null!")
		
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
		print("✅ Quit button connected")
	else:
		print("❌ Quit button is null!")
	
	# Focus first button
	play_button.grab_focus()
	
	# Start menu music
	Audio.play_music("menu_theme")
	
	# Hide quit button on web
	if OS.get_name() == "Web":
		quit_button.visible = false

func _on_play_pressed():
	print("🎮 PLAY BUTTON CLICKED! Function called successfully!")
	print("🔍 Current scene: ", get_tree().current_scene.scene_file_path)
	print("🔍 Scene tree ready: ", get_tree() != null)
	
	# Load Tutorial as the first level
	var scene_path = "res://levels/Tutorial.tscn"
	
	print("📁 Loading Tutorial: ", scene_path)
	
	if FileAccess.file_exists(scene_path):
		print("✅ Tutorial file exists")
		
		# Try to change scene
		print("🔄 Starting Tutorial...")
		var result = get_tree().change_scene_to_file(scene_path)
		print("📊 Scene change result: ", result)
		
		if result == OK:
			print("✅ Successfully started Tutorial!")
		else:
			print("❌ Failed to start Tutorial. Error: ", result)
	else:
		print("❌ Tutorial file not found: ", scene_path)

func _on_level_select_pressed():
	print("🗺️ Level select button pressed - loading Level Map")
	
	# Check if level map exists
	var scene_path = "res://ui/LevelMap.tscn"
	if not FileAccess.file_exists(scene_path):
		print("❌ Level Map scene not found: ", scene_path)
		return
	
	# Go to level map screen
	var result = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		print("❌ Failed to load Level Map: ", result)
	else:
		print("✅ Loading Level Map scene")

func _on_options_pressed():
	# Go to settings/options screen
	get_tree().change_scene_to_file("res://ui/SettingsMenuStandalone.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		if OS.get_name() != "Web":
			get_tree().quit()
	elif Input.is_action_just_pressed("ui_accept"):
		_on_play_pressed()
