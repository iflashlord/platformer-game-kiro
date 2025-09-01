extends Control
class_name BossHealthUI

@onready var health_bar: ProgressBar = $HealthBar
@onready var boss_name: Label = $BossName
@onready var phase_indicator: Label = $PhaseIndicator
@onready var damage_counter: Label = $DamageCounter

var max_health: int = 5
var current_health: int = 5

func _ready():
	# Connect to EventBus for boss health updates
	if EventBus.has_signal("boss_health_changed"):
		EventBus.boss_health_changed.connect(_on_boss_health_changed)
	
	# Initially hidden
	visible = false

func show_boss_ui(boss_name_text: String = "GIANT BOSS"):
	boss_name.text = boss_name_text
	visible = true
	
	# Animate in
	var tween = create_tween()
	modulate.a = 0.0
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func hide_boss_ui():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	visible = false

func _on_boss_health_changed(health: int, max_hp: int):
	current_health = health
	max_health = max_hp
	
	# Update health bar
	var health_percentage = (float(health) / max_hp) * 100
	health_bar.value = health_percentage
	
	# Color based on health
	if health_percentage > 60:
		health_bar.modulate = Color.GREEN
	elif health_percentage > 30:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.RED
	
	# Update damage counter
	var damage_taken = max_hp - health
	damage_counter.text = str(damage_taken) + "/" + str(max_hp)
	
	# Update phase indicator
	_update_phase_indicator(health, max_hp)
	
	# Animate damage taken
	_animate_damage_effect()

func _update_phase_indicator(health: int, _max_hp: int):
	match health:
		5:
			phase_indicator.text = "PHASE 1: WALKING"
			phase_indicator.modulate = Color.WHITE
		4:
			phase_indicator.text = "PHASE 2: JUMPING"
			phase_indicator.modulate = Color.YELLOW
		3:
			phase_indicator.text = "PHASE 3: CHARGING"
			phase_indicator.modulate = Color.ORANGE
		2, 1:
			phase_indicator.text = "PHASE 4: FLYING"
			phase_indicator.modulate = Color.RED
		0:
			phase_indicator.text = "DEFEATED!"
			phase_indicator.modulate = Color.GREEN

func _animate_damage_effect():
	# Flash effect when boss takes damage
	var tween = create_tween()
	tween.tween_property(health_bar, "modulate", Color.WHITE, 0.1)
	tween.tween_property(health_bar, "modulate", _get_health_color(), 0.1)
	
	# Shake effect
	var original_pos = position
	for i in range(5):
		tween.tween_property(self, "position", original_pos + Vector2(randf_range(-2, 2), randf_range(-2, 2)), 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)

func _get_health_color() -> Color:
	var health_percentage = (float(current_health) / max_health) * 100
	if health_percentage > 60:
		return Color.GREEN
	elif health_percentage > 30:
		return Color.YELLOW
	else:
		return Color.RED