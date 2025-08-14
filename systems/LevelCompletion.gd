extends Node

signal level_completed(level_name: String, completion_data: Dictionary)

func complete_level(level_name: String, completion_time: float, hearts_remaining: int, gems_found: int, total_gems: int):
	# Create completion data
	var completion_data = {
		"level_name": level_name,
		"completion_time": completion_time,
		"hearts_remaining": hearts_remaining,
		"gems_found": gems_found,
		"total_gems": total_gems,
		"score": _calculate_final_score(level_name, completion_time, hearts_remaining, gems_found, total_gems),
		"completed": true,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# Save completion data
	Persistence.save_level_completion(level_name, completion_data)
	
	# Trigger explosion effect
	_trigger_completion_explosion()
	
	# Wait for explosion, then show results
	await get_tree().create_timer(1.5).timeout
	
	# Show completion screen
	_show_completion_results(completion_data)
	
	# Emit completion signal
	level_completed.emit(level_name, completion_data)

func _trigger_completion_explosion():
	# Get player position for explosion
	var player = get_tree().get_first_node_in_group("player")
	var explosion_pos = player.global_position if player else Vector2(640, 360)
	
	# Create celebration explosion
	var explosion = ObjectPool.get_explosion()
	if explosion:
		explosion.global_position = explosion_pos
		explosion.setup(150.0, 0.0)  # Large, non-damaging explosion
		get_tree().current_scene.add_child(explosion)
	
	# Additional visual effects
	FX.flash_screen(Color.GOLD * 0.3, 0.5)
	FX.shake(200)
	Audio.play_sfx("level_complete")
	
	# Particle burst
	EventBus.particle_burst_requested.emit("celebration", explosion_pos, 50)
	
	print("🎉 Level completed with celebration explosion!")

func _calculate_final_score(level_name: String, time: float, hearts: int, gems: int, total_gems: int) -> int:
	var base_scores = {
		"Level01": 1000,
		"Level02": 1500, 
		"Level03": 2000
	}
	
	var base_score = base_scores.get(level_name, 1000)
	var time_bonus = max(0, 300 - int(time)) * 10
	var heart_bonus = hearts * 100
	var gem_bonus = gems * 200
	var perfect_bonus = 500 if gems == total_gems else 0
	
	return base_score + time_bonus + heart_bonus + gem_bonus + perfect_bonus

func _show_completion_results(completion_data: Dictionary):
	# Load the results screen
	var results_scene = preload("res://ui/LevelResults.tscn")
	var results = results_scene.instantiate()
	
	# Pass completion data to results screen
	results.setup_results(completion_data)
	
	# Add to scene tree
	get_tree().current_scene.add_child(results)
