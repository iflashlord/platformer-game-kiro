extends Node

## Simplified error handler for production

enum LogLevel {
	DEBUG,
	INFO,
	WARNING,
	ERROR,
	CRITICAL
}

func _ready():
	pass

func debug(message: String, context: String = ""):
	if OS.is_debug_build():
		print("[DEBUG] ", message)

func info(message: String, context: String = ""):
	if OS.is_debug_build():
		print("[INFO] ", message)

func warning(message: String, context: String = ""):
	print("[WARNING] ", message)

func error(message: String, context: String = ""):
	print("[ERROR] ", message)

func critical(message: String, context: String = ""):
	print("[CRITICAL] ", message)

func report_scene_load_error(scene_path: String, error_code: int):
	error("Failed to load scene: " + scene_path + " (Error: " + str(error_code) + ")")

func report_resource_error(resource_path: String, operation: String):
	error("Resource operation failed: " + operation + " on " + resource_path)

func report_system_error(system_name: String, error_message: String):
	error("System error in " + system_name + ": " + error_message)
