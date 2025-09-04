extends Node

## Simplified scene manager

var current_scene_path: String = ""
var is_transitioning: bool = false

signal scene_changed(new_scene_path: String)
signal transition_started(target_scene: String)
signal transition_completed(scene_path: String)
signal transition_failed(error_message: String)

func _ready():
	current_scene_path = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""

func change_scene(scene_path: String, show_loading: bool = true) -> bool:
	if is_transitioning:
		if ErrorHandler:
			ErrorHandler.warning("Already transitioning, ignoring request")
		return false
	
	is_transitioning = true
	transition_started.emit(scene_path)
	
	print("🎬 SceneManager loading scene: ", scene_path)
	var result = get_tree().change_scene_to_file(scene_path)
	if result == OK:
		current_scene_path = scene_path
		is_transitioning = false
		
		# Reset dimension to A when loading a new scene (especially levels)
		if scene_path.begins_with("res://levels/") and DimensionManager:
			DimensionManager.reset_to_layer_a()
		
		scene_changed.emit(scene_path)
		transition_completed.emit(scene_path)
		print("✅ Scene change successful")
		return true
	else:
		is_transitioning = false
		print("❌ Scene change failed, error code: ", result)
		if ErrorHandler:
			ErrorHandler.error("Failed to change scene: " + scene_path)
		transition_failed.emit("Failed to load scene")
		return false

func get_current_scene_path() -> String:
	return current_scene_path

func is_scene_loaded(scene_path: String) -> bool:
	return current_scene_path == scene_path

func reload_current_scene() -> bool:
	if current_scene_path == "":
		if ErrorHandler:
			ErrorHandler.error("No current scene to reload")
		return false
	
	return change_scene(current_scene_path, false)

func go_to_main_menu():
	change_scene("res://ui/MainMenu.tscn")

func go_to_level_select():
	change_scene("res://ui/LevelMapPro.tscn")

func load_level(level_path: String):
	change_scene(level_path, true)