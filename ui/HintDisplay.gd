extends Control
class_name HintDisplay

## UI component that displays hint messages triggered by HintArea
## Dynamically adjusts size based on content length

@onready var background: Panel = $Background
@onready var title_label: Label = $Background/VBoxContainer/TitleLabel
@onready var message_label: Label = $Background/VBoxContainer/MessageLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var vbox_container: VBoxContainer = $Background/VBoxContainer

var _is_showing: bool = false
var _original_position: Vector2
var _original_size: Vector2

# Dynamic sizing configuration
@export var min_width: float = 300.0
@export var max_width: float = 600.0
@export var min_height: float = 80.0
@export var max_height: float = 400.0
@export var padding: Vector2 = Vector2(32, 32)  # Internal padding for content



func _ready():
	# Connect to EventBus signals
	EventBus.hint_requested.connect(_on_hint_requested)
	EventBus.hint_dismissed.connect(_on_hint_dismissed)
	
	# Store original position and size for animation reference
	_original_position = position
	_original_size = size
	
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
	
	# Update content and wait for sizing to complete before showing
	_update_content(message, title)
	# Wait one frame for the deferred sizing to complete
	await get_tree().process_frame
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
	
	# Dynamically adjust size based on content (call without await to avoid blocking)
	_adjust_size_for_content.call_deferred(message, title)

func _show_hint():
	_is_showing = true
	visible = true
	
	print("💡 HintDisplay: Showing hint with animation")
	
	# Store the target position (current position after dynamic sizing)
	var target_position = position
	
	# Start from below the target position
	position = target_position + Vector2(0, 50)
	modulate.a = 0.0
	
	# Create smooth slide-up and fade-in animation
	var tween: Tween = create_tween()
	tween.set_parallel(true)  # Allow multiple properties to animate simultaneously
	tween.tween_property(self, "position", target_position, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_on_show_complete)

  
func _hide_hint():
	if not _is_showing:
		return
		
	print("💡 HintDisplay: Hiding hint with animation")
	
	# Create smooth slide-down and fade-out animation
	var tween: Tween = create_tween()
	tween.set_parallel(true)  # Allow multiple properties to animate simultaneously
	tween.tween_property(self, "position:y", position.y + 30, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_callback(_on_hide_complete)

func _on_show_complete():
	# Hint is now fully visible
	pass

func _on_hide_complete():
	_is_showing = false
	visible = false
	# Reset position and size to original when fully hidden
	position = _original_position
	size = _original_size

# Method to manually show hint (for testing or scripted events)
func show_hint_manual(message: String, title: String = ""):
	_on_hint_requested(message, title)

# Method to manually hide hint
func hide_hint_manual():
	_on_hint_dismissed()

# Dynamic sizing methods
func _adjust_size_for_content(message: String, title: String):
	"""Dynamically adjust the hint display size based on content length"""
	if not message_label or not title_label or not vbox_container:
		print("❌ HintDisplay: Required nodes not found for dynamic sizing")
		return
	
	print("💡 HintDisplay: Starting dynamic sizing - original size: ", _original_size, " original pos: ", _original_position)
	
	# Calculate required width based on text content
	var required_width = _calculate_required_width(message, title)
	var required_height = _calculate_required_height(message, title)
	
	print("💡 HintDisplay: Calculated required size: ", Vector2(required_width, required_height))
	
	# Clamp to min/max bounds
	required_width = clampf(required_width, min_width, max_width)
	required_height = clampf(required_height, min_height, max_height)
	
	# Update the control size
	var new_size = Vector2(required_width, required_height)
	size = new_size
	
	# Update position to keep it centered horizontally and at bottom
	var new_position = Vector2(
		_original_position.x - (new_size.x - _original_size.x) / 2,
		_original_position.y - (new_size.y - _original_size.y)
	)
	position = new_position
	
	print("💡 HintDisplay: Adjusted size to ", new_size, " and position to ", new_position)

func _calculate_required_width(message: String, title: String) -> float:
	"""Calculate the required width based on text content"""
	var font_size_message = 14  # Default message font size
	var font_size_title = 18    # Default title font size
	
	# Estimate character width (rough approximation)
	var char_width_message = font_size_message * 0.6
	var char_width_title = font_size_title * 0.6
	
	# Calculate width needed for message (considering word wrapping)
	var message_lines = _estimate_wrapped_lines(message, max_width - padding.x, char_width_message)
	var max_line_width = 0.0
	
	for line in message_lines:
		var line_width = line.length() * char_width_message
		max_line_width = maxf(max_line_width, line_width)
	
	# Calculate width needed for title
	var title_width = title.length() * char_width_title
	
	# Take the maximum of title and message width, plus padding
	var content_width = maxf(max_line_width, title_width)
	return content_width + padding.x

func _calculate_required_height(message: String, title: String) -> float:
	"""Calculate the required height based on text content"""
	var font_size_message = 14
	var font_size_title = 18
	var line_height_message = font_size_message * 1.2
	var line_height_title = font_size_title * 1.2
	var char_width_message = font_size_message * 0.6
	
	# Calculate height for title
	var title_height = 0.0
	if not title.is_empty():
		title_height = line_height_title
	
	# Calculate height for message (considering word wrapping)
	var available_width = min(max_width - padding.x, size.x - padding.x)
	var message_lines = _estimate_wrapped_lines(message, available_width, char_width_message)
	var message_height = message_lines.size() * line_height_message
	
	# Add spacing between title and message if both exist
	var spacing = 8.0 if not title.is_empty() else 0.0
	
	# Total height with padding
	return title_height + spacing + message_height + padding.y

func _estimate_wrapped_lines(text: String, available_width: float, char_width: float) -> Array[String]:
	"""Estimate how text will wrap given available width"""
	var lines: Array[String] = []
	var words = text.split(" ")
	var current_line = ""
	var chars_per_line = int(available_width / char_width)
	
	for word in words:
		var test_line = current_line + (" " if not current_line.is_empty() else "") + word
		
		if test_line.length() <= chars_per_line:
			current_line = test_line
		else:
			if not current_line.is_empty():
				lines.append(current_line)
			current_line = word
			
			# Handle very long words that exceed line width
			while current_line.length() > chars_per_line:
				lines.append(current_line.substr(0, chars_per_line))
				current_line = current_line.substr(chars_per_line)
	
	if not current_line.is_empty():
		lines.append(current_line)
	
	return lines
