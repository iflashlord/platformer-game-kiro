extends Area2D
class_name CollectibleFruit

enum FruitType {
	APPLE,
	BANANA,
	CHERRY,
	ORANGE,
	GRAPE
}

@export var fruit_type: FruitType = FruitType.APPLE
@export var score_value: int = 10
@export var magnetic_range: float = 60.0
@export var magnetic_speed: float = 300.0

var is_collected: bool = false
var is_magnetic: bool = false
var target_player = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collect_particles: CPUParticles2D = $CollectParticles

func _ready():
	# Add to collectibles group
	add_to_group("collectibles")
	add_to_group("fruits")
	
	# Connect collision signal
	body_entered.connect(_on_body_entered)
	
	# Set fruit appearance based on type
	setup_fruit_type()
	
	# Start bounce animation
	animation_player.play("bounce")

func _physics_process(delta):
	if is_collected:
		return
	
	# Check for nearby player for magnetic collection
	if not is_magnetic:
		var player = get_tree().get_first_node_in_group("player")
		if player and global_position.distance_to(player.global_position) <= magnetic_range:
			start_magnetic_collection(player)
	
	# Move towards player if magnetic
	if is_magnetic and target_player:
		var direction = (target_player.global_position - global_position).normalized()
		global_position += direction * magnetic_speed * delta
		
		# Collect if close enough
		if global_position.distance_to(target_player.global_position) <= 25.0:
			collect(target_player)

func setup_fruit_type():
	match fruit_type:
		FruitType.APPLE:
			sprite.modulate = Color.RED
			score_value = 10
			collect_particles.color = Color.RED
		FruitType.BANANA:
			sprite.modulate = Color.YELLOW
			score_value = 15
			collect_particles.color = Color.YELLOW
		FruitType.CHERRY:
			sprite.modulate = Color(0.8, 0.2, 0.4, 1.0) # Dark red
			score_value = 20
			collect_particles.color = Color(0.8, 0.2, 0.4, 1.0)
		FruitType.ORANGE:
			sprite.modulate = Color.ORANGE
			score_value = 12
			collect_particles.color = Color.ORANGE
		FruitType.GRAPE:
			sprite.modulate = Color.PURPLE
			score_value = 25
			collect_particles.color = Color.PURPLE

func start_magnetic_collection(player):
	is_magnetic = true
	target_player = player
	
	# Visual feedback for magnetic attraction
	var tween = create_tween()
	tween.tween_property(sprite, "scale", sprite.scale * 1.2, 0.2)
	tween.tween_property(sprite, "scale", sprite.scale, 0.2)

func _on_body_entered(body):
	if body.is_in_group("player") and not is_collected:
		collect(body)

func collect(player):
	if is_collected:
		return
	
	is_collected = true
	
	# Add to game totals
	Game.collect_fruit(fruit_type)
	
	# Add score
	Game.add_score(score_value)
	
	# Visual feedback
	collect_particles.emitting = true
	
	# Audio feedback
	if Audio.has_method("play_sfx"):
		# Audio.play_sfx("fruit_collect")
		pass
	
	# Hide sprite and collision
	sprite.visible = false
	collision_shape.disabled = true
	
	# Animate collection
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
	
	print("Collected ", FruitType.keys()[fruit_type], " for ", score_value, " points!")

func get_fruit_name() -> String:
	return FruitType.keys()[fruit_type].capitalize()

func get_fruit_icon_color() -> Color:
	match fruit_type:
		FruitType.APPLE:
			return Color.RED
		FruitType.BANANA:
			return Color.YELLOW
		FruitType.CHERRY:
			return Color(0.8, 0.2, 0.4, 1.0)
		FruitType.ORANGE:
			return Color.ORANGE
		FruitType.GRAPE:
			return Color.PURPLE
		_:
			return Color.WHITE