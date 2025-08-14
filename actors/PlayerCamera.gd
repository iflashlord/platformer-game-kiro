extends Camera2D
class_name PlayerCamera

@export var look_ahead_distance: float = 80.0
@export var smoothing_speed: float = 3.0
@export var dead_zone_width: float = 40.0
@export var dead_zone_height: float = 25.0
@export var vertical_offset: float = -30.0  # Camera slightly above player

var player: CharacterBody2D
var target_position: Vector2
var dead_zone_center: Vector2

func _ready():
	player = get_parent() as CharacterBody2D
	if player == null:
		push_error("PlayerCamera must be child of CharacterBody2D")
		return
	
	# Initialize positions with vertical offset
	target_position = player.global_position + Vector2(0, vertical_offset)
	dead_zone_center = player.global_position
	global_position = target_position
	
	# Set better zoom for closer view without losing details
	zoom = Vector2(1.3, 1.3)

func _process(delta):
	if player == null:
		return
	
	update_dead_zone()
	update_look_ahead()
	smooth_camera_movement(delta)

func update_dead_zone():
	var player_pos = player.global_position
	var camera_pos = global_position
	
	# Check if player is outside dead zone
	var dead_zone_left = dead_zone_center.x - dead_zone_width / 2
	var dead_zone_right = dead_zone_center.x + dead_zone_width / 2
	var dead_zone_top = dead_zone_center.y - dead_zone_height / 2
	var dead_zone_bottom = dead_zone_center.y + dead_zone_height / 2
	
	# Update dead zone center if player moves outside
	if player_pos.x < dead_zone_left:
		dead_zone_center.x = player_pos.x + dead_zone_width / 2
	elif player_pos.x > dead_zone_right:
		dead_zone_center.x = player_pos.x - dead_zone_width / 2
	
	if player_pos.y < dead_zone_top:
		dead_zone_center.y = player_pos.y + dead_zone_height / 2
	elif player_pos.y > dead_zone_bottom:
		dead_zone_center.y = player_pos.y - dead_zone_height / 2

func update_look_ahead():
	var look_ahead_offset = Vector2.ZERO
	
	# Horizontal look-ahead based on velocity
	if abs(player.velocity.x) > 50:
		var direction = sign(player.velocity.x)
		look_ahead_offset.x = direction * look_ahead_distance
	
	# Vertical look-ahead for falling
	if player.velocity.y > 100:
		look_ahead_offset.y = look_ahead_distance * 0.5
	
	target_position = dead_zone_center + look_ahead_offset

func smooth_camera_movement(delta):
	global_position = global_position.lerp(target_position, smoothing_speed * delta)

func shake(intensity: float, duration: float = 0.3):
	FX.camera_shake(self, intensity, duration)