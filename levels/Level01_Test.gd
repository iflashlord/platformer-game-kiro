extends Node2D

func _ready():
	print("🧪 Level01 Test scene loaded successfully!")
	print("✅ Scene file is not corrupted")
	print("🎮 Press ESC to return to menu")

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		print("🏠 Returning to main menu")
		get_tree().change_scene_to_file("res://ui/MainMenu.tscn")