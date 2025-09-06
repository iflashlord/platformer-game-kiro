# Requirements Document

## Introduction

This feature addresses the flying enemy collision system to ensure proper stomping mechanics. Currently, there are inconsistencies in how flying enemies handle collisions with the player. The goal is to create a clear, reliable system where players can stomp flying enemies from above to defeat them, while side collisions cause the player to lose hearts.

## Requirements

### Requirement 1

**User Story:** As a player, I want to be able to stomp flying enemies from above to defeat them, so that I can eliminate threats while gaining points and maintaining momentum.

#### Acceptance Criteria

1. WHEN the player collides with a flying enemy from above AND the player has downward velocity greater than 50 pixels/second THEN the flying enemy SHALL be defeated immediately
2. WHEN a flying enemy is stomped THEN the player SHALL bounce upward with velocity of -300 pixels/second
3. WHEN a flying enemy is stomped THEN the player SHALL gain points equal to the enemy's point value
4. WHEN a flying enemy is stomped THEN appropriate visual and audio feedback SHALL be played
5. WHEN a flying enemy is stomped THEN the enemy SHALL play a defeat animation and be removed from the scene

### Requirement 2

**User Story:** As a player, I want flying enemies to damage me when I collide with them from the side or below, so that there is risk and challenge in navigating around them.

#### Acceptance Criteria

1. WHEN the player collides with a flying enemy from the side OR from below THEN the player SHALL lose one heart
2. WHEN the player takes damage from a flying enemy THEN the player SHALL be pushed away from the enemy with appropriate force
3. WHEN the player takes damage from a flying enemy THEN the player SHALL become invincible for 3 seconds with visual blinking effect
4. WHEN the player takes damage from a flying enemy THEN appropriate damage visual and audio effects SHALL be played
5. IF the player has no hearts remaining THEN the game over sequence SHALL be triggered

### Requirement 3

**User Story:** As a player, I want consistent collision detection that works reliably across different flying enemy types and movement patterns, so that the gameplay feels fair and predictable.

#### Acceptance Criteria

1. WHEN determining collision direction THEN the system SHALL use the player's position relative to the enemy center with a tolerance of 8 pixels
2. WHEN the player is above the enemy center by more than 8 pixels AND has downward velocity greater than 50 THEN it SHALL be classified as a stomp
3. WHEN collision occurs during player invincibility frames THEN no damage SHALL be applied to the player
4. WHEN multiple flying enemies are in collision range THEN only one collision SHALL be processed per physics frame
5. WHEN a flying enemy is already defeated THEN it SHALL not cause any further collisions with the player

### Requirement 4

**User Story:** As a developer, I want clear visual and audio feedback for different collision types, so that players can understand the game mechanics intuitively.

#### Acceptance Criteria

1. WHEN a flying enemy is stomped THEN a "+point" text effect SHALL appear with orange color and the enemy's point value
2. WHEN a flying enemy is stomped THEN the "enemy_hurt" sound effect SHALL play
3. WHEN a player takes damage from a flying enemy THEN the screen SHALL flash red for 0.15 seconds
4. WHEN a player takes damage from a flying enemy THEN the screen SHALL shake for 8 frames
5. WHEN a flying enemy is defeated by stomping THEN it SHALL fall down with rotation animation before being removed