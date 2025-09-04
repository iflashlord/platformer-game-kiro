extends CanvasLayer
class_name AchievementsMenu

@onready var back_button: Button = $UI/MainContainer/BackButton
@onready var progress_label: Label = $UI/MainContainer/Header/Progress

# Achievement data structure
var achievements = [
	{
		"id": "first_steps",
		"name": "First Steps",
		"description": "Complete the tutorial level",
		"icon": "🏃",
		"unlocked": false
	},
	{
		"id": "dimension_shifter", 
		"name": "Dimension Shifter",
		"description": "Use dimension flip 50 times",
		"icon": "🔄",
		"unlocked": false
	},
	{
		"id": "gem_collector",
		"name": "Gem Collector", 
		"description": "Collect 100 gems",
		"icon": "💎",
		"unlocked": false
	},
	{
		"id": "speed_runner",
		"name": "Speed Runner",
		"description": "Complete any level in under 30 seconds",
		"icon": "⚡",
		"unlocked": false
	},
	{
		"id": "perfectionist",
		"name": "Perfectionist",
		"description": "Complete a level with 100% collectibles",
		"icon": "⭐",
		"unlocked": false
	},
	{
		"id": "explorer",
		"name": "Explorer",
		"description": "Find 10 hidden gems",
		"icon": "🔍",
		"unlocked": false
	}
]

func _ready():
	_setup_ui()
	_connect_signals()
	_load_achievements()
	_update_display()

func _setup_ui():
	back_button.grab_focus()

func _connect_signals():
	back_button.pressed.connect(_on_back_pressed)

func _load_achievements():
	# Load achievement progress from save system
	if Persistence:
		for achievement in achievements:
			achievement.unlocked = Persistence.get_achievement(achievement.id)

func _update_display():
	var unlocked_count = 0
	for achievement in achievements:
		if achievement.unlocked:
			unlocked_count += 1
	
	progress_label.text = str(unlocked_count) + " / " + str(achievements.size()) + " Unlocked"
	
	# Update achievement status in UI
	_update_achievement_ui()

func _update_achievement_ui():
	# This would update the visual status of achievements in the list
	# For now, just update the first few that exist in the scene
	var achievement_nodes = [
		$UI/MainContainer/AchievementsContainer/AchievementsList/Achievement1,
		$UI/MainContainer/AchievementsContainer/AchievementsList/Achievement2,
		$UI/MainContainer/AchievementsContainer/AchievementsList/Achievement3
	]
	
	for i in range(min(achievements.size(), achievement_nodes.size())):
		var achievement = achievements[i]
		var node = achievement_nodes[i]
		
		if node:
			var status_label = node.get_node("Status")
			if achievement.unlocked:
				status_label.text = "✅"
				status_label.modulate = Color.GREEN
			else:
				status_label.text = "🔒"
				status_label.modulate = Color.GRAY

func _on_back_pressed():
	if Audio:
		Audio.play_sfx("ui_select")
	_safe_scene_change("res://ui/MainMenu.tscn")

func _safe_scene_change(scene_path: String):
	"""Standard scene loading - same as MainMenu approach"""
	print("🎬 Standard scene change to: ", scene_path)
	
	var result = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		print("❌ Scene change failed, error code: ", result)
	else:
		print("✅ Scene change successful")

func _input(event):
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"):
		_on_back_pressed()
