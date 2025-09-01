extends Node2D

func _ready():
	print("Starting HintDisplay test...")
	
	# Wait a moment for everything to initialize
	await get_tree().create_timer(1.0).timeout
	
	# Test short hint
	print("Testing short hint...")
	EventBus.hint_requested.emit("Short hint!", "Test")
	
	await get_tree().create_timer(3.0).timeout
	EventBus.hint_dismissed.emit()
	
	await get_tree().create_timer(1.0).timeout
	
	# Test long hint
	print("Testing long hint...")
	EventBus.hint_requested.emit("This is a very long hint message that should demonstrate the dynamic sizing feature. The hint display should automatically adjust its size to accommodate this longer text content while maintaining good visual design.", "Dynamic Sizing Test")
	
	await get_tree().create_timer(5.0).timeout
	EventBus.hint_dismissed.emit()
	
	print("Test completed!")
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()