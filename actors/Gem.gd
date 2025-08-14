extends Area2D
class_name Gem

enum GemType {
	RUBY,
	EMERALD,
	SAPPHIRE,
	DIAMOND,
	AMETHYST
}

@export var gem_type: GemType = GemType.RUBY
@export var score_value: int = 50
@export var magnetic_range: float = 80.0
@export var magnetic_speed: float = 400.0

var is_collected: bool = false
var is_magnetic: bool = false
var target_player: Player = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var glow_sprite: Sprite2D = $GlowSprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collect_particles: CPUParticles2D = $CollectParticles

func _ready():
	# Add to collectibles group
	add_to_group("collectibles")
	add_to_group("gems")
	
	# Set gem appearance based on type
	setup_gem_type()
	
	# Start sparkle animation
	animation_player.play("sparkle")

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
		if global_position.distance_to(target_player.global_position) <= 30.0:
			collect(target_player)

func setup_gem_type():
	match gem_type:
		GemType.RUBY:
			sprite.modulate = Color.RED
			glow_sprite.modulate = Color(1, 0.5, 0.5, 0.3)
			score_value = 50
			collect_particles.color = Color.RED
		GemType.EMERALD:
			sprite.modulate = Color.GREEN
			glow_sprite.modulate = Color(0.5, 1, 0.5, 0.3)
			score_value = 75
			collect_particles.color = Color.GREEN
		GemType.SAPPHIRE:
			sprite.modulate = Color.BLUE
			glow_sprite.modulate = Color(0.5, 0.5, 1, 0.3)
			score_value = 60
			collect_particles.color = Color.BLUE
		GemType.DIAMOND:
			sprite.modulate = Color.WHITE
			glow_sprite.modulate = Color(1, 1, 1, 0.5)
			score_value = 100
			collect_particles.color = Color.WHITE
		GemType.AMETHYST:
			sprite.modulate = Color.PURPLE
			glow_sprite.modulate = Color(1, 0.5, 1, 0.3)
			score_value = 80
			collect_particles.color = Color.PURPLE

func start_magnetic_collection(player: Player):
	is_magnetic = true
	target_player = player
	
	# Enhanced visual feedback for gems
	FX.flash_screen(get_gem_color(), 0.1)
	
	var tween = create_tween()
	tween.tween_property(sprite, "scale", sprite.scale * 1.3, 0.3)
	tween.tween_property(sprite, "scale", sprite.scale, 0.3)

func _on_body_entered(body):
	if body is Player and not is_collected:
		collect(body)

func collect(player: Player):
	if is_collected:
		return
	
	is_collected = true
	
	# Add to game totals
	Game.collect_gem(gem_type)
	
	# Add score
	Game.add_score(score_value)
	
	# Enhanced effects for gems
	FX.shake(150)
	FX.flash_screen(get_gem_color(), 0.2)
	
	# Visual feedback
	collect_particles.emitting = true
	
	# Audio feedback
	if Audio.has_method("play_sfx"):
		# Audio.play_sfx("gem_collect")
		pass
	
	# Play collect animation
	animation_player.play("collect")
	collision_shape.disabled = true
	
	# Wait for animation to finish
	await animation_player.animation_finished
	queue_free()
	
	print("Collected ", GemType.keys()[gem_type], " gem for ", score_value, " points!")

func get_gem_name() -> String:
	return GemType.keys()[gem_type].capitalize()

func get_gem_color() -> Color:
	match gem_type:
		GemType.RUBY:
			return Color.RED
		GemType.EMERALD:
			return Color.GREEN
		GemType.SAPPHIRE:
			return Color.BLUE
		GemType.DIAMOND:
			return Color.WHITE
		GemType.AMETHYST:
			return Color.PURPLE
		_:
			return Color.WHITE