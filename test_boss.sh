#!/bin/bash

# Test the Giant Boss level
# Run this script to quickly test the boss fight

echo "Starting Giant Boss test level..."

# Check if we're on macOS and use the appropriate Godot path
if [[ "$OSTYPE" == "darwin"* ]]; then
    GODOT_PATH="/Applications/Godot.app/Contents/MacOS/Godot"
else
    GODOT_PATH="godot"
fi

# Try simple test first (most reliable)
echo "Running boss test with player..."
"$GODOT_PATH" --main-scene res://test_boss_with_player.tscn

echo "Boss test completed!"