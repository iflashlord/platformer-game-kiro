extends StaticBody2D
class_name Spike

# Signals
signal player_damaged(player: Player)
signal spike_destroyed
signal spike_warning

# Basic Properties
@export_group("Damage")
@export var damage: int = 1
@export var damage_type: String = "spike"
@export var knockback_force: float = 200.0
@export var can_be_destroyed: bool = false
@export var spike_health: int = 3

@export_group("Movement")
@export var auto_scroll_speed: float = 0.0
@export var spike_direction: Vector2 = Vector2.UP

@export_group("Behavior")
@export var retract_on_hit: bool = false
@export var retract_time: float = 2.0
@export var warning_time: float = 1.0
@export var show_warning: bool = true
@export var auto_extend_cycle: bool = false
@export var cycle_time: float = 3.0

@export_group("Visual")
@export var spike_size: Vector2 = Vector2(24, 32)
@export var custom_color: Color = Color.WHITE
@export var use_direction_colors: bool = true
@export var glow_intensity: float = 1.0

@export_group("Audio")
@export var damage_sound: String = "spike_hit"
@export var extend_sound: String = "spike_extend"
@export var retract_sound: String = "spike_retract"
@export var warning_sound: String = "spike_warning"

@export_group("Effects")
@export var blood_particles: bool = true
@export var screen_shake: bool = true
@export var flash_screen: bool = true

# Internal state
var is_extended: bool = true
var is_retracting: bool = false
var is_warning: bool = false
var retract_timer: float = 0.0
var cycle_timer: float = 0.0
var warning_timer: float = 0.0
var current_health: int
var original_color: Color

@onready var spike_sprite: ColorRect = $SpikeSprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_area: Area2D = $DamageArea
@onready var damage_collision: CollisionShape2D = $DamageArea/CollisionShape2D
@onready var dimension_node: DimensionNode = $DimensionNode
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# Initialize health
	current_health = spike_health
	
	# Add to groups
	add_to_group("hazards")
	add_to_group("spikes")
	if can_be_destroyed:
		add_to_group("destructible_hazards")
	
	# Connect signals
	if damage_area:
		damage_area.body_entered.connect(_on_player_entered)
		if can_be_destroyed:
			damage_area.area_entered.connect(_on_area_entered)
	
	# Setup appearance and collision
	setup_spike_appearance()
	setup_collision_sizes()
	
	# Start behavior
	if auto_extend_cycle:
		start_warning_cycle()
	elif animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")

func _physics_process(delta):
	# Handle auto-scroll movement
	if auto_scroll_speed != 0.0:
		global_position.x += auto_scroll_speed * delta
	
	# Handle warning state
	if is_warning:
		warning_timer += delta
		if warning_timer >= warning_time:
			complete_warning()
	
	# Handle retraction
	if is_retracting:
		retract_timer += delta
		if retract_timer >= retract_time:
			extend_spike()
	
	# Handle auto cycle
	if auto_extend_cycle and is_extended and not is_retracting:
		cycle_timer += delta
		if cycle_timer >= cycle_time:
			start_warning_cycle()

func setup_spike_appearance():
	"""Setup spike visual appearance based on direction and settings"""
	if not spike_sprite:
		return
	
	# Set rotation based on direction
	match spike_direction:
		Vector2.UP:
			spike_sprite.rotation = 0
		Vector2.DOWN:
			spike_sprite.rotation = PI
		Vector2.LEFT:
			spike_sprite.rotation = -PI / 2
		Vector2.RIGHT:
			spike_sprite.rotation = PI / 2
	
	# Set color
	if custom_color != Color.WHITE:
		original_color = custom_color
		spike_sprite.color = custom_color
	elif use_direction_colors:
		match spike_direction:
			Vector2.UP:
				original_color = Color(0.8, 0.2, 0.2, 1) # Red for up-facing spikes
			Vector2.DOWN:
				original_color = Color(0.2, 0.8, 0.2, 1) # Green for down-facing spikes
			Vector2.LEFT:
				original_color = Color(0.2, 0.2, 0.8, 1) # Blue for left-facing spikes
			Vector2.RIGHT:
				original_color = Color(0.8, 0.8, 0.2, 1) # Yellow for right-facing spikes
			_:
				original_color = Color(0.8, 0.2, 0.2, 1) # Default red
		spike_sprite.color = original_color
	else:
		original_color = Color(0.8, 0.2, 0.2, 1)
		spike_sprite.color = original_color

func setup_collision_sizes():
	"""Setup collision shapes based on spike size"""
	if collision_shape and collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = spike_size
	
	if damage_collision and damage_collision.shape is RectangleShape2D:
		damage_collision.shape.size = spike_size + Vector2(4, 4) # Slightly larger damage area

func _on_player_entered(body):
	if body is Player and is_extended:
		damage_player(body)

