extends Node

## Emitted when an effect starts. Not emitted when it's modified via subsequent
## calls to slow_motion() while a previous is running
signal slow_motion_started(target_speed: float)

## Emitted every Engine frame (with varying intervals) while the effect is processing.
## [code]progress[/code] is normalized to the effect duration, and is [b]not[/b] garanteed
## to follow linearity across signal emittances in case effects overlap. (Value will be linear
## for a single effect with no overlap, though.)
signal slow_motion_process(progress: float)

## Emitted when the effect is completely finished and engine is back to it's full normal speed.
signal slow_motion_recovered

# What to do when effects overlap (one slow motion is requested while another is still playing)
enum OverlapModes {
	## Ignores any new effects while a previous is running
	IGNORE_NEW_EFFECT,
	
	## If the new request is for a slower motion, slow down further to the new speed, but keep the
	## current duration
	REPLACE_IF_SLOWER_USE_OLD_DURATION,
	
	## If the new request is for a slower motion, discard the previous and enter the new,
	## using duration from the new one
	REPLACE_IF_SLOWER_USE_NEW_DURATION,
	
	## If the new request is for a slower motion, discard the previous and enter the new, but use the longest of durations
	REPLACE_IF_SLOWER_USE_LONGEST_DURATION,
	
	## Use the slowest speed, and add the duration
	REPLACE_IF_SLOWER_ADD_DURATION,
	
	## If the new request would end later than the current one, regardless of speed, 
	## discard the previous and enter the new, with new speed
	REPLACE_IF_LONGER_USE_NEW_SPEED,
	
	## If the new request would end later than the current one, regardless of speed, 
	## discard the previous and enter the new but use the slowest motion speed
	REPLACE_IF_LONGER_KEEP_SLOWEST_SPEED,
	
	## If the new request is for a slower motion or longer duration, use the slowest speed
	## and calculate a duration so the effect ends to match the one which would end latest
	REPLACE_IF_SLOWER_OR_LONGER_USE_STRONGEST_VALUES,
	
	## Use lowest speed for the duration of the one which would end first,
	## and the speed of the other effect for the remaining duration
	# COMBINE, # TODO - might open a can of worms since there can be an unlimited number of effects - use queue
}
@export var overlap_mode: OverlapModes = OverlapModes.IGNORE_NEW_EFFECT

## Time scale used when recovering from the slow motion effect. Leave at 1.0 unless you know
## what you are doing.
@export var engine_normal_speed := 1.0

var target_duration := 1.0
var target_slow_speed := 0.2

var is_active := false

var enter_speed := 0.0
var recover_speed := 0.0

var enter_time := 0.0
#var sustain_time := 0.0
#var sustain_count := 0.0
var recover_time := 0.0

enum States {
	IDLE,
	ENTER,
	SUSTAIN,
	RECOVER,
}
var current_state := States.IDLE

var last_os_time := 0.0
var start_os_time := 0.0
var end_os_time := 0.0
var current_elapsed_time := 0.0
var expected_leave_sustain_os_time := 0.0
var expected_effect_emd_time := 0.0
var current_progress := 0.0
var progress_step := 0.01

# Handles cases of sign ivnersion whem entering a second effect from a slower first one 
var direction_sign: float = 1.0
var is_enter_inverted: bool = false


func _init():
	set_process(false)



