# Requirements Document

## Introduction

This feature enhances the flying enemy AI system to make enemies more intelligent and engaging. Currently, flying enemies may get stuck when encountering blockers and lack proper chase detection mechanics. The goal is to implement pathfinding around obstacles and a dynamic chase system that activates when the player is within detection range.

## Requirements

### Requirement 1

**User Story:** As a player, I want flying enemies to navigate around obstacles intelligently, so that they don't get stuck and continue to pose a threat throughout the level.

#### Acceptance Criteria

1. WHEN a flying enemy encounters a blocker (wall, platform, or solid object) THEN it SHALL detect the obstacle within 32 pixels of its collision boundary
2. WHEN a flying enemy detects a blocker in its path THEN it SHALL attempt to find an alternative route around the obstacle
3. WHEN finding an alternative route THEN the enemy SHALL try moving vertically (up or down) by 64 pixels to bypass the obstacle
4. IF vertical movement is blocked THEN the enemy SHALL try horizontal movement (left or right) by 64 pixels
5. WHEN no clear path is found after 3 attempts THEN the enemy SHALL reverse its current direction and continue its original behavior pattern

### Requirement 2

**User Story:** As a player, I want flying enemies to chase me when I'm nearby, so that the gameplay feels more dynamic and engaging.

#### Acceptance Criteria

1. WHEN the player enters within 5 times the flying enemy's collision radius THEN the enemy SHALL switch to chase mode
2. WHEN in chase mode THEN the flying enemy SHALL move directly toward the player's current position
3. WHEN chasing THEN the enemy's movement speed SHALL increase by 50% from its normal patrol speed
4. WHEN the player moves outside of 6 times the enemy's collision radius THEN the enemy SHALL return to its original behavior after 2 seconds
5. WHEN chasing THEN the enemy SHALL still respect obstacle avoidance rules from Requirement 1

### Requirement 3

**User Story:** As a player, I want flying enemies to have smooth and natural movement patterns, so that their behavior feels believable and not robotic.

#### Acceptance Criteria

1. WHEN a flying enemy changes direction due to obstacle avoidance THEN the direction change SHALL be smoothed over 0.3 seconds
2. WHEN transitioning between chase and patrol modes THEN the speed change SHALL be interpolated over 0.5 seconds
3. WHEN avoiding obstacles THEN the enemy SHALL maintain a minimum distance of 16 pixels from solid surfaces
4. WHEN multiple path options are available THEN the enemy SHALL choose the path that requires the least direction change
5. WHEN returning to patrol after chasing THEN the enemy SHALL resume its original patrol pattern from its current position

### Requirement 4

**User Story:** As a developer, I want the flying enemy AI to be performance-efficient, so that multiple enemies can exist in a level without causing frame rate drops.

#### Acceptance Criteria

1. WHEN performing obstacle detection THEN the system SHALL use raycasting with a maximum of 4 rays per enemy per frame
2. WHEN calculating chase detection THEN distance checks SHALL be performed using squared distance to avoid expensive square root operations
3. WHEN multiple flying enemies are present THEN AI calculations SHALL be distributed across frames using a staggered update system
4. WHEN an enemy is off-screen THEN its AI update frequency SHALL be reduced to every 3rd frame
5. WHEN an enemy has been inactive (not chasing, not avoiding obstacles) for 5 seconds THEN it SHALL enter a low-frequency update mode

### Requirement 5

**User Story:** As a level designer, I want to be able to configure flying enemy behavior parameters, so that I can create varied gameplay experiences across different levels.

#### Acceptance Criteria

1. WHEN placing a flying enemy THEN the chase detection radius SHALL be configurable via an exported variable
2. WHEN configuring an enemy THEN the patrol speed and chase speed SHALL be independently adjustable
3. WHEN setting up enemy behavior THEN the obstacle avoidance sensitivity SHALL be configurable (16-64 pixel range)
4. WHEN designing levels THEN enemies SHALL support different AI modes: "patrol_only", "chase_only", and "patrol_and_chase"
5. WHEN an enemy is set to "patrol_only" mode THEN it SHALL ignore the player completely and focus only on obstacle avoidance