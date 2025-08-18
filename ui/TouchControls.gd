extends Control

@onready var left_button: TouchScreenButton = $LeftButton
@onready var right_button: TouchScreenButton = $RightButton
@onready var jump_button: TouchScreenButton = $JumpButton
@onready var dimension_button: TouchScreenButton = $DimensionButton

var repeat_timer: Timer
var current_action: String = ""
var repeat_delay: float = 0.5
var repeat_rate: float = 0.1

func _ready():
	# Only show on touch devices
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		visible = false
		return
	
	# Create repeat timer
	repeat_timer = Timer.new()
	repeat_timer.wait_time = repeat_delay
	repeat_timer.one_shot = true
	repeat_timer.timeout.connect(_start_repeat)
	add_child(repeat_timer)
	
	# Connect button signals
	left_button.pressed.connect(_on_button_pressed.bind("move_left"))
	left_button.released.connect(_on_button_released.bind("move_left"))
	
	right_button.pressed.connect(_on_button_pressed.bind("move_right"))
	right_button.released.connect(_on_button_released.bind("move_right"))
	
	jump_button.pressed.connect(_on_button_pressed.bind("jump"))
	jump_button.released.connect(_on_button_released.bind("jump"))
	
	dimension_button.pressed.connect(_on_button_pressed.bind("dimension_flip"))
	dimension_button.released.connect(_on_button_released.bind("dimension_flip"))

func _on_button_pressed(action: String):
	# Send initial input
	Input.action_press(action)
	
	# Start repeat timer for movement actions
	if action in ["move_left", "move_right"]:
		current_action = action
		repeat_timer.wait_time = repeat_delay
		repeat_timer.start()

func _on_button_released(action: String):
	# Stop input
	Input.action_release(action)
	
	# Stop repeat
	if current_action == action:
		current_action = ""
		repeat_timer.stop()

func _start_repeat():
	if current_action != "":
		# Switch to faster repeat rate
		repeat_timer.wait_time = repeat_rate
		repeat_timer.start()
		
		# Send repeated input
		Input.action_press(current_action)
