@tool
extends Area2D
class_name CollectableHeart

signal heart_collected(heart: CollectableHeart)

@export var heal_amount: int = 1
@export var float_height: float = 8.0
@export var float_speed: float = 1.5
@export var pulse_speed: float = 2.0
@export var blink_speed: float = 3.0

var start_position: Vector2
var time_offset: float
var is_collected: bool = false
var can_collect: bool = true
var is_blinking: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var label: Label = $HeartLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	# Skip setup in editor mode
	if Engine.is_editor_hint():
		return
		
	add_to_group("collectibles")
	add_to_group("hearts")
	
	start_position = position
	time_offset = randf() * PI * 2
	
	# Force visibility first
	visible = true
	modulate = Color.WHITE
	z_index = 100  # Make sure it's on top
	
	# Set appearance
	setup_heart_appearance()
	
	# Connect collision
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Set collision layers
	collision_layer = 8  # Collectible layer
	collision_mask = 2   # Player layer
	
	# Connect to health system to monitor health changes
	if has_node("/root/HealthSystem"):
		var health_system = get_node("/root/HealthSystem")
		if health_system.has_signal("health_changed"):
			health_system.health_changed.connect(_on_health_changed)
	
	# Check initial collection state
	_update_collection_state()
	
	print("💖 HEART CREATED! Position: ", global_position)

func _process(delta):
	# Skip animation in editor mode
	if Engine.is_editor_hint():
		return
		
	if is_collected:
		return
	
	# Smooth floating animation using get_ticks_msec for better smoothness
	var time = (Time.get_ticks_msec() / 1000.0) + time_offset
	position.y = start_position.y + sin(time * float_speed) * float_height
	
	# Gentle scale pulsing with smoother timing
	var pulse = 1.0 + sin(time * pulse_speed) * 0.1
	scale = Vector2(pulse, pulse)
	
	# Blink if can't collect
	if is_blinking:
		var blink_alpha = 0.3 + 0.7 * (sin(time * blink_speed * 4) + 1) * 0.5
		modulate.a = blink_alpha
	else:
		modulate.a = 1.0

func setup_heart_appearance():
	if not sprite or not label:
		print("💖 ERROR: Sprite or label not found!")
		return
	
	# Use AnimatedSprite2D with user's heart texture
	sprite.visible = true
	sprite.play("default")
	
	# Hide label since we have a proper sprite now
	label.visible = false
	
	print("💖 Heart appearance set")

func _on_body_entered(body):
	print("💖 Heart collision detected with: ", body.name, " (groups: ", body.get_groups(), ")")
	if body.is_in_group("player") and not is_collected and can_collect:
		print("💖 Valid player collision, collecting heart")
		collect()
	else:
		print("💖 Invalid collision, already collected, or can't collect (full health)")

func _on_area_entered(area):
	print("💖 Heart area collision detected with: ", area.name, " (groups: ", area.get_groups(), ")")
	if area.is_in_group("player") and not is_collected and can_collect:
		print("💖 Valid player area collision, collecting heart")
		collect()
	else:
		print("💖 Invalid area collision, already collected, or can't collect (full health)")

func collect():
	if is_collected or not can_collect:
		print("💖 Heart already collected or can't collect (full health)")
		return
	
	print("💖 Starting collection process for heart")
	is_collected = true
	
	# Check HealthSystem availability more thoroughly
	var health_system = null
	if has_node("/root/HealthSystem"):
		health_system = get_node("/root/HealthSystem")
		print("💖 Found HealthSystem node: ", health_system)
	elif HealthSystem:
		health_system = HealthSystem
		print("💖 Using HealthSystem singleton: ", health_system)
	else:
		print("💖 ERROR: No HealthSystem found!")
	
	# Add health through HealthSystem
	var health_added = false
	if health_system:
		print("💖 Health before: ", health_system.get_current_health(), "/", health_system.get_max_health())
		
		if health_system.has_method("gain_heart"):
			health_system.gain_heart()
			health_added = true
			print("💖 ✅ Called gain_heart() successfully")
			print("💖 Health after: ", health_system.get_current_health(), "/", health_system.get_max_health())
		else:
			print("💖 ERROR: HealthSystem doesn't have gain_heart() method!")
			print("💖 Available methods: ", health_system.get_method_list())
	
	if not health_added:
		print("💖 ERROR: Failed to add health!")
	
	# Emit signal for level tracking
	heart_collected.emit(self)
	
	# Create collection effect
	create_collection_effect()
	
	print("💖 Heart collection complete!")

func create_collection_effect():
	# Disable collision
	collision_layer = 0
	collision_mask = 0
	
	# Create floating text effect
	var effect_label = Label.new()
	effect_label.text = "+❤"
	effect_label.add_theme_font_size_override("font_size", 18)
	effect_label.add_theme_color_override("font_color", Color.LIME_GREEN)
	effect_label.position = global_position + Vector2(-15, -30)
	get_tree().current_scene.add_child(effect_label)
	
	# Animate the text effect with proper cleanup - create tween on scene tree
	var text_tween = get_tree().create_tween()
	text_tween.parallel().tween_property(effect_label, "position", effect_label.position + Vector2(0, -50), 0.8)
	text_tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 0.8)
	text_tween.tween_callback(effect_label.queue_free)

	# Audio feedback
	if Audio:
		Audio.play_sfx("collect_heart")
	
	# Animate the heart disappearing with smoother movement
	var item_tween: Tween = create_tween()
	item_tween.set_parallel(true)
	item_tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.15)
	item_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	item_tween.tween_property(self, "position", position + Vector2(0, -20), 0.25)
	item_tween.chain().tween_callback(queue_free)
	
	# Screen flash effect
	if has_node("/root/FX") and FX.has_method("flash_screen"):
		FX.flash_screen(Color.GREEN * 0.3, 0.2)
	else:
		print("💖 FX singleton not found, no screen flash")

func _on_health_changed(current_health: int, max_health: int):
	print("💖 Health changed: ", current_health, "/", max_health)
	_update_collection_state()

func _update_collection_state():
	if is_collected:
		return
		
	# Check if player has full health
	var health_system = null
	if has_node("/root/HealthSystem"):
		health_system = get_node("/root/HealthSystem")
	
	if health_system:
		var current_health = health_system.get_current_health()
		var max_health = health_system.get_max_health()
		
		# Can only collect if not at full health
		can_collect = current_health < max_health
		is_blinking = not can_collect
		
		print("💖 Collection state updated - Can collect: ", can_collect, " (Health: ", current_health, "/", max_health, ")")
	else:
		# Fallback: always allow collection if no health system
		can_collect = true
		is_blinking = false
		print("💖 No health system found, allowing collection")

# Debug method to force collection state
func debug_toggle_collection():
	can_collect = not can_collect
	is_blinking = not can_collect
	print("💖 DEBUG: Toggled collection state - Can collect: ", can_collect)
