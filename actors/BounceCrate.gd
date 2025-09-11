extends StaticBody2D
class_name BounceCrate

signal fruit_collected(position: Vector2, fruits_remaining: int, points: int)
signal box_depleted(position: Vector2)

@export var player_bounce_force: float = 300.0
@export var initial_fruit_count: int = 5
@export var bounce_cooldown: float = 0.3
@export var points_per_fruit: int = 75

@export_group("Dimension")
# 0=Both, 1=Only A, 2=Only B (same as HUDVisual)
@export_enum("Both","A","B") var visible_in_dimension: int = 0: set = set_visible_in_dimension

var _current_layer: String = "A"
var _dimension_manager: Node = null

var fruits_remaining: int = 5
var is_bouncing: bool = false
var bounce_timer: float = 0.0

# Remember active-layer collision setup so we can restore it per-dimension
var _active_collision_layer: int = 0
var _active_collision_mask: int = 0
var _active_detection_layer: int = 0
var _active_detection_mask: int = 0
var _dim_disabled: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_collision: CollisionShape2D = $DetectionArea/DetectionCollisionShape2D
@onready var fruit_label: Label = $FruitLabel
@onready var crateSprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready():
	# Connect area signals
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	# Configure Area2D to monitor bodies
	detection_area.monitoring = true
	detection_area.monitorable = false
	
	# Initialize fruit count
	fruits_remaining = initial_fruit_count
	update_display()
	
	if crateSprite:
		crateSprite.play("basic")

	# Add to groups
	add_to_group("fruit_boxes")
	add_to_group("interactive_objects")

	# Cache the active collision setup to restore when visible
	_active_collision_layer = collision_layer
	_active_collision_mask = collision_mask
	if detection_area:
		_active_detection_layer = detection_area.collision_layer
		_active_detection_mask = detection_area.collision_mask

	# Setup dimension manager (same pattern as HUDVisual/TorchLight)
	if _dimension_manager == null:
		_dimension_manager = get_node_or_null("/root/DimensionManager")
	_connect_dimension_manager()
	_update_dimension_visibility()
	
	print("Fruit box initialized with ", fruits_remaining, " fruits")
	print("Detection area monitoring: ", detection_area.monitoring)
	print("Detection area collision mask: ", detection_area.collision_mask)

func _physics_process(delta):
	if is_bouncing:
		bounce_timer += delta
		if bounce_timer >= bounce_cooldown:
			is_bouncing = false
			bounce_timer = 0.0

func _on_detection_area_body_entered(body):
	print("Body entered detection area: ", body.name)
	
	# Ignore interactions if not active in current dimension
	if not _is_active_in_current_dimension():
		return

	# Simple check - if it's a CharacterBody2D (player) and we have fruits
	if body is CharacterBody2D and fruits_remaining > 0 and not is_bouncing:
		print("Player detected! Activating fruit box...")
		
		# For now, always bounce the player up to test basic functionality
		bounce_player_up(body)

func bounce_player_up(player):
	print("Bouncing player up!")
	
	# Set bouncing state
	is_bouncing = true
	bounce_timer = 0.0
	
	# Bounce the player upward
	if "velocity" in player:
		player.velocity.y = -player_bounce_force
		print("Set player velocity to: ", player.velocity.y)
	
	# Set player jumping state if available
	if "is_jumping" in player:
		player.is_jumping = true
	
	# Consume a fruit
	consume_fruit()
	
	
	print("Player bounced on fruit box! Fruits remaining: ", fruits_remaining)

func hit_from_below(player):
	print("Player hit from below!")
	
	# Set bouncing state (no player bounce, just fruit consumption)
	is_bouncing = true
	bounce_timer = 0.0
	
	# Consume a fruit
	consume_fruit()
	 
	print("Player hit fruit box from below! Fruits remaining: ", fruits_remaining)

func consume_fruit():
	if fruits_remaining > 0:
		fruits_remaining -= 1
		update_display()
		
		# Visual bounce effect
		var bounce_tween: Tween = create_tween()
		bounce_tween.parallel().tween_property(self, "scale", Vector2(1.2, 0.8), 0.1)
		bounce_tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
		
		# Audio feedback
		if Audio:
			Audio.play_sfx("collect_gem")

		# Add score
		if has_node("/root/Game"):
			Game.add_score(points_per_fruit)
			print("Added ", points_per_fruit, " points! New score: ", Game.get_score())
		
		# Create collection effect
		create_collection_effect()
		
		# Emit signal for fruit collection
		fruit_collected.emit(global_position, fruits_remaining, points_per_fruit)
		
		print("Fruit consumed! Remaining: ", fruits_remaining, " Points awarded: ", points_per_fruit)
		
		# Check if box is depleted
		if fruits_remaining <= 0:
			deplete_box()

