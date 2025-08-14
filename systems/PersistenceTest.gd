extends Node

# Test script for Persistence system
func _ready():
	print("=== Persistence System Test ===")
	
	# Connect to signals
	Persistence.profile_loaded.connect(_on_profile_loaded)
	Persistence.profile_saved.connect(_on_profile_saved)
	Persistence.save_failed.connect(_on_save_failed)
	
	# Test basic functionality
	test_basic_operations()
	
	# Test level data
	test_level_data()
	
	# Test statistics
	test_statistics()
	
	# Test settings
	test_settings()
	
	print("=== Test Complete ===")

func test_basic_operations():
	print("\n--- Testing Basic Operations ---")
	
	# Test profile creation
	var profile = Persistence.get_default_profile()
	profile.profile_name = "TestPlayer"
	
	# Test save/load
	var save_success = Persistence.save_profile(profile)
	print("Save success: ", save_success)
	
	var loaded_profile = Persistence.load_profile()
	print("Loaded profile name: ", loaded_profile.get("profile_name", "None"))

func test_level_data():
	print("\n--- Testing Level Data ---")
	
	# Test setting best time
	Persistence.set_best_time("TestLevel", 45000) # 45 seconds in ms
	print("Set best time: 45000ms")
	
	var best_time = Persistence.get_best_time_ms("TestLevel")
	print("Retrieved best time: ", best_time, "ms")
	
	# Test setting best score
	Persistence.set_best_score("TestLevel", 1500)
	print("Set best score: 1500")
	
	var best_score = Persistence.get_best_score("TestLevel")
	print("Retrieved best score: ", best_score)
	
	# Test level completion
	Persistence.mark_level_completed("TestLevel", false)
	print("Marked level as completed")
	
	var is_completed = Persistence.is_level_completed("TestLevel")
	print("Level completed: ", is_completed)

func test_statistics():
	print("\n--- Testing Statistics ---")
	
	# Test incrementing stats
	Persistence.update_statistics("total_jumps", 10)
	Persistence.update_statistics("total_collectibles", 5)
	
	var profile = Persistence.current_profile
	print("Total jumps: ", profile.statistics.get("total_jumps", 0))
	print("Total collectibles: ", profile.statistics.get("total_collectibles", 0))
	
	# Test playtime
	Persistence.add_playtime(120.5) # 2 minutes
	print("Added playtime: 120.5 seconds")
	print("Total playtime: ", profile.get("total_playtime", 0.0))

func test_settings():
	print("\n--- Testing Settings ---")
	
	# Test setting updates
	Persistence.update_setting("master_volume", 0.8)
	Persistence.update_setting("fullscreen", true)
	
	var settings = Persistence.current_profile.settings
	print("Master volume: ", settings.get("master_volume", 1.0))
	print("Fullscreen: ", settings.get("fullscreen", false))

func _on_profile_loaded(profile_name: String):
	print("Profile loaded signal: ", profile_name)

func _on_profile_saved(profile_name: String):
	print("Profile saved signal: ", profile_name)

func _on_save_failed(error_message: String):
	print("Save failed signal: ", error_message)