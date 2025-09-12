# Analytics

Implemented in `systems/Analytics.gd`. The analytics system is offline by default and designed for privacy.

## Behavior

- `ANALYTICS_ENABLED = true`: Enables local buffering.
- Batches with `BATCH_SIZE` and `FLUSH_INTERVAL`.
- Writes batches to `user://analytics_log.json` for inspection during development.
- No network transmission is performed in this implementation.

## Categories

`enum EventCategory`:
- `GAMEPLAY`
- `UI`
- `PERFORMANCE`
- `ERROR`
- `PROGRESSION`
- `MONETIZATION`

## API

- `track_event(name, category, properties={})`
- `track_level_start(name, attempt_number=1)`
- `track_level_complete(name, time, score, deaths=0)`
- `track_level_fail(name, reason, time_played)`
- `track_ui_interaction(element, action, context="")`
- `track_performance_issue(type, severity, details={})`
- `track_error(type, message, stack_trace="")`
- `track_setting_change(name, old_value, new_value)`

## Privacy

- `opt_out()` clears the queue and halts logging.
- `clear_user_data()` removes the analytics user record (`user://analytics_user.dat`).

