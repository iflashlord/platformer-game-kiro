extends Area2D
class_name CollectibleGem

signal gem_collected(gem: CollectibleGem, points: int)

@export var gem_type: String = "ruby"
@export var points_value: int = 200
@export var is_hidden: bool = false
@export var float_height: float = 8.0
@export var float_speed: float = 1.5
@export var sparkle_speed: float = 3.0

var start_position: Vector2
var time_offset: float
var is_collected: bool = false
var is_revealed: bool = false

@onready var sprite: ColorRect = $GemSprite
@onready var label: Label = $GemLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("collectibles")
	add_to_group("gems")
	
	start_position = position
	time_offset = randf() * PI * 2
	
	# Set appearance based on gem type
	setup_gem_appearance()
	
	# Handle hidden state
	if is_hidden:
		modulate.a = 0.3
		scale = Vector2(0.8, 0.8)
		is_revealed = false
	else:
		is_revealed = true
	
	# Connect collision
	body_entered.connect(_on_body_entered)
	
	# Set collision layers
	collision_layer = 8  # Collectible layer
	collision_mask = 2   # Player layer

func _process(delta):
	if is_collected:
		return
	
	# Floating animation
	var time = Time.get_time_dict_from_system()["second"] + time_offset
	position.y = start_position.y + sin(time * float_speed) * float_height
	
	# Sparkle effect
	var sparkle = 1.0 + sin(time * sparkle_speed) * 0.2
	sprite.scale = Vector2(sparkle, sparkle)

func setup_gem_appearance():
	match gem_type:
		"ruby":
			sprite.color = Color(1, 0, 0, 0.8)
			label.text = "💎"
			points_value = 200
		"emerald":
			sprite.color = Color(0, 1, 0, 0.8)
			label.text = "💎"
			points_value = 250
		"sapphire":
			sprite.color = Color(0, 0, 1, 0.8)
			label.text = "💎"
			points_value = 300
		"diamond":
			sprite.color = Color(1, 1, 1, 0.9)
			label.text = "💎"
			points_value = 500
		"amethyst":
			sprite.color = Color(1, 0, 1, 0.8)
			label.text = "💎"
			points_value = 350
		_:
			sprite.color = Color(1, 0, 0, 0.8)
			label.text = "💎"
			points_value = 200

func _on_body_entered(body):
	if body.is_in_group("player") and not is_collected:
		if is_hidden and not is_revealed:
			reveal()
		else:
			collect()

func reveal():
	if is_revealed:
		return
	
	is_revealed = true
	print("✨ Hidden gem revealed!")
	
	# Reveal animation
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.5)
	
	# Sparkle effect
	if FX and FX.has_method("flash_screen"):
		FX.flash_screen(sprite.color * 0.3, 0.2)

func collect():
	if is_collected:
		return
	
	is_collected = true
	
	# Add score
	Game.add_score(points_value)
	
	# Emit signal for level tracking
	gem_collected.emit(self, points_value)
	
	# Create collection effect
	create_collection_effect()
	
	print("💎 ", gem_type.capitalize(), " gem collected! +", points_value, " points")

func create_collection_effect():
	# Disable collision
	collision_layer = 0
	collision_mask = 0
	
	# Create floating text effect
	var effect_label = Label.new()
	effect_label.text = "+" + str(points_value)
	effect_label.add_theme_font_size_override("font_size", 18)
	effect_label.add_theme_color_override("font_color", Color.CYAN)
	effect_label.position = global_position + Vector2(-20, -35)
	get_tree().current_scene.add_child(effect_label)
	
	# Animate the effect
	var tween = create_tween()
	tween.parallel().tween_property(effect_label, "position", effect_label.position + Vector2(0, -60), 1.2)
	tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 1.2)
	tween.tween_callback(effect_label.queue_free)
	
	# Animate the gem disappearing with sparkle
	var item_tween = create_tween()
	item_tween.parallel().tween_property(self, "scale", Vector2(2.0, 2.0), 0.3)
	item_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
	item_tween.tween_callback(queue_free)
	
	# Screen flash effect
	if FX and FX.has_method("flash_screen"):
		FX.flash_screen(sprite.color * 0.4, 0.2)