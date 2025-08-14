extends Control

var time_physics_process := 0.0
var control_music := false

@onready var target_speed: float = $SpinSpeed.value
@onready var btn_overlap := $AdvancedGroup/BtnOverlap

func _ready() -> void:
	btn_overlap.clear()
	var modes: Array = SlowMotion.OverlapModes.keys()
	for mode in modes:
		btn_overlap.add_item(mode)
	btn_overlap.select(0)
	
	SlowMotion.slow_motion_started.connect(_on_slowmotion_started)
	SlowMotion.slow_motion_recovered.connect(_on_slowmotion_recover)
	SlowMotion.slow_motion_process.connect(_on_slowmotion_process)
	
	Engine.time_scale = 1.0


func _physics_process(delta: float) -> void:
	time_physics_process += delta
	$LabelPhysicsTime.text = "%.2f" % time_physics_process


func _on_slowmotion_started(target_speed: float):
	print("-- Slow motion STARTED for target speed: %s - start: %.2f" % [str(target_speed), SlowMotion.start_os_time])


func _on_slowmotion_recover():
	print("-- Slow motion RECOVERED - start: %.2f   end: %.2f      delta: %.3f" % [
		SlowMotion.start_os_time,
		SlowMotion.end_os_time,
		SlowMotion.end_os_time - SlowMotion.start_os_time 
	])


func _on_slowmotion_process(progress: float):
	# intensity == 0.0 -> engine running at normal speed
	# intensity == 1.0 -> effect is at its slowest requested value
	var intensity: float = 1.0 + (target_speed - Engine.time_scale) / (1.0 - target_speed)
	
	$BarGroup/ProgressBar.value = progress
	$BarGroup/SpeedBar.value = Engine.time_scale
	$BarGroup/IntensityBar.value = intensity
	if control_music:
		# To make pitch proportional to game speed:
		#$AudioGroup/MusicPlayer.pitch_scale = Engine.time_scale
		
		# Or to slow pitch on its own value range
		$AudioGroup/MusicPlayer.pitch_scale = lerp(
			1.0, # pitch when no effect is happening
			0.5, # pitch at full effect
			intensity)


func _on_button_pressed() -> void:
	var duration = $SpinDuration.value
	target_speed = $SpinSpeed.value
	
	var did_start_new_effect := false
	
	if $BtnAdvanced.button_pressed:
		var ramp_slowdown: float = $AdvancedGroup/SpinSlowdownRamp.value
		var ramp_speedup: float = $AdvancedGroup/SpinSpeedupRamp.value
		
		print("starting slow motion with duration: ", duration, "s, speed: ", target_speed, " s/s", "   ramps: ", ramp_slowdown, ", ", ramp_speedup)
		did_start_new_effect = await SlowMotion.slow_motion(duration, target_speed, ramp_slowdown, ramp_speedup, btn_overlap.selected)
	
	else:
		print("starting slow motion with duration: ", duration, "s, speed: ", target_speed, " s/s")
		did_start_new_effect = await SlowMotion.slow_motion(duration, target_speed)
	
	if did_start_new_effect:
		print("Effect done")
		$BarGroup/ProgressBar.value = 0.0
		$BarGroup/IntensityBar.value = 0.0


func _on_btn_audio_toggled(toggled_on: bool) -> void:
	$AudioGroup.visible = toggled_on
	$AudioGroup/MusicPlayer.playing = toggled_on
	if not toggled_on:
		$AudioGroup/BtnAudioSlowmotion.button_pressed = false
		control_music = false


func _on_btn_audio_slowmotion_toggled(toggled_on: bool) -> void:
	control_music = toggled_on
