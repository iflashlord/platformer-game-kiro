extends RigidBody2D
class_name TNTCrate

signal exploded(position: Vector2)

@export var explosion_radius: float = 100.0
@export var explosion_damage: int = 1
@export var fuse_time: float = 3.0
@export var explosion_scene: PackedScene

var is_armed: bool = false
var fuse_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var explosion_area: Area2D = $ExplosionArea
@onready var fuse_sound: AudioStreamPlayer2D = $FuseSound
@onready var explosion_sound: AudioStreamPlayer2D = $ExplosionSound
@onready var warning_light: Node2D = $WarningLight

func _ready():
	# Set up physics
	gravity_scale = 1.0
	collision_layer = 4  # Debris layer
	collision_mask = 1   # World layer
	
	# Start armed immediately when dropped by boss
	_arm_tnt()

func _physics_process(delta):
	if is_armed:
		fuse_timer += delta
		
		# Visual warning as explosion approaches
		var time_ratio = fuse_timer / fuse_time
		warning_light.modulate = Color.WHITE.lerp(Color.RED, time_ratio)
		
		# Flashing effect in final second
		if fuse_timer > fuse_time - 1.0:
			warning_light.visible = sin(fuse_timer * 20) > 0
		
		if fuse_timer >= fuse_time:
			_explode()

func _arm_tnt():
	is_armed = true
	sprite.play("armed")
	fuse_sound.play()
	
	# Start warning light
	warning_light.visible = true

func _explode():
	if not is_armed:
		return
		
	is_armed = false
	
	# Create explosion effect
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_parent().add_child(explosion)
		explosion.global_position = global_position
	
	# Damage nearby entities
	_damage_nearby_entities()
	
	# Screen shake
	if FX:
		FX.screen_shake(1.5)
	
	explosion_sound.play()
	exploded.emit(global_position)
	
	# Hide sprite and disable collision
	sprite.visible = false
	collision_shape.set_deferred("disabled", true)
	
	# Remove after sound finishes
	await explosion_sound.finished
	queue_free()

func _damage_nearby_entities():
	# Get all bodies in explosion radius
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	# Create circle shape for explosion
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = explosion_radius
	query.shape = circle_shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 2 | 4  # Player and enemy layers
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var body = result.collider
		
		# Damage player
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(explosion_damage)
		
		# Push objects away
		if body is RigidBody2D:
			var direction = (body.global_position - global_position).normalized()
			var distance = global_position.distance_to(body.global_position)
			var force = (explosion_radius - distance) / explosion_radius * 500
			body.apply_central_impulse(direction * force)

func _on_body_entered(body):
	# Explode on contact with player or other objects
	if body.is_in_group("player") or body.is_in_group("enemy"):
		if is_armed and fuse_timer > 0.5:  # Minimum fuse time
			_explode()