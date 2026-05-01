extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	var tracker := get_tree().get_first_node_in_group("objective_tracker")
	if not tracker: return
	# Force 3-star flawless: 0 commands, 0 tries (triggers "Sekali Percobaan").
	tracker._commands_executed = 0
	tracker._steps_taken       = 0
	tracker._current_tries     = 0
	tracker.level_completed.emit(3, "FLAWLESS! Sekali Percobaan", 0, 0)
