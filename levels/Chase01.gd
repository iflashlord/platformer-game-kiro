extends BaseLevel
class_name Chase01

# The Great Escape - Intense chase level with pursuing wall

@export var chase_speed: float = 100.0
var chase_wall: Node2D

func _ready():
	level_id = "Chase01"
	level_name = "The Great Escape"
	target_score = 600
	time_limit = 300.0  # 5 minutes
	super._ready()

func setup_level():
	setup_chase_mechanics()

func setup_chase_mechanics():
	# Create the pursuing wall
	chase_wall = Node2D.new()
	add_child(chase_wall)
	chase_wall.position.x = -200
	
	if ui and ui.has_method("show_hint"):
		ui.show_hint("RUN! The wall is coming!")

func _process(delta):
	if chase_wall and player:
		# Move the chase wall forward
		chase_wall.position.x += chase_speed * delta
		
		# Check if wall caught the player
		if chase_wall.position.x > player.position.x:
			_on_player_caught_by_wall()

func _on_player_caught_by_wall():
	# Player caught by wall - trigger death
	if player and player.has_method("take_damage"):
		player.take_damage(999)