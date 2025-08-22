extends CanvasLayer
class_name GameHUD

@onready var hearts_container: HBoxContainer = $UI/TopBar/HealthContainer
@onready var time_display: Label = $UI/TopBar/TimerContainer/TimeDisplay
@onready var score_display: Label = $UI/TopBar/ScoreContainer/ScoreDisplay
@onready var pause_button: Button = $UI/TopBar/PauseButton
@onready var pause_overlay: Control = $UI/PauseOverlay

@onready var heartOne: AnimatedSprite2D = $UI/TopBar/HealthContainer/AnimatedSprite2D_1
@onready var heartTwo: AnimatedSprite2D = $UI/TopBar/HealthContainer/AnimatedSprite2D_2
@onready var heartThree: AnimatedSprite2D = $UI/TopBar/HealthContainer/AnimatedSprite2D_3
@onready var heartFour: AnimatedSprite2D = $UI/TopBar/HealthContainer/AnimatedSprite2D_4
@onready var heartFive: AnimatedSprite2D = $UI/TopBar/HealthContainer/AnimatedSprite2D_5

var is_paused := false
var pause_menu: PauseMenu = null

func _ready():
	print("💖 GameHUD _ready() called")
 
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
	
	# Pause button
	pause_button.pressed.connect(_on_pause_button_pressed)
	
	# Hide pause overlay initially
	pause_overlay.visible = false
	
	# Initialize displays
	_update_time_display(0.0)
	_update_score_display(0)

	# Instance PauseMenu and add to scene
	var pause_menu_scene = preload("res://ui/PauseMenu.tscn")
	pause_menu = pause_menu_scene.instantiate()
	add_child(pause_menu)
	pause_menu.visible = false
	pause_menu.resume_requested.connect(_on_pause_menu_resume) # <-- Connect signal

func _setHearts(active: int):
	var hearts = [heartOne, heartTwo, heartThree, heartFour, heartFive]
	for i in range(5):
		if i < active:
			hearts[i].play("default")
		else:
			hearts[i].play("empty")

# func _ready():
# 	print("💖 GameHUD _ready() called")
 
# 	# Initialize heart display
# 	_update_health_display(5, 5)
	
# 	# Connect to health system
# 	if HealthSystem:
# 		HealthSystem.health_changed.connect(_on_health_changed)
# 		HealthSystem.heart_lost.connect(_on_heart_lost)
	
# 	# Connect to timer system
# 	if GameTimer:
# 		GameTimer.time_updated.connect(_on_time_updated)
	
# 	# Connect to game events
# 	if Game:
# 		Game.score_changed.connect(_on_score_changed)
	
# 	# Pause button
# 	pause_button.pressed.connect(_on_pause_button_pressed)
	
# 	# Hide pause overlay initially
# 	pause_overlay.visible = false
	
# 	# Initialize displays
# 	_update_health_display(5, 5)
# 	_update_time_display(0.0)
# 	_update_score_display(0)

func _on_health_changed(current_health: int, max_health: int):
	_update_health_display(current_health, max_health)

 
func _on_heart_lost():
	# Animate heart loss
	var lost_heart_index = HealthSystem.get_current_health()

	# Animate the heart for AnimatedSprite2D
	var heart = hearts_container.get_child(lost_heart_index) as AnimatedSprite2D

	# Shake, blink red, and reset heart position/size using tween
	var original_position = heart.position
	var original_modulate = heart.modulate

	var tween = create_tween()
	# Shake horizontally
	tween.tween_property(heart, "position", original_position + Vector2(10, 0), 0.05)
	tween.tween_property(heart, "position", original_position - Vector2(10, 0), 0.05)
	tween.tween_property(heart, "position", original_position, 0.05)
	# Blink red
	tween.tween_property(heart, "modulate", Color(1, 0, 0), 0.05)
	tween.tween_property(heart, "modulate", original_modulate, 0.05)
	

func _update_health_display(current_health: int, max_health: int):
	print("💖 GameHUD: Updating health display - ", current_health, "/", max_health)
	
	_setHearts(current_health)
	

func _on_time_updated(time: float):
	_update_time_display(time)

func _update_time_display(time: float):
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	time_display.text = "%02d:%02d" % [minutes, seconds]

func _on_score_changed(new_score: int):
	_update_score_display(new_score)

func _update_score_display(score: int):
	score_display.text = str(score)
	
	# Score increase animation
	var tween = create_tween()
	tween.tween_property(score_display, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(score_display, "scale", Vector2.ONE, 0.1)

func _on_pause_button_pressed():
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_overlay.visible = is_paused
	if GameTimer:
		if is_paused:
			GameTimer.pause_timer()
		else:
			GameTimer.resume_timer()
	
	# Show or hide PauseMenu
	if pause_menu:
		if is_paused:
			pause_menu.show_pause_menu()
		else:
			pause_menu.hide_pause_menu()

# Resume from PauseMenu
func resume_game():
	is_paused = false
	get_tree().paused = false
	pause_overlay.visible = false
	if GameTimer:
		GameTimer.resume_timer()
	if pause_menu:
		pause_menu.hide_pause_menu()

func _on_pause_menu_resume():
	resume_game()

func show_hud():
	visible = true

func hide_hud():
	visible = false

func update_health(current_health: int, max_health: int = 5):
	"""Direct method to update health display - can be called from levels"""
	print("💖 Updating health display: ", current_health, "/", max_health)
	_update_health_display(current_health, max_health)
