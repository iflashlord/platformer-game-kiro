extends Node2D

## Test script to simulate player entering and exiting hint areas

@onready var player: CharacterBody2D = $Player
@onready var hint_area: HintArea = $HintArea

func _ready():
	print("Starting HintArea exit test...")
	
	# Wait for everything to initialize
	await get_tree().create_timer(1.0).timeout
	
	# Simulate player entering hint area
	print("Simulating player entering hint area...")
	hint_area._on_body_entered(player)
	
	await get_tree().create_timer(2.0).timeout
	
	# Simulate player exiting hint area
	print("Simulating player exiting hint area...")
	hint_area._on_body_exited(player)
	
	await get_tree().create_timer(2.0).timeout
	
	print("Test completed!")
	get_tree().quit()