# Returns true if this call caused a new effect, false if one was already playing and
# was modified instead, or if nothing was done for other reasons
func slow_motion(
	duration: float, 
	slow_speed: float = 0.2, 
	enter_ramp_time: float = 0.2, 
	recover_ramp_time: float = 0.4, 
	custom_overlap_mode: OverlapModes = overlap_mode
) -> bool:
	if ((duration <= 0.0) or (slow_speed >= 1.0)) and (current_state == States.IDLE):
		# Let's assume good will and not print any error messages offending the user's intelligence
		# This might have come from math which outputs a brief zero in some edge cases (e.g. when
		# coming from physics impacts) and shoud just be ignored
		return false
	
	if (slow_speed <= 0.0) or (slow_speed > 1.0):
		var used_slow_speed: float = clamp(slow_speed, 0.001, 1.0)
		print_rich("[color=#ffcc00]SlowMotion: Invalid value for time_scale speed. Value will be clamped to valid range. value provided: %s  value used: %s[/color]" % 
		[
			str(slow_speed),
			str(used_slow_speed),
		])
		slow_speed = used_slow_speed
	
	var ramp_sum: float = enter_ramp_time + recover_ramp_time
	if (ramp_sum >= 1.0):
		# User made a mistake. Fix it as best guess
		enter_ramp_time = clamp(enter_ramp_time / ramp_sum, 0.01, 0.49)
		recover_ramp_time = clamp(recover_ramp_time / ramp_sum, 0.01, 0.49)
		print_rich("[color=#ffcc00]SlowMotion: Ramp values sum more than 1.0. Values were corrected as: enter=%s  recover=%s[/color]" % [
			str(enter_ramp_time),
			str(recover_ramp_time)
		])

	# This might be fired when a slow motion effect is already running, and must update accordingly
	# This also means cleanup agt the end is mantatory or things will break
	var must_replace_speed := false
	var must_replace_duration := false
	var must_add_duration := false
	var must_keep_slowest_speed := false
	if current_state != States.IDLE:
		match custom_overlap_mode:
			OverlapModes.IGNORE_NEW_EFFECT:
				print_rich("[color=#777777]SlowMotion: effect ignored as a previous one was playing[/color]")
				return false
			
			OverlapModes.REPLACE_IF_SLOWER_USE_OLD_DURATION:
				if (slow_speed <= target_slow_speed):
					must_replace_speed = true
				else:
					return false
			
			OverlapModes.REPLACE_IF_SLOWER_USE_NEW_DURATION:
				if (slow_speed <= target_slow_speed):
					must_replace_speed = true
					must_replace_duration = true
				else:
					return false
			
			OverlapModes.REPLACE_IF_SLOWER_USE_LONGEST_DURATION:
				if (slow_speed <= target_slow_speed):
					must_replace_speed = true
					var remaining_duration: float = target_duration - current_elapsed_time
					if (duration > remaining_duration):
						must_replace_duration = true
				else:
					return false
			
			OverlapModes.REPLACE_IF_SLOWER_ADD_DURATION:
				if (slow_speed <= target_slow_speed):
					must_replace_speed = true
					must_add_duration = true
				else:
					return false
			
			OverlapModes.REPLACE_IF_LONGER_USE_NEW_SPEED:
				var remaining_duration: float = target_duration - current_elapsed_time
				if (duration >= target_duration):
					must_replace_duration = true
					must_replace_speed = true
				else:
					return false
				pass
			
			OverlapModes.REPLACE_IF_LONGER_KEEP_SLOWEST_SPEED:
				var remaining_duration: float = target_duration - current_elapsed_time
				if (duration >= target_duration):
					must_replace_duration = true
					if (slow_speed < target_slow_speed):
						must_replace_speed = true
				else:
					return false
			
			OverlapModes.REPLACE_IF_SLOWER_OR_LONGER_USE_STRONGEST_VALUES:
				if (slow_speed <= target_slow_speed):
					must_replace_speed = true
				if (duration >= target_duration):
					must_replace_duration = true
				if (not must_replace_speed) and (not must_replace_duration):
					return false
			
			# TODO: split effect in queue
	
	
	
	var current_os_time: float = Time.get_unix_time_from_system()
	
	# Starting a new effect
	if current_state == States.IDLE:
		target_slow_speed = slow_speed
		direction_sign = 1.0
		target_duration = duration
		progress_step = 1.0 / target_duration
		current_progress = 0.0
		
		start_os_time = current_os_time
		last_os_time = start_os_time
		
		# max() avoids division by zero, forcing a minimum ramp time of 1% duration
		enter_time = duration * max(0.01, enter_ramp_time)
		recover_time = duration * max(0.01, recover_ramp_time)
		
		enter_speed = (1.0 - target_slow_speed) / enter_time
		recover_speed = (1.0 - target_slow_speed) / recover_time
		
		#var sustain_time = duration - enter_time - recover_time
		expected_leave_sustain_os_time = start_os_time + duration - recover_time
		
		current_state = States.ENTER
	
	# Update ongoing effect
	else:
		if must_replace_speed:
			target_slow_speed = slow_speed

		if must_add_duration or must_replace_duration:
			if must_add_duration:
				target_duration += duration
			elif must_replace_duration:
				# Replacng duration translates to replacing END TIME, based on current time
				target_duration = (current_os_time + duration) - start_os_time
				print("target_duration: ", target_duration)
		
			# Enter and recover times are still calculated based off last duration, otherwise effect 
			# accumulation drags the ramps
			enter_time = duration * (      max(0.01, enter_ramp_time))
			recover_time = duration * (1.0 - max(0.01, recover_ramp_time))
		
		var expected_start_of_sustain_os_time: float = start_os_time + enter_time
		var expected_start_of_recover_os_time: float = start_os_time + recover_time
		#var remaining_duration: float = (start_os_time + target_duration) - current_os_time
			#var remaining_speed_delta: float = abs(engine_normal_speed - Engine.time_scale)
		
		recover_speed = (1.0 - target_slow_speed) / recover_time
		expected_leave_sustain_os_time = start_os_time + target_duration - recover_time
		
		if current_os_time < expected_start_of_sustain_os_time:
			enter_speed = (1.0 - target_slow_speed) / enter_time
		else:
			# We will return to enter state briefly just to avoid sudden glitches
			enter_speed = (1.0 - target_slow_speed) / 0.01
		
		direction_sign = 1.0 if Engine.time_scale >= target_slow_speed else -1.0
		is_enter_inverted = (direction_sign < 0.0)
		
		current_state = States.ENTER
		_recalculate_progress(current_os_time)
	
	slow_motion_started.emit(target_slow_speed)
	slow_motion_process.emit(0.0) # User processes might be relying on a guaranteed [0, 1] process firing
	
	set_process(true)
	
	await slow_motion_recovered
	return true


