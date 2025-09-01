extends Node2D

# Simple debug script for GiantBoss

func _ready():
	print("=== DEBUG BOSS ===")
	
	# Test if we can load the boss scene
	var boss_scene_path = "res://actors/GiantBoss.tscn"
	if ResourceLoader.exists(boss_scene_path):
		print("✅ Boss scene file exists")
		
		var boss_scene = load(boss_scene_path)
		if boss_scene:
			print("✅ Boss scene loads successfully")
			
			var boss = boss_scene.instantiate()
			if boss:
				print("✅ Boss instantiated successfully")
				print("Boss class name: ", boss.get_class())
				print("Boss script: ", boss.get_script())
				
				# Add to scene and test
				add_child(boss)
				boss.position = Vector2(400, 300)
				
				# Test basic functionality
				await get_tree().process_frame
				print("✅ Boss added to scene successfully")
				
				# Test signals
				if boss.has_signal("boss_defeated"):
					print("✅ boss_defeated signal exists")
				if boss.has_signal("boss_damaged"):
					print("✅ boss_damaged signal exists")
				
			else:
				print("❌ Failed to instantiate boss")
		else:
			print("❌ Failed to load boss scene")
	else:
		print("❌ Boss scene file does not exist at path: ", boss_scene_path)
	
	print("=== DEBUG COMPLETE ===")
