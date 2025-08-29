extends Node

## Simplified input management system

var touch_enabled: bool = false

func _ready():
	touch_enabled = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	
	if ErrorHandler:
		ErrorHandler.info("Input manager initialized")

func is_touch_enabled() -> bool:
	return touch_enabled

func _exit_tree():
	if ErrorHandler:
		ErrorHandler.debug("Input manager shutting down")
