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
	
	# Force visibility first
	visible = true
	modulate = Color.WHITE
	z_index = 100  # Make sure it's on top
	
	# Set appearance based on fruit type
	setup_fruit_appearance()
	
	# Connect collision
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Set collision layers
	collision_layer = 8  # Collectible layer
	collision_mask = 2   # Player layer
	
	# Debug info
	print("🍎 FRUIT CREATED! Position: ", global_position, " Type: ", fruit_type)
	print("🍎 Visible: ", visible, " Modulate: ", modulate, " Z-index: ", z_index)
	print("🍎 Sprite: ", sprite, " Label: ", label)
	print("🍎 Parent: ", get_parent().name if get_parent() else "NO PARENT")
	
	# Add a timer to keep printing position for debugging
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_debug_print)
	add_child(timer)
	timer.start()

func _process(delta):
	if is_collected:
		return
	
	# Simple floating animation
	var time = Time.get_time_dict_from_system()["second"] + time_offset
	position.y = start_position.y + sin(time * float_speed) * float_height
	
	# Gentle rotation
	rotation += rotation_speed * delta
	
	# Gentle scale pulsing
	var pulse = 1.0 + sin(time * float_speed * 2) * 0.1
	scale = Vector2(pulse, pulse)

func setup_fruit_appearance():
	if not sprite or not label:
		print("🍎 ERROR: Sprite or label not found!")
		return
	
	# Make the sprite very visible
	sprite.color = Color.RED
	sprite.visible = true
	
	# Set label text based on fruit type
	match fruit_type:
		"apple":
			sprite.color = Color.RED
			label.text = "A"
			points_value = 50
		"banana":
			sprite.color = Color.YELLOW
			label.text = "B"
			points_value = 60
		"orange":
			sprite.color = Color.ORANGE
			label.text = "O"
			points_value = 70
		"cherry":
			sprite.color = Color(0.8, 0.2, 0.4)
			label.text = "C"
			points_value = 80
		"grape":
			sprite.color = Color.PURPLE
			label.text = "G"
			points_value = 90
		_:
			sprite.color = Color.WHITE
			label.text = "F"
			points_value = 50
	
	# Make label visible
	label.visible = true
	label.add_theme_color_override("font_color", Color.WHITE)
	
	print("🍎 Fruit appearance set: ", fruit_type, " Color: ", sprite.color, " Text: ", label.text)

func _on_body_entered(body):
	print("🍎 Fruit collision detected with: ", body.name, " (groups: ", body.get_groups(), ")")
	if body.is_in_group("player") and not is_collected:
		print("🍎 Valid player collision, collecting fruit")
		collect()
	else:
		print("🍎 Invalid collision or already collected")

func _on_area_entered(area):
	print("🍎 Fruit area collision detected with: ", area.name, " (groups: ", area.get_groups(), ")")
	if area.is_in_group("player") and not is_collected:
		print("🍎 Valid player area collision, collecting fruit")
		collect()
	else:
		print("🍎 Invalid area collision or already collected")

func collect():
	if is_collected:
		print("🍎 Fruit already collected, ignoring")
		return
	
	print("🍎 Starting collection process for ", fruit_type)
	is_collected = true
	
	# Add score
	print("🍎 Adding ", points_value, " points to score")
	if has_node("/root/Game"):
		Game.add_score(points_value)
		print("🍎 New score: ", Game.get_score())
	else:
		print("🍎 Game singleton not found, score not added")
	
	# Emit signal for level tracking
	fruit_collected.emit(self, points_value)
	
	# Create collection effect
	create_collection_effect()
	
	print("🍎 ", fruit_type.capitalize(), " collected! +", points_value, " points")

func _debug_print():
	if not is_collected:
		print("🍎 DEBUG: Fruit still exists at ", global_position, " Visible: ", visible)

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
	
	# Screen flash effect (with fallback if FX singleton doesn't exist)
	if has_node("/root/FX") and FX.has_method("flash_screen"):
		FX.flash_screen(Color.YELLOW * 0.3, 0.1)
	else:
		print("🍎 FX singleton not found, no screen flash")
