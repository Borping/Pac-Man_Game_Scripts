extends Label

var score = 0
var multiplier = 1
var cheese_score = 5
var cat_score = 100

@onready var counter: Label = $"../Counter - Label"

func _ready() -> void:
	SignalBus.level = 1
	text = str(score)
	counter.connect("_update_score", _on_update_score)

#called by 3d label
func get_cat_points() -> int:
	return cat_score * multiplier

# called by 3d label
func add_points(amount: int) -> void:
	score += int(amount)
	text = str(score)

func _on_update_score():
	# for cheese
	multiplier = 2 ** (SignalBus.level - 1)
	score += cheese_score * multiplier
	text = str(score)
