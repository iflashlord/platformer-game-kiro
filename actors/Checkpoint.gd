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
	
	# Floating "Checkpoint" text effect (reuse collectible score animation style)
	_create_checkpoint_text_effect()

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

# Creates a floating label that fades out, matching Collectible.gd style
func _create_checkpoint_text_effect():
	var effect_label := Label.new()
	effect_label.text = "Checkpoint"
	effect_label.add_theme_font_size_override("font_size", 16)
	effect_label.add_theme_color_override("font_color", Color.BLACK)
	effect_label.position = global_position + Vector2(-20, -30)
	
	if get_tree() and get_tree().current_scene:
		get_tree().current_scene.add_child(effect_label)
	else:
		add_child(effect_label)

	var tween := create_tween()
	tween.parallel().tween_property(effect_label, "position", effect_label.position + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func():
		effect_label.queue_free()
	)
