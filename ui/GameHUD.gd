extends CanvasLayer
class_name GameHUD

@onready var hearts_container: HBoxContainer = $UI/TopBar/HealthContainer/HeartsContainer
@onready var time_display: Label = $UI/TopBar/TimerContainer/TimeDisplay
@onready var score_display: Label = $UI/TopBar/ScoreContainer/ScoreDisplay

var heart_labels: Array[Label] = []

func _ready():
	print("💖 GameHUD _ready() called")
	
	# Check if hearts container exists
	if not hearts_container:
		print("❌ Hearts container not found!")
		return
	
	# Get all heart labels
	print("🔍 Finding heart labels...")
	for i in range(5):
		if i < hearts_container.get_child_count():
			var heart_label = hearts_container.get_child(i) as Label
			if heart_label:
				heart_labels.append(heart_label)
				print("✅ Found heart ", i + 1, ": ", heart_label.name)
			else:
				print("❌ Heart ", i + 1, " is not a Label")
		else:
			print("❌ Heart ", i + 1, " not found - not enough children")
	
	print("💖 Found ", heart_labels.size(), " heart labels")
	
	# Initialize heart display
	_update_health_display(5, 5)
	
	# Connect to health system
	if HealthSystem:
		HealthSystem.health_changed.connect(_on_health_changed)
		HealthSystem.heart_lost.connect(_on_heart_lost)
	
	# Connect to timer system
	if GameTimer:
		GameTimer.time_updated.connect(_on_time_updated)
	
	# Connect to game events
	if Game:
		Game.score_changed.connect(_on_score_changed)
	
	# Initialize displays
	_update_health_display(5, 5)
	_update_time_display(0.0)
	_update_score_display(0)

func _on_health_changed(current_health: int, max_health: int):
	_update_health_display(current_health, max_health)

func _on_heart_lost():
	# Animate heart loss
	var lost_heart_index = HealthSystem.get_current_health()
	if lost_heart_index < heart_labels.size():
		var heart = heart_labels[lost_heart_index]
		
		# Heart loss animation
		var tween = create_tween()
		tween.parallel().tween_property(heart, "scale", Vector2(1.5, 1.5), 0.1)
		tween.parallel().tween_property(heart, "modulate", Color.WHITE, 0.1)
		tween.tween_property(heart, "scale", Vector2.ONE, 0.2)
		tween.parallel().tween_property(heart, "modulate", Color(0.3, 0.3, 0.3, 0.5), 0.2)

func _update_health_display(current_health: int, max_health: int):
	print("💖 GameHUD: Updating health display - ", current_health, "/", max_health)
	
	for i in range(heart_labels.size()):
		if i < heart_labels.size():
			var heart = heart_labels[i]
			if i < current_health:
				# Full heart
				heart.modulate = Color(1, 0.2, 0.2, 1)
				heart.text = "♥"
			else:
				# Empty heart
				heart.modulate = Color(0.3, 0.3, 0.3, 0.5)
				heart.text = "♡"

func _on_time_updated(time: float):
	_update_time_display(time)

func _update_time_display(time: float):
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	time_display.text = "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

func _on_score_changed(new_score: int):
	_update_score_display(new_score)

func _update_score_display(score: int):
	score_display.text = str(score)
	
	# Score increase animation
	var tween = create_tween()
	tween.tween_property(score_display, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(score_display, "scale", Vector2.ONE, 0.1)

func show_hud():
	visible = true

func hide_hud():
	visible = false

func update_health(current_health: int, max_health: int = 5):
	"""Direct method to update health display - can be called from levels"""
	print("💖 Updating health display: ", current_health, "/", max_health)
	_update_health_display(current_health, max_health)
