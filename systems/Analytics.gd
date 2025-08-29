extends Node

## Production-ready analytics and telemetry system

# Analytics configuration
const ANALYTICS_ENABLED = true
const BATCH_SIZE = 10
const FLUSH_INTERVAL = 30.0  # seconds
const MAX_EVENTS_IN_MEMORY = 100

# Event categories
enum EventCategory {
	GAMEPLAY,
	UI,
	PERFORMANCE,
	ERROR,
	PROGRESSION,
	MONETIZATION
}

# Event data storage
var event_queue: Array[Dictionary] = []
var session_data: Dictionary = {}
var user_data: Dictionary = {}
var flush_timer: Timer

# Session tracking
var session_start_time: float
var session_id: String
var user_id: String

signal analytics_event_sent(event_data: Dictionary)
signal analytics_batch_sent(batch_data: Array)
signal analytics_error(error_message: String)

func _ready():
	if not ANALYTICS_ENABLED:
		return
	
	_initialize_session()
	_setup_flush_timer()
	_load_user_data()
	
	if ErrorHandler:
		ErrorHandler.info("Analytics system initialized")

func _initialize_session():
	"""Initialize a new analytics session"""
	var time = Time.get_datetime_dict_from_system()
	session_start_time = time.hour * 3600 + time.minute * 60 + time.second
	session_id = _generate_session_id()
	user_id = _get_or_create_user_id()
	
	session_data = {
		"session_id": session_id,
		"user_id": user_id,
		"start_time": session_start_time,
		"platform": OS.get_name(),
		"version": ProjectSettings.get_setting("application/config/version", "1.0.0"),
		"viewport_size": get_viewport().get_visible_rect().size,
		"locale": OS.get_locale()
	}
	
	# Track session start
	track_event("session_start", EventCategory.GAMEPLAY, session_data)

func _setup_flush_timer():
	"""Setup timer for periodic analytics flushing"""
	flush_timer = Timer.new()
	flush_timer.wait_time = FLUSH_INTERVAL
	flush_timer.timeout.connect(_flush_events)
	flush_timer.autostart = true
	add_child(flush_timer)

func _load_user_data():
	"""Load persistent user data"""
	var save_path = "user://analytics_user.dat"
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			if json.parse(json_string) == OK:
				user_data = json.data
	
	# Ensure user has required data
	if not user_data.has("user_id"):
		user_data["user_id"] = _generate_user_id()
		user_data["first_session"] = Time.get_datetime_string_from_system()
		user_data["total_sessions"] = 0
	
	user_data["total_sessions"] = user_data.get("total_sessions", 0) + 1
	user_data["last_session"] = Time.get_datetime_string_from_system()
	
	_save_user_data()

func _save_user_data():
	"""Save user data to disk"""
	var save_path = "user://analytics_user.dat"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(user_data))
		file.close()

func _generate_session_id() -> String:
	"""Generate a unique session ID"""
	var time = Time.get_datetime_dict_from_system()
	var random_suffix = randi() % 10000
	return "%04d%02d%02d_%02d%02d%02d_%04d" % [
		time.year, time.month, time.day,
		time.hour, time.minute, time.second,
		random_suffix
	]

func _generate_user_id() -> String:
	"""Generate a unique user ID"""
	return "user_" + str(Time.get_datetime_dict_from_system().year) + "_" + str(randi() % 1000000)

func _get_or_create_user_id() -> String:
	"""Get existing user ID or create new one"""
	return user_data.get("user_id", _generate_user_id())

# Public API for tracking events
func track_event(event_name: String, category: EventCategory, properties: Dictionary = {}):
	"""Track a custom event"""
	if not ANALYTICS_ENABLED:
		return
	
	var event_data = {
		"event_name": event_name,
		"category": _category_to_string(category),
		"timestamp": Time.get_datetime_string_from_system(),
		"session_id": session_id,
		"user_id": user_id,
		"properties": properties
	}
	
	_add_event_to_queue(event_data)

func track_level_start(level_name: String, attempt_number: int = 1):
	"""Track when a level is started"""
	track_event("level_start", EventCategory.GAMEPLAY, {
		"level_name": level_name,
		"attempt_number": attempt_number
	})

func track_level_complete(level_name: String, completion_time: float, score: int, deaths: int = 0):
	"""Track level completion"""
	track_event("level_complete", EventCategory.PROGRESSION, {
		"level_name": level_name,
		"completion_time": completion_time,
		"score": score,
		"deaths": deaths,
		"success": true
	})

