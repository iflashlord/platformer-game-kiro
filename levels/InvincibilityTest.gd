extends Node2D

# Simple test script to verify invincibility system
func _ready():
	print("🧪 Invincibility Test Level Ready")
	print("Instructions:")
	print("- Walk into enemies or spikes to test invincibility")
	print("- Player should blink for 3 seconds after taking damage")
	print("- During blinking, player should not take additional damage")
	
	# Add some debug info
	if Input.is_action_pressed("ui_accept"):
		_debug_test_invincibility()

func _input(event):
	# Debug key to manually test invincibility
	if event.is_action_pressed("ui_accept"):
		_debug_test_invincibility()

func _debug_test_invincibility():
	var player = get_node_or_null("Player")
	if player and player.has_method("take_damage"):
		print("🧪 Debug: Manually triggering player damage")
		player.take_damage(1)
	else:
		print("❌ Player not found or doesn't have take_damage method")