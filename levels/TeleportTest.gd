extends Node2D

func _ready():
	print("TeleportTest level loaded")
	
	# Connect to teleport gate signals if needed
	var gates = get_tree().get_nodes_in_group("teleport_gates")
	for gate in gates:
		if gate.has_signal("player_teleported"):
			gate.player_teleported.connect(_on_player_teleported)

func _on_player_teleported(from_gate: TeleportGate, to_gate: TeleportGate):
	print("Player teleported from ", from_gate.gate_id, " to ", to_gate.gate_id)
	
	# Add score or other effects when player uses teleport
	if has_node("/root/Game"):
		Game.add_score(50)
		print("Teleport bonus: +50 points!")