func _recalculate_progress(current_os_time: float):
	progress_step = 1.0 / target_duration
	current_elapsed_time = current_os_time - start_os_time
	current_progress = current_elapsed_time / target_duration
	expected_effect_emd_time = start_os_time + target_duration


func _process(_delta: float) -> void:
	var this_time := Time.get_unix_time_from_system()
	var real_delta: float = this_time - last_os_time
	last_os_time = this_time
	
	if current_state != States.IDLE:
		current_elapsed_time += real_delta
		current_progress += progress_step * real_delta
	
	match current_state:
		States.IDLE:
			pass
		
		States.ENTER:
			var time_scale_value: float = Engine.time_scale - direction_sign * enter_speed * real_delta
			if (
				# Normal case
				(not is_enter_inverted) and (time_scale_value < target_slow_speed)
			) or (
				# Speeding up going from a slower effect into a not-so-slow one
				is_enter_inverted and (time_scale_value > target_slow_speed)
			):
				Engine.time_scale = target_slow_speed
				current_state = States.SUSTAIN
			else:
				Engine.time_scale = time_scale_value
			
			slow_motion_process.emit(current_progress)
		
		States.SUSTAIN:
			if this_time >= expected_leave_sustain_os_time:
				current_state = States.RECOVER
				
			slow_motion_process.emit(current_progress)
		
		States.RECOVER:
			var time_scale_value: float = Engine.time_scale + recover_speed * real_delta
			if time_scale_value >= engine_normal_speed:
				Engine.time_scale = engine_normal_speed
				current_state = States.IDLE
				
				set_process(false)
				end_os_time = Time.get_unix_time_from_system()
				
				slow_motion_process.emit(1.0) # User processes might be relying on a guaranteed [0, 1] process firing
				slow_motion_recovered.emit()
			
			else:
				Engine.time_scale = time_scale_value 
				slow_motion_process.emit(current_progress)
