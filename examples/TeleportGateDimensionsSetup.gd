extends Node2D

## Setup script for TeleportGate dimensions demo

@onready var gate_a1: TeleportGate = $TeleportGateA1
@onready var gate_a2: TeleportGate = $TeleportGateA2
@onready var gate_b1: TeleportGate = $TeleportGateB1
@onready var gate_b2: TeleportGate = $TeleportGateB2
@onready var gate_both1: TeleportGate = $TeleportGateBoth1
@onready var gate_both2: TeleportGate = $TeleportGateBoth2

func _ready():
	print("Setting up TeleportGate connections...")
	
	# Connect dimension A gates
	gate_a1.teleport_target = gate_a2
	gate_a2.teleport_target = gate_a1
	
	# Connect dimension B gates
	gate_b1.teleport_target = gate_b2
	gate_b2.teleport_target = gate_b1
	
	# Connect "Both" dimension gates
	gate_both1.teleport_target = gate_both2
	gate_both2.teleport_target = gate_both1
	
	print("TeleportGate connections established:")
	print("- A gates: ", gate_a1.name, " <-> ", gate_a2.name)
	print("- B gates: ", gate_b1.name, " <-> ", gate_b2.name)
	print("- Both gates: ", gate_both1.name, " <-> ", gate_both2.name)