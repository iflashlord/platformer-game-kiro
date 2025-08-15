extends Area2D
class_name JumpPad

signal player_bounced(jump_pad: JumpPad, player: Node2D, force: float)

@export var bounce_force: float = 600.0
@export var pad_type: String = "normal"
@export var cooldown_time: float = 0.5
@export var auto_trigger: bool = true

var is_on_cooldown: bool = false
var cooldown_timer: float = 0.0

@onready var sprite: ColorRect = $PadSprite
@onready var label: Label = $PadLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("jump_pads")
	add_to_group("interactive")
	
	# Set appearance based on pad type
	setup_pad_appearance()
	
	# Connect collision
	body_entered.connect(_on_body_entered)
	
	# Set collision layers
	collision_layer = 16  # Interactive layer
	collision_mask = 2    # Player layer

func _process(delta):
	if is_on_cooldown:
		cooldown_timer += delta
		if cooldown_timer >= cooldown_time:
			reset_cooldown()

func setup_pad_appearance():
	match pad_type:
		"normal":
			sprite.color = Color(0.2, 0.8, 0.2, 1)  # Green
			label.text = "⬆️"
			bounce_force = 600.0
		"super":
			sprite.color = Color(0.2, 0.2, 1, 1)  # Blue
			label.text = "⏫"
			bounce_force = 800.0
		"mega":
			sprite.color = Color(1, 0.2, 1, 1)  # Magenta
			label.text = "🚀"
			bounce_force = 1000.0
		"horizontal":
			sprite.color = Color(1, 0.8, 0.2, 1)  # Orange
			label.text = "➡️"
			bounce_force = 400.0
		_:
			sprite.color = Color(0.2, 0.8, 0.2, 1)
			label.text = "⬆️"
			bounce_force = 600.0

func _on_body_entered(body):
	if body.is_in_group("player") and not is_on_cooldown and auto_trigger:
		activate_jump_pad(body)

func activate_jump_pad(player):
	if is_on_cooldown:
		return
	
	# Apply bounce force based on pad type
	if "velocity" in player:
		match pad_type:
			"horizontal":
				player.velocity.x = bounce_force * (1 if sprite.scale.x > 0 else -1)
				player.velocity.y = -200.0  # Small upward boost
			_:
				player.velocity.y = -bounce_force
		
		if "is_jumping" in player:
			player.is_jumping = true
	
	# Emit signal
	player_bounced.emit(self, player, bounce_force)
	
	# Visual and audio feedback
	create_bounce_effect()
	
	# Start cooldown
	start_cooldown()
	
	print("🦘 Jump pad activated! Force: ", bounce_force)

func create_bounce_effect():
	# Visual bounce animation
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 0.8), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	
	# Screen shake
	if FX and FX.has_method("shake"):
		FX.shake(150)
	
	# Particle effect (simple color flash)
	var flash_tween = create_tween()
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	flash_tween.tween_property(sprite, "modulate", sprite.color, 0.2)

func start_cooldown():
	is_on_cooldown = true
	cooldown_timer = 0.0
	
	# Visual cooldown indicator
	sprite.modulate = Color(0.6, 0.6, 0.6, 1)

func reset_cooldown():
	is_on_cooldown = false
	cooldown_timer = 0.0
	
	# Restore normal appearance
	setup_pad_appearance()

func set_bounce_direction(direction: Vector2):
	if direction.x > 0:
		pad_type = "horizontal"
		sprite.scale.x = 1
		label.text = "➡️"
	elif direction.x < 0:
		pad_type = "horizontal"
		sprite.scale.x = -1
		label.text = "⬅️"
	else:
		pad_type = "normal"
		label.text = "⬆️"

func set_bounce_power(power: float):
	bounce_force = power
	if power >= 1000:
		pad_type = "mega"
	elif power >= 800:
		pad_type = "super"
	else:
		pad_type = "normal"
	setup_pad_appearance()