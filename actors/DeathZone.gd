extends Area2D
class_name DeathZone

func _ready():
	# Connect the body entered signal
	body_entered.connect(_on_body_entered)
	
	# Add to death zone group
	add_to_group("death_zones")
	
	print("💀 Death zone created at: ", global_position)

func _on_body_entered(body):
	if body is Player:
		print("💀 Player entered death zone - triggering death")
		body.die()