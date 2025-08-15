extends Area2D
class_name DangerousSpike

signal player_damaged(spike: DangerousSpike, player: Node2D, damage: int)

@export var damage_amount: int = 1
@export var spike_direction: Vector2 = Vector2.UP
@export var retract_on_hit: bool = false
@export var retract_time: float = 2.0
@export var auto_retract_cycle: bool = false
@export var cycle_time: float = 3.0

var is_extended: bool = true
var is_retracting: bool = false
var retract_timer: float = 0.0
var cycle_timer: float = 0.0

@onready var sprite: ColorRect = $SpikeSprite
@onready var label: Label = $SpikeLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("hazards")
	add_to_group("spikes")
	
	# Set appearance based on direction
	setup_spike_appearance()
	
	# Connect collision
	body_entered.connect(_on_body_entered)
	
	# Set collision layers
	collision_layer = 32  # Hazard layer
	collision_mask = 2    # Player layer

func _process(delta):
	# Handle retraction timer
	if is_retracting:
		retract_timer += delta
		if retract_timer >= retract_time:
			extend_spike()
	
	# Handle auto cycle
	if auto_retract_cycle:
		cycle_timer += delta
		if cycle_timer >= cycle_time:
			cycle_timer = 0.0
			if is_extended:
				retract_spike()
			else:
				extend_spike()

func setup_spike_appearance():
	# Set color based on danger level
	match damage_amount:
		1:
			sprite.color = Color(0.6, 0.6, 0.6, 1)  # Gray
		2:
			sprite.color = Color(0.8, 0.4, 0.4, 1)  # Red
		3:
			sprite.color = Color(0.4, 0.4, 0.8, 1)  # Blue (deadly)
		_:
			sprite.color = Color(0.6, 0.6, 0.6, 1)
	
	# Set spike emoji based on direction
	if spike_direction == Vector2.UP:
		label.text = "🔺"
		rotation = 0
	elif spike_direction == Vector2.DOWN:
		label.text = "🔻"
		rotation = PI
	elif spike_direction == Vector2.LEFT:
		label.text = "◀️"
		rotation = -PI/2
	elif spike_direction == Vector2.RIGHT:
		label.text = "▶️"
		rotation = PI/2
	else:
		label.text = "🔺"

func _on_body_entered(body):
	if body.is_in_group("player") and is_extended:
		damage_player(body)

func damage_player(player):
	# Apply damage through HealthSystem
	if HealthSystem and HealthSystem.has_method("take_damage"):
		HealthSystem.take_damage(damage_amount)
	elif player.has_method("take_damage"):
		player.take_damage(damage_amount)
	
	# Emit signal
	player_damaged.emit(self, player, damage_amount)
	
	# Visual feedback
	create_damage_effect()
	
	# Retract if configured
	if retract_on_hit:
		retract_spike()
	
	print("🔺 Spike damaged player for ", damage_amount, " damage")

func create_damage_effect():
	# Screen flash
	if FX and FX.has_method("flash_screen"):
		FX.flash_screen(Color.RED, 0.2)
	
	# Screen shake
	if FX and FX.has_method("shake"):
		FX.shake(150)
	
	# Damage number effect
	var damage_label = Label.new()
	damage_label.text = "-" + str(damage_amount)
	damage_label.add_theme_font_size_override("font_size", 16)
	damage_label.add_theme_color_override("font_color", Color.RED)
	damage_label.position = global_position + Vector2(-10, -30)
	get_tree().current_scene.add_child(damage_label)
	
	# Animate damage number
	var tween = create_tween()
	tween.parallel().tween_property(damage_label, "position", damage_label.position + Vector2(0, -40), 0.8)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(damage_label.queue_free)

func retract_spike():
	if not is_extended or is_retracting:
		return
	
	is_extended = false
	is_retracting = true
	retract_timer = 0.0
	
	# Visual retraction
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 0.3), 0.2)
	
	# Disable collision temporarily
	collision_shape.disabled = true
	
	print("🔺 Spike retracted")

func extend_spike():
	is_extended = true
	is_retracting = false
	
	# Visual extension
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	
	# Re-enable collision
	collision_shape.disabled = false
	
	print("🔺 Spike extended")

func set_damage(new_damage: int):
	damage_amount = new_damage
	setup_spike_appearance()

func set_auto_cycle(enabled: bool, cycle_duration: float = 3.0):
	auto_retract_cycle = enabled
	cycle_time = cycle_duration
	cycle_timer = 0.0