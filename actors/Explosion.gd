extends Area2D
class_name Explosion

@export var explosion_radius: float = 100.0
@export var damage: float = 1.0
@export var duration: float = 0.5

var explosion_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var particles: CPUParticles2D = $Particles

func _ready():
	# Set collision shape radius
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = explosion_radius
	collision_shape.shape = circle_shape

func _physics_process(delta):
	explosion_timer += delta
	
	# Expand explosion
	var scale_progress = explosion_timer / duration
	var explosion_scale = lerp(0.1, 1.0, scale_progress)
	sprite.scale = Vector2(explosion_scale, explosion_scale) * (explosion_radius / 50.0)
	
	# Fade out
	sprite.modulate.a = 1.0 - scale_progress
	
	# Return to pool when done
	if explosion_timer >= duration:
		ObjectPool.return_explosion(self)

func setup(radius: float, dmg: float):
	explosion_radius = radius
	damage = dmg
	explosion_timer = 0.0
	
	# Update collision shape
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	collision_shape.shape = circle_shape
	
	# Start particles
	if particles:
		particles.emitting = true
		particles.amount = int(radius / 2)
	
	# Reset visuals
	sprite.scale = Vector2(0.1, 0.1)
	sprite.modulate.a = 1.0
	
	# Visual effects for big explosions
	if radius >= 80:  # TNT-sized explosion
		FX.hit_stop(120)  # 120ms hit-stop
		FX.shake(300)  # Strong screen shake
		Audio.play_sfx("big_explosion")
	elif radius >= 50:  # Medium explosion
		FX.shake(150)  # Medium screen shake
		Audio.play_sfx("explosion")
	else:  # Small explosion
		FX.shake(75)  # Small screen shake
		Audio.play_sfx("small_explosion")

func reset():
	explosion_timer = 0.0
	sprite.scale = Vector2(0.1, 0.1)
	sprite.modulate.a = 1.0
	if particles:
		particles.emitting = false
