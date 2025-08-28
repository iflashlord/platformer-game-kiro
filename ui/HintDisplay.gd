extends Control
class_name HintDisplay

## UI component that displays hint messages triggered by HintArea

@onready var background: NinePatchRect = $Background
@onready var title_label: Label = $Background/VBoxContainer/TitleLabel
@onready var message_label: Label = $Background/VBoxContainer/MessageLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _is_showing: bool = false

func _ready():
	# Connect to EventBus signals
	EventBus.hint_requested.connect(_on_hint_requested)
	EventBus.hint_dismissed.connect(_on_hint_dismissed)
	
	# Start hidden
	modulate.a = 0.0
	visible = false

func _on_hint_requested(message: String, title: String = ""):
	if _is_showing:
		# If already showing, just update the content
		_update_content(message, title)
		return
	
	_update_content(message, title)
	_show_hint()

func _on_hint_dismissed():
	if _is_showing:
		_hide_hint()

func _update_content(message: String, title: String):
	message_label.text = message
	
	if title.is_empty():
		title_label.visible = false
	else:
		title_label.text = title
		title_label.visible = true

func _show_hint():
	_is_showing = true
	visible = true
	
	# Create fade-in tween
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_callback(_on_show_complete)

func _hide_hint():
	if not _is_showing:
		return
		
	# Create fade-out tween
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(_on_hide_complete)

func _on_show_complete():
	# Hint is now fully visible
	pass

func _on_hide_complete():
	_is_showing = false
	visible = false

# Method to manually show hint (for testing or scripted events)
func show_hint_manual(message: String, title: String = ""):
	_on_hint_requested(message, title)

# Method to manually hide hint
func hide_hint_manual():
	_on_hint_dismissed()