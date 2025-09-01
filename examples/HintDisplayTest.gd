extends Control

## Test script for HintDisplay dynamic sizing

@onready var hint_display: HintDisplay = $HintDisplay

var test_messages = [
	"Short hint!",
	"This is a medium-length hint message that should demonstrate the dynamic sizing feature.",
	"This is a very long hint message that should really test the dynamic sizing capabilities of the new hint display system. It contains multiple sentences and should wrap properly while adjusting the display size to accommodate all the content without looking cramped or awkward. The system should handle this gracefully and maintain good visual design principles.",
	"Multi\nLine\nHint\nWith\nExplicit\nBreaks"
]

var test_titles = [
	"Short",
	"Medium Length Title",
	"Very Long Title That Tests Width Calculation",
	"Multi-Line"
]

var current_test = 0

func _ready():
	print("HintDisplay Test Ready")
	_show_next_test()

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space or Enter
		_show_next_test()
	elif event.is_action_pressed("ui_cancel"):  # Escape
		get_tree().quit()

func _show_next_test():
	if current_test >= test_messages.size():
		current_test = 0
	
	var message = test_messages[current_test]
	var title = test_titles[current_test]
	
	print("Testing hint ", current_test + 1, "/", test_messages.size())
	print("Title: '", title, "'")
	print("Message: '", message, "'")
	
	EventBus.hint_requested.emit(message, title)
	
	current_test += 1
	
	# Auto-dismiss after 3 seconds for testing
	get_tree().create_timer(3.0).timeout.connect(func(): EventBus.hint_dismissed.emit())
