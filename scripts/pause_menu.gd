extends Control

var can_pause = true

@onready var continue_button: Button = $PanelContainer/VBoxContainer/ContinueButton
@onready var retry_button: Button = $PanelContainer/VBoxContainer/RetryButton
@onready var exit_button: Button = $PanelContainer/VBoxContainer/ExitButton

func _ready():
	continue_button.hide()
	retry_button.hide()
	exit_button.hide()
	
	SignalBus.player_dead.connect(_on_player_dead)
	SignalBus.level_is_transitioning.connect(_on_transition)
	SignalBus.connect("pausable", _on_pausable)
	$AnimationPlayer.play("RESET")

func resume():
	continue_button.hide()
	retry_button.hide()
	exit_button.hide()
	
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")

func pause():
	continue_button.show()
	retry_button.show()
	exit_button.show()
	
	get_tree().paused = true
	$AnimationPlayer.play("blur")
	
func testEsc():
	if !can_pause:
		return
	if Input.is_action_just_pressed("esc") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("esc") and get_tree().paused:
		resume()

func _on_continue_button_pressed() -> void:
	resume()

func _on_retry_button_pressed() -> void:
	resume()
	get_tree().reload_current_scene()

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_transition():
	can_pause = false
	print("transitioned")
	
func _on_pausable():
	can_pause = true
	print("pausable")

func _process(_delta):
	testEsc()

func _on_player_dead():
	can_pause = false
