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
		print("💀 DeathZone: Player entered death zone at ", global_position)
		print("🎮 Player position: ", body.global_position)
		body.die()