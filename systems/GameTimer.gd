extends Node

signal time_updated(time: float)
signal timer_started()
signal timer_stopped()
signal timer_paused()
signal timer_resumed()

var current_time: float = 0.0
var is_running: bool = false
var is_paused: bool = false
var start_time: float = 0.0

func _ready():
	# Connect to game events
	if EventBus:
		EventBus.level_started.connect(_on_level_started)
		EventBus.level_completed.connect(_on_level_completed)

func _process(delta):
	if is_running and not is_paused:
		current_time += delta
		time_updated.emit(current_time)

func start_timer():
	current_time = 0.0
	start_time = Time.get_time_dict_from_system()["second"]
	is_running = true
	is_paused = false
	timer_started.emit()
	print("Timer started")

func stop_timer():
	is_running = false
	is_paused = false
	timer_stopped.emit()
	print("Timer stopped at: ", format_time(current_time))

func pause_timer():
	if is_running and not is_paused:
		is_paused = true
		timer_paused.emit()
		print("Timer paused at: ", format_time(current_time))

func resume_timer():
	if is_running and is_paused:
		is_paused = false
		timer_resumed.emit()
		print("Timer resumed")

func reset_timer():
	current_time = 0.0
	is_running = false
	is_paused = false
	time_updated.emit(current_time)

func get_current_time() -> float:
	return current_time

func get_formatted_time() -> String:
	return format_time(current_time)

func format_time(time: float) -> String:
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

func _on_level_started(level_name: String):
	start_timer()

func _on_level_completed(level_name: String, time: float, score: int):
	stop_timer()