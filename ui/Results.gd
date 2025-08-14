extends CanvasLayer
class_name Results

@onready var score_value: Label = $ResultsPanel/ScoreSection/ScoreValue
@onready var rank_value: Label = $ResultsPanel/RankSection/RankValue
@onready var relic: Sprite2D = $ResultsPanel/RelicContainer/Relic
@onready var restart_button: Button = $ResultsPanel/ButtonSection/RestartButton
@onready var continue_button: Button = $ResultsPanel/ButtonSection/ContinueButton

# Fruit labels
@onready var apple_label: Label = $ResultsPanel/CollectiblesSection/FruitSection/FruitBreakdown/AppleCount/AppleLabel
@onready var banana_label: Label = $ResultsPanel/CollectiblesSection/FruitSection/FruitBreakdown/BananaCount/BananaLabel
@onready var cherry_label: Label = $ResultsPanel/CollectiblesSection/FruitSection/FruitBreakdown/CherryCount/CherryLabel

# Gem labels
@onready var ruby_label: Label = $ResultsPanel/CollectiblesSection/GemSection/GemBreakdown/RubyCount/RubyLabel
@onready var emerald_label: Label = $ResultsPanel/CollectiblesSection/GemSection/GemBreakdown/EmeraldCount/EmeraldLabel
@onready var diamond_label: Label = $ResultsPanel/CollectiblesSection/GemSection/GemBreakdown/DiamondCount/DiamondLabel

var selected_button_index: int = 0
var menu_buttons: Array[Button] = []

func _ready():
	# Setup button navigation
	menu_buttons = [restart_button, continue_button]
	
	# Connect button signals
	restart_button.pressed.connect(_on_restart_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)
	
	# Pause the game when results are shown
	get_tree().paused = true
	
	# Display results
	display_results()
	
	# Animate the panel
	animate_panel_entrance()
	
	# Start relic animation
	animate_relic()

func _input(event):
	if not visible:
		return
	
	if event.is_action_pressed("ui_left"):
		navigate_menu(-1)
	elif event.is_action_pressed("ui_right"):
		navigate_menu(1)
	elif event.is_action_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		activate_selected_button()
	elif Input.is_action_just_pressed("restart"):
		_on_restart_button_pressed()
	elif Input.is_action_just_pressed("pause"):
		_on_continue_button_pressed()

func navigate_menu(direction: int):
	selected_button_index = (selected_button_index + direction) % menu_buttons.size()
	if selected_button_index < 0:
		selected_button_index = menu_buttons.size() - 1
	
	update_button_focus()

func update_button_focus():
	for i in range(menu_buttons.size()):
		var button = menu_buttons[i]
		if i == selected_button_index:
			button.grab_focus()
			button.modulate = Color.YELLOW
		else:
			button.modulate = Color.WHITE

func activate_selected_button():
	if selected_button_index < menu_buttons.size():
		menu_buttons[selected_button_index].pressed.emit()

func display_results():
	# Display score
	score_value.text = str(Game.get_score())
	
	# Display fruit counts
	apple_label.text = "Apples: " + str(Game.get_fruit_count(0))
	banana_label.text = "Bananas: " + str(Game.get_fruit_count(1))
	cherry_label.text = "Cherries: " + str(Game.get_fruit_count(2))
	
	# Display gem counts
	ruby_label.text = "Rubies: " + str(Game.get_gem_count(0))
	emerald_label.text = "Emeralds: " + str(Game.get_gem_count(1))
	diamond_label.text = "Diamonds: " + str(Game.get_gem_count(3))
	
	# Display rank
	var rank = Game.get_completion_rank()
	rank_value.text = rank
	
	# Color rank based on performance
	match rank:
		"S+", "S":
			rank_value.modulate = Color.GOLD
			relic.modulate = Color.GOLD
		"A":
			rank_value.modulate = Color.GREEN
			relic.modulate = Color.GREEN
		"B":
			rank_value.modulate = Color.BLUE
			relic.modulate = Color.BLUE
		"C":
			rank_value.modulate = Color.ORANGE
			relic.modulate = Color.ORANGE
		"D":
			rank_value.modulate = Color.RED
			relic.modulate = Color.RED
		"F":
			rank_value.modulate = Color.DARK_RED
			relic.modulate = Color.DARK_RED

func animate_panel_entrance():
	var panel = $ResultsPanel
	panel.scale = Vector2.ZERO
	panel.modulate.a = 0.0
	
	var tween = create_tween()
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.5)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.5)
	tween.tween_callback(animate_rank_reveal)

func animate_rank_reveal():
	# Special animation for rank reveal
	rank_value.scale = Vector2.ZERO
	
	var tween = create_tween()
	tween.tween_property(rank_value, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(rank_value, "scale", Vector2.ONE, 0.2)
	
	# Screen flash based on rank
	var rank = Game.get_completion_rank()
	var flash_color = Color.WHITE
	match rank:
		"S+", "S":
			flash_color = Color.GOLD
		"A":
			flash_color = Color.GREEN
		"B":
			flash_color = Color.BLUE
	
	FX.flash_screen(flash_color, 0.3)
	
	# Setup button focus
	update_button_focus()

func animate_relic():
	if not relic:
		return
	
	# Floating animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(relic, "position:y", relic.position.y - 10, 1.5)
	tween.tween_property(relic, "position:y", relic.position.y + 10, 1.5)
	
	# Rotation animation
	var rotation_tween = create_tween()
	rotation_tween.set_loops()
	rotation_tween.tween_property(relic, "rotation", TAU, 4.0)
	
	# Scale pulse animation
	var scale_tween = create_tween()
	scale_tween.set_loops()
	scale_tween.tween_property(relic, "scale", Vector2(1.1, 1.1), 0.8)
	scale_tween.tween_property(relic, "scale", Vector2.ONE, 0.8)

func _on_restart_button_pressed():
	get_tree().paused = false
	Game.restart_game()

func _on_continue_button_pressed():
	get_tree().paused = false
	# Load next level or return to menu
	if LevelLoader.has_next_level():
		LevelLoader.load_next_level()
	else:
		get_tree().change_scene_to_file("res://ui/MainMenu.tscn")

func show_results():
	visible = true
	display_results()
	animate_panel_entrance()
	animate_relic()

func hide_results():
	visible = false
	get_tree().paused = false