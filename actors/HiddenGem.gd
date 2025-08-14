extends Area2D
class_name HiddenGem

@onready var sprite: ColorRect = $GemSprite
@onready var glow_particles: CPUParticles2D = $GlowParticles
@onready var collect_particles: CPUParticles2D = $CollectParticles

@export var gem_type: String = "ruby"
@export var gem_value: int = 100
@export var is_hidden: bool = true

var collected: bool = false
var pulse_time: float = 0.0

signal gem_collected(gem: HiddenGem)

func _ready():
	# Set up collision detection
	body_entered.connect(_on_body_entered)
	
	# Set collision layers
	collision_layer = 8   # Collectible layer
	collision_mask = 2    # Player layer
	
	# Setup appearance based on gem type
	_setup_gem_appearance()
	
	# Start with hidden state
	if is_hidden:
		modulate.a = 0.3
		scale = Vector2(0.8, 0.8)

func _physics_process(delta):
	if not collected:
		# Gentle pulsing animation
		pulse_time += delta * 2.0
		var pulse = sin(pulse_time) * 0.1 + 1.0
		sprite.scale = Vector2(pulse, pulse)
		
		# Floating motion
		var float_offset = sin(pulse_time * 0.5) * 5.0
		sprite.position.y = float_offset

func _setup_gem_appearance():
	match gem_type:
		"ruby":
			sprite.modulate = Color.RED
			gem_value = 100
		"emerald":
			sprite.modulate = Color.GREEN
			gem_value = 150
		"sapphire":
			sprite.modulate = Color.BLUE
			gem_value = 200
		"diamond":
			sprite.modulate = Color.WHITE
			gem_value = 300
		"amethyst":
			sprite.modulate = Color.PURPLE
			gem_value = 250
		_:
			sprite.modulate = Color.YELLOW
			gem_value = 50
	
	# Setup glow particles to match gem color
	if glow_particles:
		glow_particles.color = sprite.modulate
		glow_particles.emitting = true

func reveal():
	if not is_hidden:
		return
	
	is_hidden = false
	
	# Reveal animation
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.5)
	
	# Audio feedback
	Audio.play_sfx("gem_reveal")
	
	# Particle burst
	if glow_particles:
		glow_particles.amount = 30
		glow_particles.restart()

func collect():
	if collected:
		return
	
	collected = true
	gem_collected.emit(self)
	
	# Notify event bus
	EventBus.notify_collectible_gathered("gem_" + gem_type, global_position)
	
	# Visual feedback
	if collect_particles:
		collect_particles.emitting = true
	
	# Collection animation
	var tween = create_tween()
	tween.parallel().tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(_finish_collection)
	
	# Audio feedback
	Audio.play_sfx("collect_gem")
	
	# Screen flash
	FX.flash_screen(sprite.modulate * 0.3, 0.2)

func _finish_collection():
	# Update game statistics
	Game.add_score(gem_value)
	Persistence.update_statistics("gems_collected", 1)
	
	# Remove from scene
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player") and not collected:
		if is_hidden:
			reveal()
		else:
			collect()
