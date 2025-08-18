extends Area2D
class_name FlipGate

@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: CPUParticles2D = $Particles
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var gate_width: float = 64.0
@export var gate_height: float = 128.0
@export var target_layer: String = ""  # "A" or "B", empty for toggle

var activated: bool = false

func _ready():
	# Set up collision detection
	body_entered.connect(_on_body_entered)
	
	# Set collision layers
	collision_layer = 16  # FlipGate layer
	collision_mask = 2    # Player layer
	
	# Setup visual appearance
	sprite.modulate = Color(1, 0.5, 1, 0.8)  # Purple tint
	sprite.scale = Vector2(gate_width / 32, gate_height / 32)
	
	# Setup collision shape
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(gate_width, gate_height)
	collision_shape.shape = rect_shape
	
	# Setup particles
	if particles:
		particles.emitting = true
		particles.amount = 20
		particles.emission_rect_extents = Vector2(gate_width / 2, gate_height / 2)

func _on_body_entered(body):
	if body.is_in_group("player") and not activated:
		_activate_gate(body)

func _activate_gate(player):
	activated = true
	
	# Determine target layer
	var new_layer = target_layer
	if new_layer == "":
		# Toggle current layer
		new_layer = "B" if DimensionManager.current_layer == "A" else "A"
	
	# Force dimension flip
	DimensionManager.set_layer(new_layer)
	
	# Visual feedback
	FX.flash_screen(Color(1, 0.5, 1, 0.3), 0.2)
	FX.hit_stop(60)  # Brief pause
	
	# Audio feedback
	Audio.play_sfx("dimension_gate")
	
	# Particle burst
	if particles:
		particles.amount = 50
		particles.restart()
	
	# Visual effect on gate
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(2, 1, 2, 1), 0.1)
	tween.tween_property(sprite, "modulate", Color(1, 0.5, 1, 0.8), 0.3)
	
	# Reset activation after cooldown
	await get_tree().create_timer(1.0).timeout
	activated = false
	
	print("FlipGate activated - switched to layer: ", new_layer)
