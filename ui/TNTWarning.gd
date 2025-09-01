extends Control
class_name TNTWarning

@onready var warning_icon: ColorRect = $WarningIcon
@onready var timer: Timer = $Timer

func _ready():
	modulate.a = 0.0
	timer.timeout.connect(_fade_out)

func show_warning(duration: float = 2.0):
	timer.wait_time = duration
	timer.start()
	
	# Fade in
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	# Pulsing effect
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(warning_icon, "modulate", Color.RED, 0.3)
	pulse_tween.tween_property(warning_icon, "modulate", Color.YELLOW, 0.3)

func _fade_out():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()