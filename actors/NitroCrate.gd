extends Crate
class_name NitroCrate

@export var kill_radius: float = 100.0
@export var warning_time: float = 1.0

var is_triggered: bool = false
var warning_timer: float = 0.0

@onready var warning_sprite: ColorRect = $WarningSprite

func _ready():
	super._ready()
	crate_type = "nitro"
	shard_color = Color.GREEN
	health = 1 # Very fragile

func _process(delta):
	super._process(delta)
	
	if is_triggered and current_state != CrateState.BROKEN:
		warning_timer += delta
		
		# Warning blink effect
		var blink_speed = 15.0
		warning_sprite.modulate.a = (sin(warning_timer * blink_speed) + 1.0) / 2.0
		
		# Explode after warning period
		if warning_timer >= warning_time:
			area_kill()

func on_player_interaction(player):
	trigger_nitro()

func take_damage(amount: int = 1):
	trigger_nitro()

func trigger_nitro():
	if is_triggered:
		return
	
	is_triggered = true
	warning_timer = 0.0
	
	# Visual warning
	sprite.modulate = Color.GREEN
	if warning_sprite:
		warning_sprite.visible = true
		warning_sprite.modulate = Color.RED
	
	# Screen shake warning with fallback
	if has_node("/root/FX") and FX.has_method("shake"):
		FX.shake(50)
	
	print("Nitro crate triggered! DANGER!")

func area_kill():
	if current_state == CrateState.BROKEN:
		return
	
	# Kill anything in radius instantly
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = kill_radius
	query.shape = circle_shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 1
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var body = result.collider
		if body.is_in_group("player"):
			# Instant kill
			if body.has_method("die"):
				body.die()
		elif body.is_in_group("crates") and body != self:
			# Destroy other crates
			if body.has_method("break_crate"):
				body.break_crate()
		elif body.is_in_group("enemies"):
			# Kill enemies in blast radius
			if body.has_method("take_damage"):
				body.take_damage(999)
	
	# Massive explosion effect with fallbacks
	if has_node("/root/FX"):
		if FX.has_method("shake"):
			FX.shake(500)
		if FX.has_method("flash_screen"):
			FX.flash_screen(Color.GREEN, 0.3)
		if FX.has_method("hit_stop"):
			FX.hit_stop(200)
	
	# Break this crate
	break_crate()

func spawn_specific_effects():
	# Spawn large explosion with fallback
	if has_node("/root/ObjectPool") and ObjectPool.has_method("spawn_explosion"):
		ObjectPool.spawn_explosion(global_position, kill_radius, 0)
	else:
		# Fallback: create simple explosion effect
		create_explosion_effect()
	
	# Spawn multiple fruits with fallback
	if has_node("/root/ObjectPool") and ObjectPool.has_method("spawn_fruit"):
		for i in range(3):
			var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
			ObjectPool.spawn_fruit(global_position + offset, "apple")
	else:
		print("ObjectPool not available - no fruit spawned")

func create_explosion_effect():
	# Create multiple explosion particles
	for i in range(20):
		var particle = ColorRect.new()
		particle.size = Vector2(8, 8)
		particle.color = Color.GREEN
		var random_offset = Vector2(randf_range(-kill_radius, kill_radius), randf_range(-kill_radius, kill_radius))
		particle.position = global_position + random_offset
		get_tree().current_scene.add_child(particle)
		
		# Animate explosion particle
		var tween = create_tween()
		var random_velocity = Vector2(randf_range(-200, 200), randf_range(-300, -100))
		tween.parallel().tween_property(particle, "position", particle.position + random_velocity, 1.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 1.5)
		tween.tween_callback(particle.queue_free)
