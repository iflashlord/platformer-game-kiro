extends Node

# Test clicking the Next Level button

func _ready():
	print("🧪 Testing Next Level Button Click")
	
	# Wait for autoloads to initialize
	await get_tree().process_frame
	
	# Simulate completing Level00
	print("🎮 Simulating Level00 completion...")
	
	var completion_data = {
		"level_name": "Level00",
		"score": 150,
		"completion_time": 45.5,
		"deaths": 1,
		"hearts_remaining": 4,
		"gems_found": 1,
		"total_gems": 1,
		"completed": true
	}
	
	# Save the completion
	Persistence.save_level_completion("Level00", completion_data)
	
	# Load the level results scene
	var results_scene = preload("res://ui/LevelResults.tscn")
	var results_instance = results_scene.instantiate()
	get_tree().current_scene.add_child(results_instance)
	
	# Setup the results
	results_instance.setup_results(completion_data)
	
	# Wait a moment for everything to initialize
	await get_tree().create_timer(1.0).timeout
	
	# Simulate clicking the Next Level button
	print("🖱️ Simulating Next Level button click...")
	results_instance._on_next_level_pressed()
	
	# Wait to see what happens
	await get_tree().create_timer(3.0).timeout
	
	print("✅ Test completed!")
	get_tree().quit()