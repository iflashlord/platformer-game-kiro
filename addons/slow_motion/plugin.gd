@tool
extends EditorPlugin

const AUTOLOAD_NAME = "SlowMotion"

func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/slow_motion/SlowMotion.tscn")


func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
