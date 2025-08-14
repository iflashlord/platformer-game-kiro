extends Crate
class_name NitroCrate

@export var kill_radius: float = 100.0
@export var warning_time: float = 1.0

var is_triggered: bool = false
var warning_timer: float = 0.0

@onready var warning_sprite: Sprite2D = $WarningSprite

func _ready():
	super._ready()
	crate_type = "nitro"
	shard_color = Color.GREEN
	health = 1 # Very fragile

func _physics_process(delta):
	super._physics_process(delta)
	
	if is_triggered and current_state != CrateState.BROKEN:
		warning_timer += delta
		
		# Warning blink effect
		var blink_speed = 15.0
		warning_sprite.modulate.a = (sin(warning_timer * blink_speed) + 1.0) / 2.0
		
		# Explode after warning period
		if warning_timer >= warning_time:
			area_kill()

func on_player_interaction(player: Player):
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
	warning_sprite.visible = true
	warning_sprite.modulate = Color.RED
	
	# Screen shake warning
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
		if body is Player:
			# Instant kill
			body.die()
		elif body is Crate and body != self:
			# Destroy other crates
			body.break_crate()
	
	# Massive explosion effect
	FX.shake(500)
	FX.flash_screen(Color.GREEN, 0.3)
	FX.hit_stop(200)
	
	# Break this crate
	break_crate()

func spawn_specific_effects():
	# Spawn large explosion
	ObjectPool.spawn_explosion(global_position, kill_radius, 0)
	
	# Spawn multiple fruits
	for i in range(3):
		var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		ObjectPool.spawn_fruit(global_position + offset, "apple")