extends Control

@onready var player: Player = $Player
@onready var explosion_button: Button = $VBox/ExplosionButton
@onready var shake_button: Button = $VBox/ShakeButton
@onready var hitstop_button: Button = $VBox/HitstopButton
@onready var status_label: Label = $VBox/StatusLabel

func _ready():
	# Connect button signals
	explosion_button.pressed.connect(_on_explosion_pressed)
	shake_button.pressed.connect(_on_shake_pressed)
	hitstop_button.pressed.connect(_on_hitstop_pressed)
	
	# Connect player signals
	if player:
		player.jumped.connect(_on_player_jumped)
		player.landed.connect(_on_player_landed)
	
	_update_status()

func _update_status():
	var text = "VFX Test Scene\n\n"
	text += "Controls:\n"
	text += "WASD/Arrow Keys - Move\n"
	text += "Space - Jump\n"
	text += "F - Dimension Flip\n\n"
	text += "Effects:\n"
	text += "• Dust particles while running\n"
	text += "• Landing particles on impact\n"
	text += "• Sprite squash/stretch\n"
	text += "• Screen shake on heavy landing\n"
	text += "• Hit-stop on big impacts\n"
	status_label.text = text

func _on_explosion_pressed():
	# Create a test explosion
	var explosion = preload("res://actors/Explosion.tscn").instantiate()
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = player.global_position + Vector2(100, 0)
	explosion.setup(100, 1.0)  # Big explosion for TNT effect

func _on_shake_pressed():
	FX.shake(200)

func _on_hitstop_pressed():
	FX.hit_stop(120)

func _on_player_jumped():
	print("Player jumped - stretch effect triggered")

func _on_player_landed():
	print("Player landed - squash effect and particles triggered")

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
