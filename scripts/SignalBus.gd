extends Node

@warning_ignore_start("unused_signal")
# global signals
signal cheese_collected
signal player_dead
signal level_completed
signal level_is_transitioning
signal pausable
signal display_score_up
signal cheese_wheel_eaten(pos: Vector3)

# powerups
signal superspeed
signal magnet
signal teleport
signal eat
@warning_ignore_restore("unused_signal")

var level: int = 1 # global level variable
