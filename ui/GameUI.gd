extends Node
class_name GameUI

# Singleton for managing UI state across the game
static var instance: GameUI

@onready var pause_menu: PauseMenu
@onready var results: LevelResults
@onready var touch_controls: Control
@onready var game_hud: CanvasLayer

func _ready():
	instance = self
	
	# Create pause menu if it doesn't exist
	if not pause_menu:
		var pause_scene = preload("res://ui/PauseMenu.tscn")
		pause_menu = pause_scene.instantiate()
		add_child(pause_menu)
	
	# Create results screen if it doesn't exist
	if not results:
		var results_scene = preload("res://ui/Results.tscn")
		results = results_scene.instantiate()
		results.visible = false
		add_child(results)
	
	# Create touch controls if it doesn't exist
	if not touch_controls:
		var touch_scene = preload("res://ui/TouchControls.tscn")
		touch_controls = touch_scene.instantiate()
		add_child(touch_controls)
	
	# Create game HUD if it doesn't exist
	if not game_hud:
		var hud_scene = preload("res://ui/GameHUD.tscn")
		game_hud = hud_scene.instantiate()
		add_child(game_hud)

func show_pause_menu():
	if pause_menu:
		pause_menu.show_pause_menu()

func hide_pause_menu():
	if pause_menu:
		pause_menu.hide_pause_menu()

func show_results():
	if results:
		results.show_results()

func hide_results():
	if results:
		results.hide_results()

func show_hud():
	if game_hud:
		game_hud.show_hud()

func hide_hud():
	if game_hud:
		game_hud.hide_hud()

static func get_instance() -> GameUI:
	return instance
