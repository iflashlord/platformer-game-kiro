extends Area2D
class_name JumpPad

signal player_bounced(jump_pad: JumpPad, player: Node2D, force: float)

@export var bounce_force: float = 600.0
@export var pad_type: String = "normal"
@export var cooldown_time: float = 0.5
@export var auto_trigger: bool = true

@export_group("Dimension")
# 0=Both, 1=Only A, 2=Only B (same pattern as HUDVisual)
@export_enum("Both","A","B") var visible_in_dimension: int = 0: set = set_visible_in_dimension

var _current_layer: String = "A"
var _dimension_manager: Node = null

# Cache active collision setup so we can disable/restore based on dimension
var _active_collision_layer: int = 0
var _active_collision_mask: int = 0
var _dim_disabled: bool = false

var is_on_cooldown: bool = false
var cooldown_timer: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var spring_sprite: AnimatedSprite2D = $AnimatedSprite2D

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

	# Cache active collision setup for restoration when toggling dimensions
	_active_collision_layer = collision_layer
	_active_collision_mask = collision_mask

	# Setup DimensionManager hookup (mirrors HUDVisual behavior)
	if _dimension_manager == null:
		_dimension_manager = get_node_or_null("/root/DimensionManager")
	_connect_dimension_manager()
	_update_dimension_visibility()

func _process(delta):
	if is_on_cooldown:
		cooldown_timer += delta
		if cooldown_timer >= cooldown_time:
			reset_cooldown()

func setup_pad_appearance():
	match pad_type:
		"normal":
			spring_sprite.play("default")
			bounce_force = 600.0
	
		"horizontal":
			spring_sprite.play("horizontal_default")
			bounce_force = 400.0
		_:
			spring_sprite.play("horizontal_default")
			bounce_force = 600.0

func _on_body_entered(body):
	# Ignore interactions if not active in current dimension
	if not _is_active_in_current_dimension():
		return
	if body.is_in_group("player") and not is_on_cooldown and auto_trigger:
		activate_jump_pad(body)

func activate_jump_pad(player):
	if is_on_cooldown:
		return
	
	# Apply bounce force based on pad type
	if "velocity" in player:
		match pad_type:
			"horizontal":
				player.velocity.x = bounce_force * (1 if spring_sprite.scale.x > 0 else -1)
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

## Dimension helpers (mirroring HUDVisual behavior)
func _connect_dimension_manager() -> void:
	if _dimension_manager and _dimension_manager.has_signal("layer_changed"):
		if not _dimension_manager.layer_changed.is_connected(_on_layer_changed):
			_dimension_manager.layer_changed.connect(_on_layer_changed)
		if _dimension_manager.has_method("get_current_layer"):
			_current_layer = _dimension_manager.get_current_layer()

func _on_layer_changed(new_layer: String) -> void:
	_current_layer = new_layer
	_update_dimension_visibility()

func set_visible_in_dimension(value: int) -> void:
	visible_in_dimension = value
	_update_dimension_visibility()

func _is_active_in_current_dimension() -> bool:
	if Engine.is_editor_hint():
		return true
	match visible_in_dimension:
		0: # Both
			return true
		1: # A
			return _current_layer == "A"
		2: # B
			return _current_layer == "B"
		_:
			return true

func _update_dimension_visibility() -> void:
	var is_active := _is_active_in_current_dimension()
	# Always show in editor; in-game show only if active
	visible = true if Engine.is_editor_hint() else is_active

	# When disabling for other dimension, snapshot current layers then zero them
	if not is_active:
		if not _dim_disabled:
			_active_collision_layer = collision_layer
			_active_collision_mask = collision_mask
		_dim_disabled = true

		# Disable collision/monitoring so it doesn't trigger out-of-dimension
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
		collision_layer = 0
		collision_mask = 0
		monitoring = false
		return

	# Active dimension: restore only if we previously disabled
	if _dim_disabled:
		if collision_shape:
			collision_shape.set_deferred("disabled", false)
		collision_layer = _active_collision_layer
		collision_mask = _active_collision_mask
		monitoring = true
		_dim_disabled = false

func create_bounce_effect():
	
	match pad_type:
		"normal":
			spring_sprite.play("jump")
	
		"horizontal":
			spring_sprite.play("horizontal_jump")
		_:
			spring_sprite.play("jump")
	
	# Audio feedback
	if Audio:
		Audio.play_sfx("spring")

	# Visual bounce animation
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 0.8), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	
	# Screen shake
	if FX and FX.has_method("shake"):
		FX.shake(100)
	
	# Particle effect (simple color flash)
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(spring_sprite, "modulate", Color.WHITE, 0.1)
 
func start_cooldown():
	is_on_cooldown = true
	cooldown_timer = 0.0
	
	# Visual cooldown indicator
	spring_sprite.modulate = Color(0.6, 0.6, 0.6, 1)

func reset_cooldown():
	is_on_cooldown = false
	cooldown_timer = 0.0
	
	# Restore normal appearance
	setup_pad_appearance()

func set_bounce_direction(direction: Vector2):
	if direction.x > 0:
		pad_type = "horizontal"
		spring_sprite.scale.x = 1

	elif direction.x < 0:
		pad_type = "horizontal"
		spring_sprite.scale.x = -1
	else:
		pad_type = "normal"


func set_bounce_power(power: float):
	bounce_force = power
	if power >= 1000:
		pad_type = "mega"
	elif power >= 800:
		pad_type = "super"
	else:
		pad_type = "normal"
	setup_pad_appearance()
