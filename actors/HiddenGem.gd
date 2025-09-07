extends Area2D
class_name HiddenGem

## Signal emitted when the gem is collected
signal gem_collected(gem: HiddenGem, points: int)
## Signal emitted when a hidden gem is found
signal hidden_gem_found(gem: HiddenGem)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var glow_particles: CPUParticles2D = $GlowParticles
@onready var collect_particles: CPUParticles2D = $CollectParticles

@export_enum("ruby", "emerald", "diamond", "amethyst", "multicolor") var gem_type = "ruby"
@export var gem_value: int = 50
@export var is_hidden: bool = true

var collected: bool = false
var pulse_time: float = 0.0 
 
func _ready():
	# Add to hidden_gems group for level tracking
	add_to_group("hidden_gems")

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
		scale = Vector2(0.35, 0.35)
		glow_particles.emitting = false

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
			glow_particles.color = Color.RED
			sprite.play("ruby")
			gem_value = 50
		"emerald":
			glow_particles.color = Color.GREEN
			sprite.play("emerald")
			gem_value = 100
		"diamond":
			glow_particles.color = Color.WHITE
			sprite.play("diamond")
			gem_value = 150
		"amethyst":
			glow_particles.color = Color.PURPLE
			sprite.play("amethyst")
			gem_value = 200
		"multicolor":
			glow_particles.color = Color.WHITE
			sprite.play("multicolor")
			gem_value = 250
		_:
			glow_particles.color = Color.RED
			sprite.play("ruby")
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
	tween.parallel().tween_property(self, "scale",  Vector2(0.4, 0.4), 0.3)
	
	# Audio feedback
	Audio.play_sfx("gem_reveal")
	
	# Particle burst
	if glow_particles:
		glow_particles.amount = 20
		glow_particles.emitting = true
		glow_particles.direction = Vector2(0, -1)
		glow_particles.speed_scale = 1.0
		glow_particles.randomness = 0.5
		glow_particles.scale = Vector2(1.5, 1.5)
		glow_particles.restart()

func collect():
	if collected:
		return

	# Set collected state and emit signals
	collected = true
	print("DEBUG: About to emit gem_collected signal...")
	gem_collected.emit(self, gem_value)  # Pass both the gem instance and its value
	print("DEBUG: gem_collected signal emitted")
	hidden_gem_found.emit(self)

	# Add 500 points for hidden gem discovery
	if has_node("/root/Game"):
		Game.add_score(gem_value)
		# Notify base level through the current scene
		var base_level = get_tree().current_scene
		if base_level and base_level is BaseLevel:
			base_level.hidden_gems_collected_count += 1
			print("Hidden gem found! "+ str(gem_value) +" points. Total collected: ", base_level.hidden_gems_collected_count)
		print("New score: ", Game.get_score())
	else:
		print("Game singleton not found, score not added")

	# Notify event bus
	EventBus.notify_collectible_gathered("gem_" + gem_type, global_position)
 
	# Visual feedback
	if collect_particles:
		collect_particles.emitting = true

	# Floating text effect for score
	var effect_label = Label.new()
	effect_label.text = "+" + str(gem_value)
	effect_label.add_theme_font_size_override("font_size", 18)
	effect_label.add_theme_color_override("font_color", Color.BLACK)
	effect_label.position = global_position + Vector2(-15, -30)
	get_tree().current_scene.add_child(effect_label)

	# Collection animation
	var tween = create_tween()
	tween.parallel().tween_property(effect_label, "position", effect_label.position + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func():
		effect_label.queue_free()
		_finish_collection()
	)

	# Audio feedback
	Audio.play_sfx("collect_gem")

	# Screen flash
	FX.flash_screen(sprite.modulate * 0.3, 0.2)

func is_collected() -> bool:
	print("DEBUG: HiddenGem checking collected=", collected, " in is_collected() for gem: ", self)
	return collected

func _finish_collection():
	# Update game statistics
	Game.add_score(gem_value)
	Persistence.update_statistics("gems_collected", 1)

	# Defer removal to allow group counting
	call_deferred("queue_free")

func _on_body_entered(body):
	if body.is_in_group("player") and not collected:
		if is_hidden:
			reveal()
		else:
			collect()
