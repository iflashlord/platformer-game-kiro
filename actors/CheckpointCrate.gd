extends Crate
class_name CheckpointCrate

@export var checkpoint_name: String = "Crate Checkpoint"
var is_activated: bool = false

@onready var checkpoint_light: Sprite2D = $CheckpointLight

func _ready():
	super._ready()
	crate_type = "checkpoint"
	shard_color = Color.CYAN
	health = 1

func on_player_interaction(player: Player):
	if not is_activated:
		activate_checkpoint()

func activate_checkpoint():
	if is_activated:
		return
	
	is_activated = true
	
	# Visual feedback
	sprite.modulate = Color.CYAN
	checkpoint_light.visible = true
	checkpoint_light.modulate = Color.CYAN
	
	# Set as respawn point
	Respawn.set_checkpoint_position(global_position, checkpoint_name)
	
	# Effects
	FX.flash_screen(Color.CYAN, 0.2)
	FX.shake(150)
	
	# Update HUD
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("update_checkpoint"):
		hud.update_checkpoint(checkpoint_name)
	
	print("Checkpoint crate activated: ", checkpoint_name)

func spawn_specific_effects():
	# Don't break, just bounce
	set_state(CrateState.BOUNCING)
	
	# Spawn checkpoint particles
	var particles = preload("res://actors/CheckpointParticles.tscn").instantiate()
	get_tree().current_scene.add_child(particles)
	particles.global_position = global_position
	particles.emitting = true

func break_crate():
	# Checkpoint crates don't break, they just activate
	if not is_activated:
		activate_checkpoint()
	else:
		# If already activated, just bounce
		set_state(CrateState.BOUNCING)