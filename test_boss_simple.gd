extends Node2D

# Simple test script to verify boss functionality
# Run this scene to test the boss without complex dependencies

func _ready():
	print("Testing Giant Boss system...")
	
	# Create a simple ground
	var ground = StaticBody2D.new()
	var ground_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(1280, 64)
	ground_shape.shape = rect_shape
	ground.add_child(ground_shape)
	ground.position = Vector2(640, 680)
	ground.collision_layer = 1
	add_child(ground)
	
	# Create walls
	_create_wall(Vector2(-32, 360))
	_create_wall(Vector2(1312, 360))
	
	# Create boss
	var boss_scene = preload("res://actors/GiantBoss.tscn")
	var boss = boss_scene.instantiate()
	boss.position = Vector2(640, 550)
	add_child(boss)
	
	# Connect signals
	boss.boss_defeated.connect(_on_boss_defeated)
	boss.boss_damaged.connect(_on_boss_damaged)
	boss.tnt_placed.connect(_on_tnt_placed)
	
	print("Boss test setup complete!")
	print("Boss should start walking between walls")
	print("Click on the boss's head area to damage it!")

func _create_wall(pos: Vector2):
	var wall = StaticBody2D.new()
	var wall_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(64, 720)
	wall_shape.shape = rect_shape
	wall.add_child(wall_shape)
	wall.position = pos
	wall.collision_layer = 1
	add_child(wall)

func _on_boss_defeated():
	print("SUCCESS: Boss defeated!")

func _on_boss_damaged(health: int, max_health: int):
	print("Boss damaged! Health: ", health, "/", max_health)

func _on_tnt_placed(tnt_position: Vector2):
	print("TNT would be placed at: ", tnt_position)