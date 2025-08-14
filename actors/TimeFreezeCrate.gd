extends Crate
class_name TimeFreezeCrate

@export var time_reduction: float = 2.0
@export var freeze_duration: float = 1.0

var is_used: bool = false

@onready var time_sprite: Sprite2D = $TimeSprite

func _ready():
	super._ready()
	crate_type = "timefreeze"
	shard_color = Color.BLUE
	health = 1

func on_player_interaction(player: Player):
	if not is_used:
		activate_time_freeze()

func activate_time_freeze():
	if is_used:
		return
	
	is_used = true
	
	# Visual feedback
	sprite.modulate = Color.BLUE
	time_sprite.visible = true
	
	# Time freeze effect
	Engine.time_scale = 0.1
	
	# Restore time scale after duration
	var timer = Timer.new()
	timer.wait_time = freeze_duration * 0.1 # Adjusted for time scale
	timer.one_shot = true
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(timer)
	timer.start()
	timer.timeout.connect(func():
		Engine.time_scale = 1.0
		timer.queue_free()
	)
	
	# Subtract time from trial mode timer
	if Game.has_method("subtract_time"):
		Game.subtract_time(time_reduction)
	
	# Effects
	FX.flash_screen(Color.BLUE, 0.5)
	
	print("Time freeze activated! -", time_reduction, "s from timer")
	
	# Break the crate
	break_crate()

func spawn_specific_effects():
	# Spawn time particles
	ObjectPool.spawn_shards(global_position, 8, Color.BLUE)
	
	# Spawn clock pickup
	ObjectPool.spawn_fruit(global_position, "clock")