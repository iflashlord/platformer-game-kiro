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
	
	# Force visibility first
	visible = true
	if not is_hidden:
		modulate = Color.WHITE
	z_index = 100  # Make sure it's on top
	
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
	area_entered.connect(_on_area_entered)
	
	# Set collision layers
	collision_layer = 8  # Collectible layer
	collision_mask = 2   # Player layer
	
	# Debug info
	print("💎 GEM CREATED! Position: ", global_position, " Type: ", gem_type)
	print("💎 Visible: ", visible, " Modulate: ", modulate, " Z-index: ", z_index)
	print("💎 Sprite: ", sprite, " Label: ", label)
	print("💎 Parent: ", get_parent().name if get_parent() else "NO PARENT")
	
	# Add a timer to keep printing position for debugging
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_debug_print)
	add_child(timer)
	timer.start()

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
	if not sprite or not label:
		print("💎 ERROR: Sprite or label not found!")
		return
	
	# Make the sprite very visible
	sprite.visible = true
	
	# Set label text based on gem type
	match gem_type:
		"ruby":
			sprite.color = Color(1, 0, 0, 0.8)
			label.text = "R"
			points_value = 200
		"emerald":
			sprite.color = Color(0, 1, 0, 0.8)
			label.text = "E"
			points_value = 250
		"sapphire":
			sprite.color = Color(0, 0, 1, 0.8)
			label.text = "S"
			points_value = 300
		"diamond":
			sprite.color = Color(1, 1, 1, 0.9)
			label.text = "D"
			points_value = 500
		"amethyst":
			sprite.color = Color(1, 0, 1, 0.8)
			label.text = "A"
			points_value = 350
		_:
			sprite.color = Color(1, 0, 0, 0.8)
			label.text = "G"
			points_value = 200
	
	# Make label visible
	label.visible = true
	label.add_theme_color_override("font_color", Color.WHITE)
	
	print("💎 Gem appearance set: ", gem_type, " Color: ", sprite.color, " Text: ", label.text)

func _on_body_entered(body):
	print("💎 Gem collision detected with: ", body.name, " (groups: ", body.get_groups(), ")")
	if body.is_in_group("player") and not is_collected:
		if is_hidden and not is_revealed:
			print("💎 Hidden gem detected, revealing...")
			reveal()
		else:
			print("💎 Valid player collision, collecting gem")
			collect()
	else:
		print("💎 Invalid collision or already collected")

func _on_area_entered(area):
	print("💎 Gem area collision detected with: ", area.name, " (groups: ", area.get_groups(), ")")
	if area.is_in_group("player") and not is_collected:
		if is_hidden and not is_revealed:
			print("💎 Hidden gem detected via area, revealing...")
			reveal()
		else:
			print("💎 Valid player area collision, collecting gem")
			collect()
	else:
		print("💎 Invalid area collision or already collected")

func reveal():
	if is_revealed:
		return
	
	is_revealed = true
	print("✨ Hidden gem revealed!")
	
	# Reveal animation
	var tween: Tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.5)
	
	# Sparkle effect
	if FX and FX.has_method("flash_screen"):
		FX.flash_screen(sprite.color * 0.3, 0.2)

func collect():
	if is_collected:
		print("💎 Gem already collected, ignoring")
		return
	
	print("💎 Starting collection process for ", gem_type)
	is_collected = true
	
	# Add score
	print("💎 Adding ", points_value, " points to score")
	if has_node("/root/Game"):
		Game.add_score(points_value)
		print("💎 New score: ", Game.get_score())
	else:
		print("💎 Game singleton not found, score not added")
	
	# Emit signal for level tracking
	gem_collected.emit(self, points_value)
	
	# Create collection effect
	create_collection_effect()
	
	print("💎 ", gem_type.capitalize(), " gem collected! +", points_value, " points")

func _debug_print():
	if not is_collected:
		print("💎 DEBUG: Gem still exists at ", global_position, " Visible: ", visible)

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
	var tween: Tween = create_tween()
	tween.parallel().tween_property(effect_label, "position", effect_label.position + Vector2(0, -60), 1.2)
	tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 1.2)
	tween.tween_callback(effect_label.queue_free)
	
	# Animate the gem disappearing with sparkle
	var item_tween: Tween = create_tween()
	item_tween.parallel().tween_property(self, "scale", Vector2(2.0, 2.0), 0.3)
	item_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
	item_tween.tween_callback(queue_free)
	
	# Screen flash effect (with fallback if FX singleton doesn't exist)
	if has_node("/root/FX") and FX.has_method("flash_screen"):
		FX.flash_screen(sprite.color * 0.4, 0.2)
	else:
		print("💎 FX singleton not found, no screen flash")
