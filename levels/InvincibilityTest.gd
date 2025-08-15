extends Node2D

# Test script to verify invincibility and stomping systems
func _ready():
	print("🧪 Combat Test Level Ready")
	print("Instructions:")
	print("- Walk into enemies from the side to test invincibility")
	print("- Jump on top of enemies to stomp them")
	print("- Player should blink for 3 seconds after taking damage")
	print("- Stomped enemies should give points and bounce player up")
	
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