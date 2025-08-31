extends Control
class_name HintDisplay

## UI component that displays hint messages triggered by HintArea

@onready var background: Panel = $Background
@onready var title_label: Label = $Background/VBoxContainer/TitleLabel
@onready var message_label: Label = $Background/VBoxContainer/MessageLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _is_showing: bool = false
var _original_position: Vector2

func _ready():
	# Connect to EventBus signals
	EventBus.hint_requested.connect(_on_hint_requested)
	EventBus.hint_dismissed.connect(_on_hint_dismissed)
	
	# Store original position for animation reference
	_original_position = position
	
	# Start hidden
	modulate.a = 0.0
	visible = false

func _on_hint_requested(message: String, title: String = ""):
	print("💡 HintDisplay: Hint requested - '", title, "': '", message, "'")
	
	if _is_showing:
		# If already showing, just update the content
		print("💡 HintDisplay: Updating existing hint")
		_update_content(message, title)
		return
	
	_update_content(message, title)
	_show_hint()

func _on_hint_dismissed():
	print("💡 HintDisplay: Hint dismissed")
	if _is_showing:
		_hide_hint()

func _update_content(message: String, title: String):
	if not message_label:
		print("❌ HintDisplay: message_label is null!")
		return
		
	message_label.text = message
	
	if not title_label:
		print("❌ HintDisplay: title_label is null!")
		return
		
	if title.is_empty():
		title_label.visible = false
	else:
		title_label.text = title
		title_label.visible = true

func _show_hint():
	_is_showing = true
	visible = true
	
	print("💡 HintDisplay: Showing hint with animation")
	
	# Reset to original position and start from below
	position = _original_position
	position.y += 50
	modulate.a = 0.0
	
	# Create smooth slide-up and fade-in animation
	var tween = create_tween()
	tween.set_parallel(true)  # Allow multiple properties to animate simultaneously
	tween.tween_property(self, "position", _original_position, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_on_show_complete)

  
func _hide_hint():
	if not _is_showing:
		return
		
	print("💡 HintDisplay: Hiding hint with animation")
	
	# Create smooth slide-down and fade-out animation
	var tween = create_tween()
	tween.set_parallel(true)  # Allow multiple properties to animate simultaneously
	tween.tween_property(self, "position:y", _original_position.y + 30, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_callback(_on_hide_complete)

func _on_show_complete():
	# Hint is now fully visible
	pass

func _on_hide_complete():
	_is_showing = false
	visible = false
	# Reset position to original when fully hidden
	position = _original_position

# Method to manually show hint (for testing or scripted events)
func show_hint_manual(message: String, title: String = ""):
	_on_hint_requested(message, title)

# Method to manually hide hint
func hide_hint_manual():
	_on_hint_dismissed()
