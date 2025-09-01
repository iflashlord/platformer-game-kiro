extends Node2D

## Test script to verify "Both" dimensions functionality

@onready var player: CharacterBody2D = $Player
@onready var both_hint: HintArea = $BothDimensionsHint
@onready var dimension_a_hint: HintArea = $DimensionAHint
@onready var dimension_b_hint: HintArea = $DimensionBHint

func _ready():
	print("Starting Both Dimensions test...")
	
	# Wait for everything to initialize
	await get_tree().create_timer(1.0).timeout
	
	# Test in dimension A
	print("=== Testing in Dimension A ===")
	DimensionManager.set_layer("A")
	await get_tree().create_timer(0.5).timeout
	
	print("Both hint active:", both_hint.is_active_in_current_dimension())
	print("A hint active:", dimension_a_hint.is_active_in_current_dimension())
	print("B hint active:", dimension_b_hint.is_active_in_current_dimension())
	
	# Test in dimension B
	print("=== Testing in Dimension B ===")
	DimensionManager.set_layer("B")
	await get_tree().create_timer(0.5).timeout
	
	print("Both hint active:", both_hint.is_active_in_current_dimension())
	print("A hint active:", dimension_a_hint.is_active_in_current_dimension())
	print("B hint active:", dimension_b_hint.is_active_in_current_dimension())
	
	print("Test completed!")
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()