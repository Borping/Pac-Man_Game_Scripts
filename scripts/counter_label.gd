extends Label

signal _update_score

var cheese_collected = 0
var win_con = 10 # hardcoded for now

func _ready() -> void:
	text = str(cheese_collected) + '/' + str(win_con)
	SignalBus.cheese_collected.connect(_on_cheese_collected)

func _on_cheese_collected() -> void:
	cheese_collected += 1
	emit_signal("_update_score")
	text = str(cheese_collected) + '/' + str(win_con)
	
	if cheese_collected == win_con:
		SignalBus.emit_signal("level_is_transitioning")
		print("Round %d complete!" % SignalBus.level)
		SignalBus.level += 1
		cheese_collected = 0
		
		_update_win_con()
		text = str(cheese_collected) + '/' + str(win_con)


func _update_win_con() -> void:
	match SignalBus.level:
		1: win_con = 10
		2: win_con = 15
		3: win_con = 20
		_: win_con = 25
