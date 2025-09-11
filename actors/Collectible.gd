extends Area2D
class_name CollectibleFruit

signal fruit_collected(fruit: CollectibleFruit, points: int) 

@export_enum("coin_bronze", "coin_silver", "coin_gold", "gem_blue", "gem_green", "gem_red", "gem_yellow", "star") var collectable_type: String = "coin_bronze"
@export var points_value: int = 10
@export var float_height: float = 10.0
@export var float_speed: float = 2.0
@export var rotation_speed: float = 1.0

@export_group("Dimension")
@export var target_layer: String = "A"  # For dimension system compatibility
@export var visible_in_both_dimensions: bool = false  # Show in both dimensions A and B

var start_position: Vector2
var time_offset: float
var is_collected: bool = false

# Dimension system compatibility
var dimension_manager: Node
var is_active_in_current_layer: bool = true

@onready var sprite: ColorRect = $FruitSprite
@onready var label: Label = $FruitLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	add_to_group("collectibles")
	add_to_group("fruits")

	start_position = position
	time_offset = randf() * PI * 2

	# Force visibility first
	visible = true
	z_index = 100  # Make sure it's on top

	# Set appearance based on fruit type
	_setup_fruit_appearance()

	# Connect collision
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Set collision layers
	collision_layer = 8  # Collectible layer
	collision_mask = 2   # Player layer

	# Setup dimension system
	if not Engine.is_editor_hint():
		_setup_dimension_system()
# Dimension system methods
func _setup_dimension_system():
	# Only setup dimension system at runtime
	if Engine.is_editor_hint():
		return

	# Find dimension manager
	dimension_manager = get_tree().get_first_node_in_group("dimension_managers")
	if not dimension_manager and has_node("/root/DimensionManager"):
		dimension_manager = get_node("/root/DimensionManager")

	if dimension_manager:
		dimension_manager.layer_changed.connect(_on_layer_changed)
		_update_for_layer(dimension_manager.get_current_layer())

func _on_layer_changed(new_layer: String):
	_update_for_layer(new_layer)

func _update_for_layer(current_layer: String):
	# If visible in both dimensions, always active. Otherwise check target layer.
	is_active_in_current_layer = visible_in_both_dimensions or (current_layer == target_layer)

	# Update visibility and collision based on layer
	visible = is_active_in_current_layer
	collision_layer = 8 if is_active_in_current_layer else 0  # Collectible layer is 8
	collision_mask = 2 if is_active_in_current_layer else 0   # Collide with player layer 2
 
 

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

func _setup_fruit_appearance():
	if not animated_sprite:
		print(" ERROR: AnimatedSprite2D not found!")
		return

	# Play the correct animation for the selected fruit type
	animated_sprite.visible = true
	if Engine.is_editor_hint():
		animated_sprite.animation = collectable_type
	else:
		animated_sprite.play(collectable_type)

	# Set points and label based on type
	match collectable_type:
		"coin_bronze":
			points_value = 10
		"coin_silver":
			points_value = 25
		"coin_gold":
			points_value = 50
		"gem_blue":
			points_value = 60
		"gem_green":
			points_value = 70
		"gem_red":
			points_value = 80
		"gem_yellow":
			points_value = 100
		"star":
			points_value = 150
		_:
			points_value = 10


func _on_body_entered(body):
	print(" Fruit collision detected with: ", body.name, " (groups: ", body.get_groups(), ")")
	if body.is_in_group("player") and not is_collected:
		print(" Valid player collision, collecting fruit")
		collect()
	else:
		print(" Invalid collision or already collected")

func _on_area_entered(area):
	print(" Fruit area collision detected with: ", area.name, " (groups: ", area.get_groups(), ")")
	if area.is_in_group("player") and not is_collected:
		print(" Valid player area collision, collecting fruit")
		collect()
	else:
		print(" Invalid area collision or already collected")

func collect():
	if is_collected:
		print(" Collectable already collected, ignoring")
		return
	
	print(" Starting collection process for ", collectable_type)
	is_collected = true
	
	# Add score
	print(" Adding ", points_value, " points to score")
	if has_node("/root/Game"):
		Game.add_score(points_value)
		print(" New score: ", Game.get_score())
	else:
		print(" Game singleton not found, score not added")
	
	# Emit signal for level tracking
	fruit_collected.emit(self, points_value)
	
	# Create collection effect
	create_collection_effect()
	
	print(" ", collectable_type.capitalize(), " collected! +", points_value, " points")

func _debug_print():
	if not is_collected:
		print(" DEBUG: Fruit still exists at ", global_position, " Visible: ", visible)

func create_collection_effect():
	# Disable collision
	collision_layer = 0
	collision_mask = 0
	
	# Create floating text effect
	var effect_label = Label.new()
	effect_label.text = "+" + str(points_value)
	effect_label.add_theme_font_size_override("font_size", 16)
	effect_label.add_theme_color_override("font_color", Color.BLACK)
	effect_label.position = global_position + Vector2(-15, -30)
	get_tree().current_scene.add_child(effect_label)

	# Animate both the effect label and the fruit, then remove both
	var tween: Tween = create_tween()
	tween.parallel().tween_property(effect_label, "position", effect_label.position + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		effect_label.queue_free()
		queue_free()
	)

	# Audio feedback
	if Audio:
		Audio.play_sfx("collect")

	# # TODO: Use sound based on the type
	# match collectable_type:
	# 	"coin_bronze":
	# 		Audio.play_sfx("collect_coin_bronze")
	# 	"coin_silver":
	# 		Audio.play_sfx("collect_coin_silver")
	# 	"coin_gold":
	# 		Audio.play_sfx("collect_coin_gold")
	# 	"gem_blue":
	# 		Audio.play_sfx("collect_gem_blue")
	# 	"gem_green":
	# 		Audio.play_sfx("collect_gem_green")
	# 	"gem_red":
	# 		Audio.play_sfx("collect_gem_red")
	# 	"gem_yellow":
	# 		Audio.play_sfx("collect_gem_yellow")
	# 	"star":
	# 		Audio.play_sfx("collect_star")
	# 	_:
	# 		Audio.play_sfx("collect")

	# Screen flash effect (with fallback if FX singleton doesn't exist)
	if has_node("/root/FX") and FX.has_method("flash_screen"):
		FX.flash_screen(Color.YELLOW * 0.3, 0.1)
	else:
		print(" FX singleton not found, no screen flash")
 
