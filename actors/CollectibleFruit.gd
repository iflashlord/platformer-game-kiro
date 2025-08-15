extends Area2D
class_name CollectibleFruit

signal fruit_collected(fruit: CollectibleFruit, points: int)

@export var fruit_type: String = "apple"
@export var points_value: int = 50
@export var float_height: float = 10.0
@export var float_speed: float = 2.0
@export var rotation_speed: float = 1.0

var start_position: Vector2
var time_offset: float
var is_collected: bool = false

@onready var sprite: ColorRect = $FruitSprite
@onready var label: Label = $FruitLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("collectibles")
	add_to_group("fruits")
	
	start_position = position
	time_offset = randf() * PI * 2
	
	# Set appearance based on fruit type
	setup_fruit_appearance()
	
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
	
	# Gentle rotation
	rotation += rotation_speed * delta
	
	# Gentle scale pulsing
	var pulse = 1.0 + sin(time * float_speed * 2) * 0.1
	scale = Vector2(pulse, pulse)

func setup_fruit_appearance():
	match fruit_type:
		"apple":
			sprite.color = Color.RED
			label.text = "🍎"
			points_value = 50
		"banana":
			sprite.color = Color.YELLOW
			label.text = "🍌"
			points_value = 60
		"orange":
			sprite.color = Color.ORANGE
			label.text = "🍊"
			points_value = 70
		"cherry":
			sprite.color = Color(0.8, 0.2, 0.4)
			label.text = "🍒"
			points_value = 80
		"grape":
			sprite.color = Color.PURPLE
			label.text = "🍇"
			points_value = 90
		_:
			sprite.color = Color.WHITE
			label.text = "🍎"
			points_value = 50

func _on_body_entered(body):
	print("🍎 Fruit collision detected with: ", body.name, " (groups: ", body.get_groups(), ")")
	if body.is_in_group("player") and not is_collected:
		print("🍎 Valid player collision, collecting fruit")
		collect()
	else:
		print("🍎 Invalid collision or already collected")

func collect():
	if is_collected:
		print("🍎 Fruit already collected, ignoring")
		return
	
	print("🍎 Starting collection process for ", fruit_type)
	is_collected = true
	
	# Add score
	print("🍎 Adding ", points_value, " points to score")
	Game.add_score(points_value)
	print("🍎 New score: ", Game.get_score())
	
	# Emit signal for level tracking
	fruit_collected.emit(self, points_value)
	
	# Create collection effect
	create_collection_effect()
	
	print("🍎 ", fruit_type.capitalize(), " collected! +", points_value, " points")

func create_collection_effect():
	# Disable collision
	collision_layer = 0
	collision_mask = 0
	
	# Create floating text effect
	var effect_label = Label.new()
	effect_label.text = "+" + str(points_value)
	effect_label.add_theme_font_size_override("font_size", 16)
	effect_label.add_theme_color_override("font_color", Color.YELLOW)
	effect_label.position = global_position + Vector2(-15, -30)
	get_tree().current_scene.add_child(effect_label)
	
	# Animate the effect
	var tween = create_tween()
	tween.parallel().tween_property(effect_label, "position", effect_label.position + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(effect_label.queue_free)
	
	# Animate the fruit disappearing
	var item_tween = create_tween()
	item_tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	item_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	item_tween.tween_callback(queue_free)
	
	# Screen flash effect
	if FX and FX.has_method("flash_screen"):
		FX.flash_screen(Color.YELLOW * 0.3, 0.1)