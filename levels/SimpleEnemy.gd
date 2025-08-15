extends CharacterBody2D
class_name SimpleEnemy

@export var patrol_speed: float = 50.0
@export var patrol_distance: float = 100.0

var start_position: Vector2
var direction: int = 1
var is_alive: bool = true

signal enemy_defeated
signal player_detected(player)

func _ready():
	add_to_group("enemies")
	start_position = global_position

func _physics_process(delta):
	if not is_alive:
		return
	
	# Simple patrol movement
	velocity.x = patrol_speed * direction
	
	# Check if we've moved too far from start position
	var distance_from_start = abs(global_position.x - start_position.x)
	if distance_from_start > patrol_distance:
		direction *= -1
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += 980 * delta
	
	move_and_slide()
	
	# Check for player collision
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			player_detected.emit(collider)
			damage_player(collider)

func damage_player(player):
	if player.has_method("take_damage"):
		player.take_damage(1)
	elif player.has_method("die"):
		player.die()

func take_damage(amount: int = 1):
	if not is_alive:
		return
	
	is_alive = false
	enemy_defeated.emit()
	
	# Visual feedback
	modulate = Color.RED
	
	# Disable collision
	collision_layer = 0
	collision_mask = 0
	
	print("Enemy defeated!")
	
	# Remove after a short delay
	await get_tree().create_timer(1.0).timeout
	queue_free()