func _on_area_entered(area):
	"""Handle projectiles or other damaging areas hitting the spike"""
	if not can_be_destroyed:
		return
		
	# Check if it's a player projectile/attack
	var source = area.get_parent()
	if source and (source.is_in_group("projectiles") or source.is_in_group("player_attacks")):
		take_damage(1)

func damage_player(player: Player):
	player_damaged.emit(player)
	
	# Apply knockback
	if knockback_force > 0 and player.has_method("apply_knockback"):
		var knockback_dir = (player.global_position - global_position).normalized()
		player.apply_knockback(knockback_dir * knockback_force)
	
	# Damage the player
	if player.has_method("take_damage"):
		player.take_damage(damage)
	elif player.has_method("die"):
		player.die()
	
	# Visual and audio feedback
	_play_damage_effects()
	_play_sound(damage_sound)
	
	# Retract if configured
	if retract_on_hit:
		retract_spike()
	
	print("Spike damaged player for ", damage, " damage")

func take_damage(amount: int):
	"""Allow the spike to be damaged if destructible"""
	if not can_be_destroyed:
		return
	
	current_health -= amount
	_flash_damage()
	_play_sound("spike_damaged")
	
	if current_health <= 0:
		destroy_spike()
	
	print("Spike took ", amount, " damage. Health: ", current_health, "/", spike_health)

func destroy_spike():
	"""Destroy the spike"""
	spike_destroyed.emit()
	_play_sound("spike_destroyed")
	_create_destruction_effect()
	queue_free()

func start_warning_cycle():
	"""Start warning before extending/retracting"""
	if not show_warning or is_warning:
		return
	
	is_warning = true
	warning_timer = 0.0
	cycle_timer = 0.0
	
	spike_warning.emit()
	_play_sound(warning_sound)
	_animate_warning()
	
	print("Spike warning started")

func complete_warning():
	"""Complete warning and perform action"""
	is_warning = false
	warning_timer = 0.0
	
	if is_extended:
		retract_spike()
	else:
		extend_spike()

func retract_spike():
	if not is_extended or is_retracting:
		return
	
	is_extended = false
	is_retracting = true
	retract_timer = 0.0
	
	# Play sound
	_play_sound(retract_sound)
	
	# Visual retraction
	if animation_player and animation_player.has_animation("retract"):
		animation_player.play("retract")
	else:
		_animate_retract()
	
	# Disable collision temporarily
	if collision_shape:
		collision_shape.disabled = true
	if damage_collision:
		damage_collision.disabled = true

func extend_spike():
	is_extended = true
	is_retracting = false
	
	# Play sound
	_play_sound(extend_sound)
	
	# Visual extension
	if animation_player and animation_player.has_animation("extend"):
		animation_player.play("extend")
	else:
		_animate_extend()
	
	# Re-enable collision
	if collision_shape:
		collision_shape.disabled = false
	if damage_collision:
		damage_collision.disabled = false

func set_auto_scroll_speed(speed: float):
	auto_scroll_speed = speed

func is_spike_extended() -> bool:
	return is_extended

func _animate_retract():
	"""Fallback visual retraction animation"""
	if not spike_sprite:
		return
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(spike_sprite, "scale", Vector2(0.5, 0.5), 0.3)
	tween.parallel().tween_property(spike_sprite, "modulate:a", 0.5, 0.3)

func _animate_extend():
	"""Fallback visual extension animation"""
	if not spike_sprite:
		return
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(spike_sprite, "scale", Vector2(1.0, 1.0), 0.2)
	tween.parallel().tween_property(spike_sprite, "modulate:a", 1.0, 0.2)

func _animate_warning():
	"""Visual warning animation"""
	if not spike_sprite:
		return
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(spike_sprite, "modulate", Color.YELLOW, 0.2)
	tween.tween_property(spike_sprite, "modulate", original_color, 0.2)

func _play_damage_effects():
	"""Play visual effects when damaging player"""
	# Screen shake
	if screen_shake and FX and FX.has_method("shake"):
		FX.shake(100)
	
	# Screen flash
	if flash_screen and FX and FX.has_method("flash_screen"):
		FX.flash_screen(Color.RED, 0.1)
	
	# Blood particles
	if blood_particles:
		_create_blood_particles()

func _play_sound(sound_name: String):
	"""Play sound effect"""
	if sound_name != "" and Audio and Audio.has_method("play_sfx"):
		Audio.play_sfx(sound_name)

func _flash_damage():
	"""Flash red when taking damage"""
	if not spike_sprite:
		return
	
	var tween = create_tween()
	tween.tween_property(spike_sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(spike_sprite, "modulate", original_color, 0.1)

func _create_blood_particles():
	"""Create blood particle effect"""
	if not FX or not FX.has_method("create_particles"):
		return
	
	FX.create_particles("blood", global_position, 10)

func _create_destruction_effect():
	"""Create destruction particle effect"""
	if not FX:
		return
	
	if FX.has_method("create_particles"):
		FX.create_particles("spike_debris", global_position, 15)
	
	if FX.has_method("shake"):
		FX.shake(150)
