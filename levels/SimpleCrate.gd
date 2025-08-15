extends Area2D
class_name SimpleCrate

@export var crate_type: String = "basic"
@export var health: int = 1
@export var bounce_force: float = 300.0

var is_destroyed: bool = false

signal crate_destroyed(type: String)

func _ready():
	add_to_group("crates")
	
	# Connect to player collision
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and not is_destroyed:
		interact_with_player(body)

func interact_with_player(player):
	match crate_type:
		"basic":
			destroy_crate()
		"bounce":
			bounce_player(player)
			destroy_crate()
		"tnt":
			explode_crate()

func bounce_player(player):
	if player.has_method("apply_bounce"):
		player.apply_bounce(bounce_force)
	elif "velocity" in player:
		player.velocity.y = -bounce_force

func destroy_crate():
	if is_destroyed:
		return
	
	is_destroyed = true
	crate_destroyed.emit(crate_type)
	
	# Visual feedback
	modulate = Color.GRAY
	
	# Disable collision
	collision_layer = 0
	collision_mask = 0
	
	print("Crate destroyed: ", crate_type)

func explode_crate():
	if is_destroyed:
		return
	
	print("TNT Crate exploding!")
	
	# Create explosion effect
	var explosion_area = Area2D.new()
	var explosion_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 100.0
	explosion_shape.shape = circle_shape
	explosion_area.add_child(explosion_shape)
	get_parent().add_child(explosion_area)
	explosion_area.global_position = global_position
	
	# Check for nearby objects
	explosion_area.body_entered.connect(_on_explosion_hit)
	
	# Remove explosion area after a short time
	await get_tree().create_timer(0.1).timeout
	explosion_area.queue_free()
	
	destroy_crate()

func _on_explosion_hit(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		else:
			body.die()