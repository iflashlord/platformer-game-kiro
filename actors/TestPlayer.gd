extends Node2D

@onready var player: Player = $Player

var event_count: int = 0

func _ready():
	print("🧪 TestPlayer scene loaded")
	
	# Check if player exists
	if player:
		print("✅ Player found at position: ", player.position)
		# Connect player signals
		player.jumped.connect(_on_player_jumped)
		player.landed.connect(_on_player_landed)
		player.died.connect(_on_player_died)
	else:
		print("❌ Player not found!")
	
	print("🎮 TestPlayer ready - use WASD/Arrow keys to move, Space to jump")

func _process(_delta):
	if player:
		# Simple debug output every few seconds
		if int(Time.get_time_dict_from_system()["second"]) % 5 == 0 and not has_logged_recent:
			print("🎮 Player status - Position: ", player.position, " Velocity: ", player.velocity, " On floor: ", player.is_on_floor())
			has_logged_recent = true
	elif int(Time.get_time_dict_from_system()["second"]) % 5 != 0:
		has_logged_recent = false

var has_logged_recent: bool = false

func _on_player_jumped():
	print("🚀 Player jumped! Velocity: ", player.velocity.y)

func _on_player_landed():
	print("🏃 Player landed! Position: ", player.position.y)

func _on_player_died():
	print("💀 Player died!")

# Input handling removed - Game singleton handles pause/ESC key
