extends Node

# Object pools for performance optimization
var fruit_pool: Array[Node] = []
var explosion_pool: Array[Node] = []

const MAX_POOL_SIZE = 50
const FRUIT_SCENE = preload("res://actors/Fruit.tscn")
const EXPLOSION_SCENE = preload("res://actors/Explosion.tscn")

func _ready():
	# Pre-populate pools
	for i in range(10):
		create_fruit()
		create_explosion()


func get_fruit() -> Node:
	if fruit_pool.is_empty():
		return create_fruit()
	
	var fruit = fruit_pool.pop_back()
	fruit.reset()
	return fruit

func return_fruit(fruit: Node):
	if fruit_pool.size() < MAX_POOL_SIZE:
		fruit.get_parent().remove_child(fruit)
		fruit_pool.append(fruit)
	else:
		fruit.queue_free()

func get_explosion() -> Node:
	if explosion_pool.is_empty():
		return create_explosion()
	
	var explosion = explosion_pool.pop_back()
	explosion.reset()
	return explosion

func return_explosion(explosion: Node):
	if explosion_pool.size() < MAX_POOL_SIZE:
		explosion.get_parent().remove_child(explosion)
		explosion_pool.append(explosion)
	else:
		explosion.queue_free()

func create_fruit() -> Node:
	var fruit = FRUIT_SCENE.instantiate()
	return fruit

func create_explosion() -> Node:
	var explosion = EXPLOSION_SCENE.instantiate()
	return explosion

func spawn_fruit(position: Vector2, fruit_type: String = "apple"):
	var fruit = get_fruit()
	get_tree().current_scene.add_child(fruit)
	fruit.global_position = position
	fruit.setup(fruit_type)

func spawn_explosion(position: Vector2, radius: float = 100.0, damage: float = 1.0):
	var explosion = get_explosion()
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = position
	explosion.setup(radius, damage)
