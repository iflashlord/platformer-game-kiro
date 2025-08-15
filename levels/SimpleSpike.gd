extends Area2D
class_name SimpleSpike

@export var damage: int = 1

signal player_damaged(player)

func _ready():
	add_to_group("spikes")
	
	# Connect to body entered
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		damage_player(body)

func damage_player(player):
	player_damaged.emit(player)
	
	if player.has_method("take_damage"):
		player.take_damage(damage)
	elif player.has_method("die"):
		player.die()
	
	print("Spike damaged player!")