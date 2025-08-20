extends Area2D
class_name Checkpoint

@export var checkpoint_id: String = "checkpoint_01"
@export var checkpoint_name: String = "Checkpoint 1"

@onready var flag_sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_activated: bool = false

func _ready():
	# Connect the body entered signal
	body_entered.connect(_on_body_entered)
	
	# Add to checkpoint group
	add_to_group("checkpoints")
	
	flag_sprite.play("default")
	
	print("🏁 Checkpoint created: ", checkpoint_name, " at ", global_position)

func _on_body_entered(body):
	print("🏁 Checkpoint collision detected with: ", body.name, " (groups: ", body.get_groups(), ")")
	if body is Player and not is_activated:
		print("🏁 Valid player collision, activating checkpoint")
		activate()
	else:
		print("🏁 Invalid collision or already activated")

func activate():
	if is_activated:
		return
		
	is_activated = true
	
	# Visual feedback
	 
	flag_sprite.play("checked")
	
	# Screen flash
	if FX and FX.has_method("flash_screen"):
		FX.flash_screen(Color.GREEN * 0.3, 0.2)
	
	# Notify respawn system
	Respawn._on_checkpoint_activated(self)
	
	# Audio feedback
	if Audio:
		Audio.play_sfx("checkpoint")
	
	print("✅ Checkpoint activated: ", checkpoint_name)

func reset():
	is_activated = false
	flag_sprite.play("default")
