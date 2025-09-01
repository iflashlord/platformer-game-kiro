extends Node

# Test script to validate GiantBoss functionality
func _ready():
	print("Testing GiantBoss validation...")
	
	# Test if GiantBoss scene can be loaded
	var boss_scene = preload("res://actors/GiantBoss.tscn")
	if boss_scene:
		print("✅ GiantBoss.tscn loads successfully")
		
		# Try to instantiate it
		var boss_instance = boss_scene.instantiate()
		if boss_instance:
			print("✅ GiantBoss can be instantiated")
			add_child(boss_instance)
			
			# Test basic properties
			if boss_instance.has_method("_ready"):
				print("✅ GiantBoss has _ready method")
			if boss_instance.has_signal("boss_defeated"):
				print("✅ GiantBoss has boss_defeated signal")
			if boss_instance.has_signal("boss_damaged"):
				print("✅ GiantBoss has boss_damaged signal")
				
			# Test node references
			var sprite = boss_instance.get_node_or_null("Sprite")
			if sprite:
				print("✅ Sprite node found")
			else:
				print("❌ Sprite node missing")
				
			var collision = boss_instance.get_node_or_null("CollisionShape2D")
			if collision:
				print("✅ CollisionShape2D node found")
			else:
				print("❌ CollisionShape2D node missing")
				
			boss_instance.queue_free()
		else:
			print("❌ Failed to instantiate GiantBoss")
	else:
		print("❌ Failed to load GiantBoss.tscn")
		
	print("Boss validation complete")
