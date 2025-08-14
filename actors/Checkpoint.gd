extends Area2D
class_name Checkpoint

@export var checkpoint_id: String = "checkpoint_01"
@export var checkpoint_name: String = "Checkpoint 1"

var is_activated: bool = false

func _ready():
	# Connect the body entered signal
	body_entered.connect(_on_body_entered)
	
	# Add to checkpoint group
	add_to_group("checkpoints")
	
	print("🏁 Checkpoint created: ", checkpoint_name, " at ", global_position)

func _on_body_entered(body):
	if body is Player and not is_activated:
		activate()

func activate():
	if is_activated:
		return
		
	is_activated = true
	
	# Visual feedback
	var sprite = $CheckpointSprite
	sprite.color = Color.GREEN
	
	# Notify respawn system
	Respawn._on_checkpoint_activated(self)
	
	# Audio feedback
	if Audio:
		Audio.play_sfx("checkpoint")
	
	print("✅ Checkpoint activated: ", checkpoint_name)

func reset():
	is_activated = false
	var sprite = $CheckpointSprite
	sprite.color = Color(0, 1, 1, 0.7)
