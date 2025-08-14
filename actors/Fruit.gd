extends Area2D
class_name Fruit

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var particles: CPUParticles2D = $CollectParticles

var fruit_type: String = "apple"
var collected: bool = false
var bounce_height: float = 20.0
var bounce_speed: float = 2.0

signal fruit_collected(fruit: Fruit, type: String)

func _ready():
	# Connect collection signal
	body_entered.connect(_on_body_entered)
	
	# Set collision layers
	collision_layer = 8   # Collectible layer
	collision_mask = 2    # Player layer

func _physics_process(delta):
	if not collected:
		# Gentle floating animation
		var offset = sin(Time.get_time_dict_from_system()["second"] * bounce_speed) * bounce_height
		sprite.position.y = offset

func setup(type: String):
	fruit_type = type
	collected = false
	sprite.modulate.a = 1.0
	
	# Set sprite based on type
	match type:
		"apple":
			sprite.modulate = Color.RED
		"banana":
			sprite.modulate = Color.YELLOW
		"cherry":
			sprite.modulate = Color(0.8, 0.2, 0.4)
		"orange":
			sprite.modulate = Color.ORANGE
		"grape":
			sprite.modulate = Color.PURPLE
		_:
			sprite.modulate = Color.WHITE

func reset():
	collected = false
	sprite.modulate.a = 1.0
	sprite.position = Vector2.ZERO
	if particles:
		particles.emitting = false

func collect():
	if collected:
		return
	
	collected = true
	fruit_collected.emit(self, fruit_type)
	
	# Visual feedback
	if particles:
		particles.emitting = true
	
	# Animate collection
	var tween = create_tween()
	tween.parallel().tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.2)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_return_to_pool)
	
	# Play sound
	Audio.play_sfx("collect_fruit")

func _return_to_pool():
	ObjectPool.return_fruit(self)

func _on_body_entered(body):
	if body.is_in_group("player") and not collected:
		collect()
