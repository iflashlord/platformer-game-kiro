extends Node2D

# Test script with a simple player for stomping mechanics

func _ready():
	print("Testing Giant Boss with Player...")
	
	# Create ground
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
	
	# Create simple player
	var player = _create_simple_player()
	player.position = Vector2(200, 600)
	add_child(player)
	
	# Create boss
	var boss_scene = preload("res://actors/GiantBoss.tscn")
	var boss = boss_scene.instantiate()
	boss.position = Vector2(640, 550)
	add_child(boss)
	
	# Connect signals
	boss.boss_defeated.connect(_on_boss_defeated)
	boss.boss_damaged.connect(_on_boss_damaged)
	
	print("Boss test with player setup complete!")
	print("Use WASD to move, Space to jump")
	print("Jump on the boss's head to damage it!")

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

func _create_simple_player():
	var player = CharacterBody2D.new()
	player.add_to_group("player")
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 48)
	collision.shape = shape
	player.add_child(collision)
	
	# Add visual
	var sprite = ColorRect.new()
	sprite.size = Vector2(32, 48)
	sprite.color = Color.BLUE
	sprite.position = Vector2(-16, -24)
	player.add_child(sprite)
	
	# Add script
	var script = GDScript.new()
	script.source_code = """
extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle movement
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()

func bounce(force: float = -300.0):
	velocity.y = force
	print("Player bounced!")
"""
	player.set_script(script)
	player.collision_layer = 2
	player.collision_mask = 1
	
	return player

func _on_boss_defeated():
	print("SUCCESS: Boss defeated!")

func _on_boss_damaged(health: int, max_health: int):
	print("Boss damaged! Health: ", health, "/", max_health)