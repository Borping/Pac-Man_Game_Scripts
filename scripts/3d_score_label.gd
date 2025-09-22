extends Label3D

var score_label: Label

func _ready() -> void:
	if score_label == null:
		return

	var points = score_label.cat_score * score_label.multiplier
	text = "+" + str(points)
	print('meats')

	# Update the 2D score label at the same time
	score_label.score += points
	score_label.text = str(score_label.score)
