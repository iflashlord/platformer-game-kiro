extends Control

@onready var input_display: Label = $InputDisplay

var input_states = {
	"move_left": false,
	"move_right": false,
	"jump": false,
	"dimension_flip": false
}

func _ready():
	# Force visibility for testing
	$TouchControls.visible = true

func _process(_delta):
	var display_text = "Inputs:\n"
	
	for action in input_states.keys():
		var is_pressed = Input.is_action_pressed(action)
		input_states[action] = is_pressed
		
		var status = "PRESSED" if is_pressed else "released"
		var color = "[color=green]" if is_pressed else "[color=gray]"
		display_text += color + action + ": " + status + "[/color]\n"
	
	input_display.text = display_text