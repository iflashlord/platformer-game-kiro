extends Area2D
class_name HintArea

## A hint area that displays a message when the player enters and hides it when they exit

@export var hint_message: String = "Enter your hint message here"
@export var hint_title: String = ""
@export var auto_hide_delay: float = 0.0  # 0 = manual hide only
@export var show_once_only: bool = false

var _has_been_shown: bool = false
var _hide_timer: Timer

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Setup auto-hide timer if needed
	if auto_hide_delay > 0:
		_hide_timer = Timer.new()
		_hide_timer.wait_time = auto_hide_delay
		_hide_timer.one_shot = true
		_hide_timer.timeout.connect(_on_auto_hide_timeout)
		add_child(_hide_timer)
	
	# Ensure we're monitoring the right collision layers
	collision_layer = 0  # Don't collide with anything
	collision_mask = 2   # Only detect player (layer 2)

func _on_body_entered(body: Node2D):
	if not body.has_method("is_player"):
		return
		
	if show_once_only and _has_been_shown:
		return

	# Audio feedback
	if Audio:
		Audio.play_sfx("hint")
	
		
	_show_hint()
	_has_been_shown = true

func _on_body_exited(body: Node2D):
	if not body.has_method("is_player"):
		return
		
	_hide_hint()

func _show_hint():
	# Send signal to UI system to show hint
	EventBus.hint_requested.emit(hint_message, hint_title)
	
	# Start auto-hide timer if configured
	if _hide_timer and auto_hide_delay > 0:
		_hide_timer.start()

func _hide_hint():
	# Stop auto-hide timer
	if _hide_timer:
		_hide_timer.stop()
	
	# Send signal to UI system to hide hint
	EventBus.hint_dismissed.emit()

func _on_auto_hide_timeout():
	_hide_hint()

# Method to manually trigger hint (useful for scripted events)
func trigger_hint():
	_show_hint()

# Method to reset the "shown once" state
func reset_shown_state():
	_has_been_shown = false