func update_display():
	# Update the number display
	fruit_label.text = str(fruits_remaining)
	
	# Change color based on remaining fruits
	var color_intensity = float(fruits_remaining) / float(initial_fruit_count)

func deplete_box():
	# Box is empty, prepare for removal
	print("Fruit box depleted!")
	
	# Emit depletion signal
	box_depleted.emit(global_position)
	
	# Transform to static block instead of removing
	transform_to_block()
	
	# Disable detection area
	detection_collision.set_deferred("disabled", true)
	detection_area.monitoring = false
	detection_area.monitorable = false

func transform_to_block():
	# Update appearance to basic block
	if crateSprite:
		crateSprite.play("basic_block")
	
	# Keep the original color but darken it
	fruit_label.text = ""
	
	# Set up collision for platform behavior
	collision_shape.disabled = false
	collision_layer = 1  # World/Platform layer
	collision_mask = 2   # Player layer
	
	# Visual transformation effect
	var tween: Tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.parallel().tween_property(self, "modulate", Color(0.4, 0.4, 0.5, 1), 0.2)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Play transformation sound if available
	if Audio:
		Audio.play_sfx("transform_to_block")

func _on_detection_area_body_exited(body):
	print("Body exited detection area: ", body.name)

# Dimension helpers (mirroring HUDVisual behavior)
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
		0:
			return true
		1:
			return _current_layer == "A"
		2:
			return _current_layer == "B"
		_:
			return true

func _update_dimension_visibility() -> void:
	var is_active := _is_active_in_current_dimension()
	visible = true if Engine.is_editor_hint() else is_active

	# When disabling for dimension, snapshot current layers then zero them.
	if not is_active:
		if not _dim_disabled:
			_active_collision_layer = collision_layer
			_active_collision_mask = collision_mask
			if detection_area:
				_active_detection_layer = detection_area.collision_layer
				_active_detection_mask = detection_area.collision_mask
		_dim_disabled = true

		if collision_shape:
			collision_shape.set_deferred("disabled", true)
		collision_layer = 0
		collision_mask = 0

		if detection_area:
			detection_area.monitoring = false
			detection_area.collision_layer = 0
			detection_area.collision_mask = 0
		if detection_collision:
			detection_collision.set_deferred("disabled", true)
		return

	# Active dimension: restore only if we previously disabled
	if _dim_disabled:
		if collision_shape:
			collision_shape.set_deferred("disabled", false)
		collision_layer = _active_collision_layer
		collision_mask = _active_collision_mask

		if detection_area:
			# Only monitor if the crate still has fruits
			detection_area.monitoring = fruits_remaining > 0
			detection_area.collision_layer = _active_detection_layer
			detection_area.collision_mask = _active_detection_mask
		if detection_collision:
			detection_collision.set_deferred("disabled", not (fruits_remaining > 0))
		_dim_disabled = false

func create_collection_effect():
	# Create floating text effect
	var effect_label = Label.new()
	effect_label.text = "+" + str(points_per_fruit)
	effect_label.add_theme_font_size_override("font_size", 16)
	effect_label.add_theme_color_override("font_color", Color.BLACK)
	effect_label.position = global_position + Vector2(-15, -30)
	get_tree().current_scene.add_child(effect_label)
	
	# Create a separate tween node to avoid issues with parent removal
	var tween_node = Node.new()
	get_tree().current_scene.add_child(tween_node)
	var tween = tween_node.create_tween()
	
	# Animate the effect
	tween.parallel().tween_property(effect_label, "position", effect_label.position + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 1.0)
	
	# Clean up both the label and tween node when animation completes
	tween.finished.connect(func(): 
		if is_instance_valid(effect_label):
			effect_label.queue_free()
		if is_instance_valid(tween_node):
			tween_node.queue_free()
	)
	
	# Backup cleanup with timer in case tween fails
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 1.5  # Slightly longer than tween duration
	cleanup_timer.one_shot = true
	get_tree().current_scene.add_child(cleanup_timer)
	cleanup_timer.start()
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(effect_label):
			effect_label.queue_free()
		if is_instance_valid(tween_node):
			tween_node.queue_free()
		cleanup_timer.queue_free()
	)
 
	# Screen flash effect (with fallback if FX singleton doesn't exist)
	if has_node("/root/FX") and FX.has_method("flash_screen"):
		FX.flash_screen(Color.ORANGE * 0.3, 0.1)
	else:
		print("FX singleton not found, no screen flash")