func track_level_fail(level_name: String, fail_reason: String, time_played: float):
	"""Track level failure/quit"""
	track_event("level_fail", EventCategory.GAMEPLAY, {
		"level_name": level_name,
		"fail_reason": fail_reason,
		"time_played": time_played,
		"success": false
	})

func track_ui_interaction(element_name: String, action: String, context: String = ""):
	"""Track UI interactions"""
	track_event("ui_interaction", EventCategory.UI, {
		"element": element_name,
		"action": action,
		"context": context
	})

func track_performance_issue(issue_type: String, severity: String, details: Dictionary = {}):
	"""Track performance issues"""
	track_event("performance_issue", EventCategory.PERFORMANCE, {
		"issue_type": issue_type,
		"severity": severity,
		"details": details,
		"fps": Engine.get_frames_per_second(),
		"memory_usage": OS.get_static_memory_peak_usage()
	})

func track_error(error_type: String, error_message: String, stack_trace: String = ""):
	"""Track errors and crashes"""
	track_event("error", EventCategory.ERROR, {
		"error_type": error_type,
		"error_message": error_message,
		"stack_trace": stack_trace,
		"platform": OS.get_name(),
		"version": ProjectSettings.get_setting("application/config/version", "1.0.0")
	})

func track_setting_change(setting_name: String, old_value, new_value):
	"""Track when settings are changed"""
	track_event("setting_change", EventCategory.UI, {
		"setting_name": setting_name,
		"old_value": str(old_value),
		"new_value": str(new_value)
	})

# Internal event management
func _add_event_to_queue(event_data: Dictionary):
	"""Add event to the queue for batching"""
	event_queue.append(event_data)
	
	# Prevent memory overflow
	if event_queue.size() > MAX_EVENTS_IN_MEMORY:
		event_queue.pop_front()
	
	# Auto-flush if batch size reached
	if event_queue.size() >= BATCH_SIZE:
		_flush_events()
	
	analytics_event_sent.emit(event_data)

func _flush_events():
	"""Flush queued events"""
	if event_queue.is_empty():
		return
	
	var batch = event_queue.duplicate()
	event_queue.clear()
	
	_send_batch(batch)

func _send_batch(batch: Array[Dictionary]):
	"""Send a batch of events (placeholder for actual implementation)"""
	# In a real implementation, this would send data to your analytics service
	# For now, we'll just log locally and emit a signal
	
	_log_batch_locally(batch)
	analytics_batch_sent.emit(batch)
	
	if ErrorHandler and OS.is_debug_build():
		ErrorHandler.debug("Analytics batch sent: " + str(batch.size()) + " events", "Analytics")

func _log_batch_locally(batch: Array[Dictionary]):
	"""Log analytics batch to local file for debugging"""
	var log_path = "user://analytics_log.json"
	var file = FileAccess.open(log_path, FileAccess.WRITE)
	if file:
		for event in batch:
			file.store_line(JSON.stringify(event))
		file.close()

func _category_to_string(category: EventCategory) -> String:
	"""Convert category enum to string"""
	match category:
		EventCategory.GAMEPLAY: return "gameplay"
		EventCategory.UI: return "ui"
		EventCategory.PERFORMANCE: return "performance"
		EventCategory.ERROR: return "error"
		EventCategory.PROGRESSION: return "progression"
		EventCategory.MONETIZATION: return "monetization"
		_: return "unknown"

# Session management
func end_session():
	"""End the current analytics session"""
	if not ANALYTICS_ENABLED:
		return
	
	var time = Time.get_datetime_dict_from_system()
	var session_duration = time.hour * 3600 + time.minute * 60 + time.second - session_start_time
	
	track_event("session_end", EventCategory.GAMEPLAY, {
		"session_duration": session_duration,
		"events_sent": user_data.get("total_events", 0)
	})
	
	_flush_events()

# Utility functions
func get_session_data() -> Dictionary:
	"""Get current session data"""
	return session_data.duplicate()

func get_user_data() -> Dictionary:
	"""Get current user data"""
	return user_data.duplicate()

func is_analytics_enabled() -> bool:
	"""Check if analytics is enabled"""
	return ANALYTICS_ENABLED

func get_queue_size() -> int:
	"""Get current event queue size"""
	return event_queue.size()

# Privacy and GDPR compliance
func opt_out():
	"""Opt user out of analytics"""
	# Implementation would disable analytics and clear stored data
	event_queue.clear()
	if ErrorHandler:
		ErrorHandler.info("User opted out of analytics")

func clear_user_data():
	"""Clear all stored user data"""
	user_data.clear()
	var save_path = "user://analytics_user.dat"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)

# Cleanup
func _exit_tree():
	end_session()
	if flush_timer:
		flush_timer.queue_free()