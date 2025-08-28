extends Node
class_name LevelCardEffects

# Visual effects for level cards

static func create_unlock_animation(card: Control):
	"""Create unlock animation effect"""
	var tween = card.create_tween()
	tween.set_parallel(true)
	
	# Scale pulse
	tween.tween_property(card, "scale", Vector2(1.2, 1.2), 0.3)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.3)
	
	# Glow effect
	tween.tween_property(card, "modulate", Color(1.5, 1.5, 1.0), 0.3)
	tween.tween_property(card, "modulate", Color.WHITE, 0.3).set_delay(0.3)

static func create_lock_effect(card: Control):
	"""Create locked state visual effect"""
	var shake_tween = card.create_tween()
	shake_tween.set_loops(3)
	
	# Shake animation
	shake_tween.tween_property(card, "position", card.position + Vector2(5, 0), 0.1)
	shake_tween.tween_property(card, "position", card.position + Vector2(-5, 0), 0.1)
	shake_tween.tween_property(card, "position", card.position, 0.1)

static func create_hover_effect(card: Control, hovered: bool):
	"""Create hover effect"""
	var tween = card.create_tween()
	
	if hovered:
		tween.tween_property(card, "scale", Vector2(1.05, 1.05), 0.1)
		tween.parallel().tween_property(card, "modulate", Color(1.1, 1.1, 1.1), 0.1)
	else:
		tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.1)
		tween.parallel().tween_property(card, "modulate", Color.WHITE, 0.1)

static func create_completion_effect(card: Control):
	"""Create completion celebration effect"""
	var tween = card.create_tween()
	tween.set_parallel(true)
	
	# Bounce effect
	tween.tween_property(card, "scale", Vector2(1.1, 1.1), 0.2)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.2)
	
	# Color flash
	tween.tween_property(card, "modulate", Color.GOLD, 0.2)
	tween.tween_property(card, "modulate", Color.WHITE, 0.2).set_delay(0.2)

static func create_perfect_glow(card: Control):
	"""Create continuous glow for perfect completions"""
	var glow_tween = card.create_tween()
	glow_tween.set_loops()
	
	glow_tween.tween_property(card, "modulate", Color(1.2, 1.1, 0.8), 1.0)
	glow_tween.tween_property(card, "modulate", Color(1.0, 0.9, 0.7), 1.0)

static func create_focus_pulse(border: Control):
	"""Create focus border pulse effect"""
	var pulse_tween = border.create_tween()
	pulse_tween.set_loops()
	
	pulse_tween.tween_property(border, "modulate", Color(0.5, 1.0, 1.0, 1.0), 0.5)
	pulse_tween.tween_property(border, "modulate", Color(0.0, 0.8, 1.0, 0.8), 0.5)
