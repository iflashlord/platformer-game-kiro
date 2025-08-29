extends Node

## Simplified performance monitor

var performance_data: Dictionary = {}

func _ready():
	set_process(true)

func _process(delta):
	# Update basic performance metrics
	performance_data = {
		"fps": {
			"current": Engine.get_frames_per_second(),
			"average": Engine.get_frames_per_second(),
			"min": Engine.get_frames_per_second(),
			"max": Engine.get_frames_per_second()
		},
		"memory": {
			"current": OS.get_static_memory_peak_usage(),
			"average": OS.get_static_memory_peak_usage(),
			"min": OS.get_static_memory_peak_usage(),
			"max": OS.get_static_memory_peak_usage()
		}
	}

func get_performance_data() -> Dictionary:
	return performance_data.duplicate()

func get_fps_stats() -> Dictionary:
	return performance_data.get("fps", {})

func get_memory_stats() -> Dictionary:
	return performance_data.get("memory", {})

func is_performance_good() -> bool:
	return performance_data.fps.current >= 30.0

func get_performance_summary() -> String:
	var fps = performance_data.fps.current
	var memory_mb = performance_data.memory.current / 1024 / 1024
	return "FPS: %.1f | Memory: %.1fMB" % [fps, memory_mb]