extends CanvasLayer

# Button references - will be found dynamically in _ready()
var playertest_button: Button
var tutorial_button: Button
var level01_button: Button
var back_button: Button
var reset_button: Button

func _ready():
	print("🗺️ LevelMap _ready() called")
	
	# Find all button references dynamically
	print("🔍 Finding UI elements...")
	
	playertest_button = get_node_or_null("ScrollContainer/MapContainer/PlayerTestContainer/PlayerTestButton")
	var portaltest_button = get_node_or_null("ScrollContainer/MapContainer/PortalTestContainer/PortalTestButton")
	tutorial_button = get_node_or_null("ScrollContainer/MapContainer/TutorialContainer/TutorialButton")
	level01_button = get_node_or_null("ScrollContainer/MapContainer/Level01Container/Level01Button")
	back_button = get_node_or_null("ScrollContainer/MapContainer/ButtonContainer/BackButton")
	reset_button = get_node_or_null("ScrollContainer/MapContainer/ButtonContainer/ResetButton")
	
	# Debug: Check if all buttons are found
	print("🔍 Button references found:")
	print("  PlayerTest button: ", playertest_button != null)
	print("  PortalTest button: ", portaltest_button != null)
	print("  Tutorial button: ", tutorial_button != null)
	print("  Level01 button: ", level01_button != null)
	print("  Back button: ", back_button != null)
	print("  Reset button: ", reset_button != null)
	
	# Connect buttons with debug output (only if they exist)
	if playertest_button:
		playertest_button.pressed.connect(func(): 
			print("🧪 PlayerTest button pressed")
			_load_level("PlayerTest")
		)
	if portaltest_button:
		portaltest_button.pressed.connect(func(): 
			print("🌀 PortalTest button pressed")
			_load_level("PortalTest")
		)
	if tutorial_button:
		tutorial_button.pressed.connect(func(): 
			print("🎓 Tutorial button pressed")
			_load_level("Tutorial")
		)
	if level01_button:
		level01_button.pressed.connect(func(): 
			print("🌲 Level01 button pressed")
			_load_level("Level01")
		)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	
	print("✅ LevelMap initialized")

func _load_level(level_name: String):
	print("🎯 Loading level: ", level_name)
	
	var scene_path = ""
	match level_name:
		"PlayerTest":
			scene_path = "res://levels/PlayerTest.tscn"
		"Tutorial":
			scene_path = "res://levels/Tutorial.tscn"
		"Level01":
			scene_path = "res://levels/Level01.tscn"
		"PortalTest":
			scene_path = "res://levels/PortalTest.tscn"
		_:
			print("❌ Unknown level: ", level_name)
			return
	
	print("📁 Loading scene: ", scene_path)
	
	# Check if file exists
	if not FileAccess.file_exists(scene_path):
		print("❌ Scene file not found: ", scene_path)
		return
	
	# Load the scene
	var result = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		print("❌ Failed to load scene: ", scene_path, " Error: ", result)
	else:
		print("✅ Successfully loading: ", scene_path)

func _on_back_pressed():
	print("🏠 Going back to main menu")
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")

func _on_reset_pressed():
	print("🔄 Resetting progress")
	# Reset health and respawn systems
	if HealthSystem:
		HealthSystem.reset_health()
	if Respawn:
		Respawn.reset_checkpoints()
	print("✅ Progress reset")
