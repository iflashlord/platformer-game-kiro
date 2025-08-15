extends Crate
class_name TNTCrate

@export var fuse_time: float = 3.0
@export var explosion_radius: float = 150.0
@export var explosion_damage: float = 2.0

var is_fuse_lit: bool = false
var fuse_timer: float = 0.0

@onready var fuse_light: Sprite2D = $FuseLight

func _ready():
	super._ready()
	crate_type = "tnt"
	shard_color = Color.RED
	health = 1 # One hit to activate

func _physics_process(delta):
	super._physics_process(delta)
	
	if is_fuse_lit:
		fuse_timer += delta
		
		# Blinking fuse effect
		var blink_speed = lerp(2.0, 10.0, fuse_timer / fuse_time)
		fuse_light.modulate.a = (sin(fuse_timer * blink_speed) + 1.0) / 2.0
		
		# Explode when timer runs out
		if fuse_timer >= fuse_time:
			remote_explode()

func on_player_interaction(player: Player):
	if not is_fuse_lit:
		light_fuse()

func take_damage(amount: int = 1):
	if not is_fuse_lit:
		light_fuse()

func light_fuse():
	if is_fuse_lit:
		return
	
	is_fuse_lit = true
	fuse_timer = 0.0
	
	# Visual feedback
	sprite.modulate = Color.ORANGE
	fuse_light.visible = true
	
	# Audio feedback
	print("TNT fuse lit! Exploding in ", fuse_time, " seconds!")

func remote_explode():
	if current_state == CrateState.BROKEN:
		return
	
	# Create explosion area
	ObjectPool.spawn_explosion(global_position, explosion_radius, explosion_damage)
	
	# Damage nearby crates and player
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = explosion_radius
	query.shape = circle_shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 1 # Adjust based on your collision layers
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var body = result.collider
		if body is Player:
			# Damage player
			body.die()
		elif body is Crate and body != self:
			# Chain reaction with other crates
			body.take_damage(explosion_damage)
	
	# Break this crate
	break_crate()

func spawn_specific_effects():
	# Spawn explosion particles
	ObjectPool.spawn_explosion(global_position, explosion_radius * 0.5, 0)
