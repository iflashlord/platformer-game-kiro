extends StaticBody2D
class_name Crate

signal broken(crate_type: String, position: Vector2)
signal crate_destroyed(crate: Crate, points: int)
signal player_bounced(crate: Crate, player: Node2D)

enum CrateState {
	IDLE,
	BOUNCING,
	EXPLODING,
	BROKEN
}

@export var crate_type: String = "basic"
@export var health: int = 1
@export var bounce_force: float = 300.0
@export var break_threshold: float = 200.0
@export var shard_count: int = 6
@export var shard_color: Color = Color.WHITE
@export var points_value: int = 100
@export var hit_points: int = 25

var current_state: CrateState = CrateState.IDLE
var state_timer: float = 0.0
var original_position: Vector2

@onready var sprite: ColorRect = $CrateSprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var area: Area2D = $Area2D
@onready var area_collision: CollisionShape2D = $Area2D/CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# Connect signals
	area.body_entered.connect(_on_area_body_entered)
	area.body_exited.connect(_on_area_body_exited)
	
	# Configure Area2D to monitor bodies
	area.monitoring = true
	area.monitorable = false
	
	# Store original position
	original_position = global_position
	
	# Set initial state
	set_state(CrateState.IDLE)
	
	# Add to crate group
	add_to_group("crates")
	add_to_group("interactive_objects")
	
	print("Crate initialized: ", crate_type)
	print("Area2D monitoring: ", area.monitoring)
	print("Area2D collision mask: ", area.collision_mask)

func _process(delta):
	state_timer += delta
	
	match current_state:
		CrateState.IDLE:
			handle_idle_state(delta)
		CrateState.BOUNCING:
			handle_bouncing_state(delta)
		CrateState.EXPLODING:
			handle_exploding_state(delta)
		CrateState.BROKEN:
			handle_broken_state(delta)

func set_state(new_state: CrateState):
	if current_state == new_state:
		return
	
	# Exit current state
	match current_state:
		CrateState.BOUNCING:
			exit_bouncing_state()
		CrateState.EXPLODING:
			exit_exploding_state()
	
	# Set new state
	current_state = new_state
	state_timer = 0.0
	
	# Enter new state
	match new_state:
		CrateState.IDLE:
			enter_idle_state()
		CrateState.BOUNCING:
			enter_bouncing_state()
		CrateState.EXPLODING:
			enter_exploding_state()
		CrateState.BROKEN:
			enter_broken_state()

func enter_idle_state():
	animation_player.play("idle")

func handle_idle_state(delta):
	# Base idle behavior - can be overridden
	pass

func enter_bouncing_state():
	animation_player.play("bounce")
	print("Crate bouncing: ", crate_type)

func handle_bouncing_state(delta):
	# Return to idle after bounce animation
	if state_timer > 0.5:
		set_state(CrateState.IDLE)

func exit_bouncing_state():
	pass

func enter_exploding_state():
	animation_player.play("explode")
	# Visual effects with fallbacks
	if has_node("/root/FX"):
		if FX.has_method("shake"):
			FX.shake(200)
		if FX.has_method("flash_screen"):
			FX.flash_screen(Color.ORANGE, 0.1)
	else:
		print("FX singleton not found, no visual effects")

func handle_exploding_state(delta):
	# Transition to broken after explosion animation
	if state_timer > 0.3:
		set_state(CrateState.BROKEN)

func exit_exploding_state():
	pass

func enter_broken_state():
	# Hide sprite and disable collision
	sprite.visible = false
	collision_shape.disabled = true
	area_collision.disabled = true
	
	# Add score
	if has_node("/root/Game"):
		Game.add_score(points_value)
		print("Crate destroyed! +", points_value, " points")
	
	# Spawn shards and effects
	spawn_break_effects()
	
	# Emit signals
	broken.emit(crate_type, global_position)
	crate_destroyed.emit(self, points_value)
	
	print("Crate broken: ", crate_type, " at ", global_position)
	
	# Queue for removal
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	add_child(timer)
	timer.start()
	timer.timeout.connect(queue_free)

func handle_broken_state(delta):
	# Already handled in enter_broken_state
	pass

