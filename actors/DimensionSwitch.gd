extends Area2D
class_name DimensionSwitch

signal dimension_switched(switch: DimensionSwitch, new_layer: String)

@export var switch_type: String = "toggle"  # "toggle" or "specific"
@export var target_layer: String = ""  # For specific switches, empty for toggle
@export var cooldown_time: float = 0.5
@export var blink_duration: float = 2.0  # How long to blink when in cooldown

var is_on_cooldown: bool = false
var cooldown_timer: float = 0.0
var is_blinking: bool = false
var blink_timer: float = 0.0
var player_in_area: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var switch_sprite: ColorRect = $SwitchSprite
@onready var layer_label: Label = $LayerLabel
@onready var graphic: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	add_to_group("dimension_switches")
	add_to_group("interactive")
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set collision layers
	collision_layer = 16  # Interactive layer
	collision_mask = 2    # Player layer
	
	# Setup initial appearance
	setup_switch_appearance()
	
	# Connect to dimension manager
	if DimensionManager:
		DimensionManager.layer_changed.connect(_on_layer_changed)
	
	print("🔄 DimensionSwitch initialized - Type: ", switch_type, " Target: ", target_layer)

func _process(delta):
	# Handle cooldown
	if is_on_cooldown:
		cooldown_timer += delta
		if cooldown_timer >= cooldown_time:
			reset_cooldown()
	
	# Handle blinking during dimension manager cooldown
	if is_blinking:
		blink_timer += delta
		
		# Check if dimension manager cooldown is over
		if DimensionManager and DimensionManager.can_switch_dimension():
			stop_blinking()
		elif blink_timer >= blink_duration:
			stop_blinking()
		else:
			# Create blinking effect
			var blink_alpha = 0.3 + 0.7 * abs(sin(blink_timer * 10))  # Fast blink
			switch_sprite.modulate.a = blink_alpha
			layer_label.modulate.a = blink_alpha

func setup_switch_appearance():
	# Set switch color based on current dimension
	var current_layer = DimensionManager.get_current_layer() if DimensionManager else "A"
	update_visual_state(current_layer)
	
func update_visual_state(current_layer: String):
	# Update label to show current layer
	layer_label.text = current_layer
	layer_label.add_theme_font_size_override("font_size", 24)
	layer_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Set switch color based on layer
	match current_layer:
		"A":
			switch_sprite.color = Color.CYAN
			layer_label.add_theme_color_override("font_color", Color.DARK_BLUE)
			graphic.play("left")
		"B":
			switch_sprite.color = Color.MAGENTA
			layer_label.add_theme_color_override("font_color", Color.DARK_RED)
			graphic.play("right")
		_:
			switch_sprite.color = Color.WHITE
			layer_label.add_theme_color_override("font_color", Color.BLACK)
			graphic.play("default")
	
	# Make switch slightly transparent when not active
	if not player_in_area:
		switch_sprite.modulate.a = 0.7
		layer_label.modulate.a = 0.7
	else:
		switch_sprite.modulate.a = 1.0
		layer_label.modulate.a = 1.0

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_area = true
		print("🔄 Player entered dimension switch area")
		
		# Highlight the switch
		update_visual_state(DimensionManager.get_current_layer() if DimensionManager else "A")
		
		# Try to activate switch
		activate_switch(body)

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_area = false
		print("🔄 Player exited dimension switch area")
		
		# Dim the switch
		update_visual_state(DimensionManager.get_current_layer() if DimensionManager else "A")

func activate_switch(player):
	if is_on_cooldown or not DimensionManager:
		print("🔄 Switch activation blocked - cooldown or no DimensionManager")
		return
	
	# Check if dimension manager allows switching
	if not DimensionManager.can_switch_dimension():
		print("🔄 Switch activation blocked - dimension manager cooldown active")
		start_blinking()
		return
	
	# Determine target layer
	var new_layer: String
	if switch_type == "specific" and target_layer != "":
		new_layer = target_layer
	else:
		# Toggle mode
		var current_layer = DimensionManager.get_current_layer()
		new_layer = "B" if current_layer == "A" else "A"
	
	# Only switch if it's actually changing
	if new_layer == DimensionManager.get_current_layer():
		print("🔄 Already in target layer: ", new_layer)
		return
	
	print("🔄 Activating dimension switch - switching to layer: ", new_layer)
	
	# Trigger dimension switch
	DimensionManager.set_layer(new_layer)
	
	# Emit signal
	dimension_switched.emit(self, new_layer)
	
	# Create activation effect
	create_activation_effect()
	
	# Start local cooldown
	start_cooldown()

func create_activation_effect():
	# Audio feedback
	if Audio:
		Audio.play_sfx("dimension")
	
	# Visual activation animation
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Pulse effect
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	
	# Color flash
	var original_color = switch_sprite.color
	tween.tween_property(switch_sprite, "color", Color.WHITE, 0.1)
	tween.tween_property(switch_sprite, "color", original_color, 0.2)
	
	# Screen shake
	if FX and FX.has_method("screen_shake"):
		FX.screen_shake(0.2, 8.0)

func start_cooldown():
	is_on_cooldown = true
	cooldown_timer = 0.0
	
	# Visual cooldown feedback
	switch_sprite.modulate = Color(0.5, 0.5, 0.5, 0.8)
	layer_label.modulate = Color(0.7, 0.7, 0.7, 0.8)

func reset_cooldown():
	is_on_cooldown = false
	cooldown_timer = 0.0
	
	# Restore normal appearance
	var current_layer = DimensionManager.get_current_layer() if DimensionManager else "A"
	update_visual_state(current_layer)

func start_blinking():
	if is_blinking:
		return
	
	is_blinking = true
	blink_timer = 0.0
	print("🔄 Switch started blinking - dimension manager cooldown active")

func stop_blinking():
	if not is_blinking:
		return
	
	is_blinking = false
	blink_timer = 0.0
	
	# Restore normal appearance
	var current_layer = DimensionManager.get_current_layer() if DimensionManager else "A"
	update_visual_state(current_layer)
	print("🔄 Switch stopped blinking")

func _on_layer_changed(new_layer: String):
	# Update visual state when dimension changes (from any source)
	update_visual_state(new_layer)
	print("🔄 Switch updated for new layer: ", new_layer)

# Public API methods
func set_target_layer(layer: String):
	"""Set specific target layer for this switch"""
	target_layer = layer
	switch_type = "specific"
	setup_switch_appearance()

func set_toggle_mode():
	"""Set switch to toggle between A and B"""
	switch_type = "toggle"
	target_layer = ""
	setup_switch_appearance()

func can_activate() -> bool:
	"""Check if switch can be activated"""
	return not is_on_cooldown and DimensionManager and DimensionManager.can_switch_dimension()