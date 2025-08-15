extends RigidBody2D
class_name CrateShard

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var lifetime: float = 3.0
var timer: float = 0.0
var fade_time: float = 1.0

signal shard_expired(shard: CrateShard)

func _ready():
	# Set collision layers
	collision_layer = 4  # Debris layer
	collision_mask = 1   # World layer

func _physics_process(delta):
	timer += delta
	
	# Start fading in the last second
	if timer > lifetime - fade_time:
		var fade_progress = (timer - (lifetime - fade_time)) / fade_time
		sprite.modulate.a = 1.0 - fade_progress
	
	# Return to pool when expired
	if timer >= lifetime:
		shard_expired.emit(self)
		ObjectPool.return_shard(self)

func setup(color: Color, velocity: Vector2):
	sprite.modulate = color
	sprite.modulate.a = 1.0
	linear_velocity = velocity
	angular_velocity = randf_range(-10, 10)
	timer = 0.0
	
	# Randomize shard size
	var scale_factor = randf_range(0.5, 1.2)
	sprite.scale = Vector2(scale_factor, scale_factor)

func reset():
	timer = 0.0
	sprite.modulate = Color.WHITE
	sprite.modulate.a = 1.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	sprite.scale = Vector2.ONE

func _integrate_forces(state):
	# Check for collision with ground for bounce effect
	if state.get_contact_count() > 0:
		var contact = state.get_contact_local_position(0)
		if contact.y > 0:  # Hit something below
			Audio.play_sfx("shard_bounce")