func spawn_break_effects():
	# Spawn shards using object pool (with fallback)
	if has_node("/root/ObjectPool") and ObjectPool.has_method("spawn_shards"):
		ObjectPool.spawn_shards(global_position, shard_count, shard_color)
	else:
		# Fallback: create simple particle effect
		create_simple_break_effect()
	
	# Override in derived classes for specific effects
	spawn_specific_effects()

func create_simple_break_effect():
	# Simple fallback effect when ObjectPool is not available
	for i in shard_count:
		var shard = ColorRect.new()
		shard.size = Vector2(4, 4)
		shard.color = shard_color
		shard.position = global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16))
		get_tree().current_scene.add_child(shard)
		
		# Animate shard
		var tween = create_tween()
		var random_velocity = Vector2(randf_range(-100, 100), randf_range(-200, -50))
		tween.parallel().tween_property(shard, "position", shard.position + random_velocity, 1.0)
		tween.parallel().tween_property(shard, "modulate:a", 0.0, 1.0)
		tween.tween_callback(shard.queue_free)

func spawn_specific_effects():
	# Override in derived classes
	pass

func take_damage(amount: int = 1):
	if current_state == CrateState.BROKEN:
		return
	
	health -= amount
	
	if health <= 0:
		break_crate()
	else:
		# Bounce on damage
		set_state(CrateState.BOUNCING)

func break_crate():
	if current_state != CrateState.BROKEN:
		set_state(CrateState.EXPLODING)

func _on_area_body_entered(body):
	print("🎯 CRATE AREA COLLISION! Body: ", body.name, " (groups: ", body.get_groups(), ")")
	
	# Visual feedback - change crate color when player is near
	sprite.color = Color.YELLOW
	
	if body.is_in_group("player") and current_state != CrateState.BROKEN:
		print("🎯 Valid player detected, calling interaction...")
		# Player touched crate area
		on_player_interaction(body)
	else:
		print("🎯 Invalid body or crate is broken")

func _on_area_body_exited(body):
	print("🎯 Body exited crate area: ", body.name)
	
	# Reset crate color
	sprite.color = Color(0.7, 0.5, 0.3, 1)

func award_hit_points():
	# Add score for hitting the crate
	if has_node("/root/Game"):
		Game.add_score(hit_points)
		print("Crate hit! +", hit_points, " points! New score: ", Game.get_score())
	else:
		print("Game singleton not found, no hit points awarded")
	
	# Create hit effect
	create_hit_effect()

func create_hit_effect():
	# Create floating text effect for hit points
	var effect_label = Label.new()
	effect_label.text = "+" + str(hit_points)
	effect_label.add_theme_font_size_override("font_size", 14)
	effect_label.add_theme_color_override("font_color", Color.CYAN)
	effect_label.position = global_position + Vector2(-10, -25)
	get_tree().current_scene.add_child(effect_label)
	
	# Animate the effect
	var tween = create_tween()
	tween.parallel().tween_property(effect_label, "position", effect_label.position + Vector2(0, -40), 0.8)
	tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(effect_label.queue_free)
	
	# Brief screen flash effect (with fallback if FX singleton doesn't exist)
	if has_node("/root/FX") and FX.has_method("flash_screen"):
		FX.flash_screen(Color.CYAN * 0.2, 0.1)
	else:
		print("FX singleton not found, no screen flash")

func on_player_interaction(player):
	print("Player interacted with crate: ", crate_type)
	print("Player position: ", player.global_position)
	print("Crate position: ", global_position)
	print("Current state: ", current_state)
	
	# Award points for hitting the crate
	award_hit_points()
	
	# Check if player is above the crate (bouncing)
	if player.global_position.y < global_position.y - 5:
		# Player is above, bounce them
		print("Player is above crate, bouncing...")
		if "velocity" in player:
			player.velocity.y = -bounce_force
			print("Set player velocity to: ", player.velocity.y)
		if "is_jumping" in player:
			player.is_jumping = true
		
		player_bounced.emit(self, player)
		set_state(CrateState.BOUNCING)
		print("Player bounced on crate!")
	else:
		# Player hit from side/below, damage crate
		print("Player hit crate from side/below, taking damage...")
		take_damage(1)
