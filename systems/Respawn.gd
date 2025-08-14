extends Node

signal player_respawned(position: Vector2)
signal checkpoint_set(checkpoint_name: String)

var current_checkpoint: Checkpoint = null
var default_spawn_position: Vector2 = Vector2.ZERO
var respawn_count: int = 0

func _ready():
	# Set default spawn position from first scene
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		default_spawn_position = player.global_position

func _on_checkpoint_activated(checkpoint: Checkpoint):
	current_checkpoint = checkpoint
	checkpoint_set.emit(checkpoint.checkpoint_name)
	print("Respawn point set to: ", checkpoint.checkpoint_id, " (", checkpoint.checkpoint_name, ")")

func set_checkpoint_position(position: Vector2, name: String):
	# For crate checkpoints
	default_spawn_position = position + Vector2(0, -16)
	checkpoint_set.emit(name)
	print("Checkpoint set at: ", position, " (", name, ")")

func respawn_player():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("No player found for respawn")
		return
	
	var spawn_position = default_spawn_position
	if current_checkpoint:
		spawn_position = current_checkpoint.global_position + Vector2(0, -16) # Spawn slightly above checkpoint
	
	# Increment respawn counter
	respawn_count += 1
	
	# Reset player state
	player.velocity = Vector2.ZERO
	player.global_position = spawn_position
	player.coyote_timer = 0.0
	player.jump_buffer_timer = 0.0
	player.has_jumped = false
	player.is_jumping = false
	
	# Visual feedback
	FX.fade_in(0.5)
	FX.shake(150)
	
	# Update HUD
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("update_deaths"):
		hud.update_deaths(respawn_count)
	
	# Emit signal
	player_respawned.emit(spawn_position)
	
	print("Player respawned at: ", spawn_position, " (Death #", respawn_count, ")")

func reset_checkpoints():
	current_checkpoint = null
	respawn_count = 0
	var checkpoints = get_tree().get_nodes_in_group("checkpoints")
	for checkpoint in checkpoints:
		if checkpoint.has_method("reset"):
			checkpoint.reset()

func get_current_checkpoint_name() -> String:
	if current_checkpoint:
		return current_checkpoint.checkpoint_name
	return "Start"

func get_respawn_count() -> int:
	return respawn_count