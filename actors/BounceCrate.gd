extends Crate
class_name BounceCrate

@export var player_bounce_force: float = 500.0

func _ready():
	super._ready()
	crate_type = "bounce"
	shard_color = Color.YELLOW
	bounce_force = 400.0

func on_player_interaction(player: Player):
	if current_state == CrateState.IDLE:
		# Give player extra bounce
		player.velocity.y = -player_bounce_force
		player.is_jumping = true
		
		# Bounce the crate too
		set_state(CrateState.BOUNCING)
		
		# Visual feedback
		FX.shake(100)
		
		print("Bounce crate activated!")

func spawn_specific_effects():
	# Spawn a fruit pickup
	ObjectPool.spawn_fruit(global_position, "banana")
