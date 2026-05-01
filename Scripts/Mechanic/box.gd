extends Area2D

signal box_grabbed(box: Node)
signal box_dropped(box: Node)

@export_enum("Yellow", "Green") var box_color: String = "Yellow"

var _is_held:   bool = false
var _holder:    Node = null

func on_grabbed(player: Node) -> void:
	_is_held = true
	_holder  = player
	# Tell movement component to use carry animations
	var mc := player.get_node_or_null("MovementCompon")
	if mc:
		mc.set_carrying(true, box_color)
	box_grabbed.emit(self)

func on_dropped(shelf: Node = null) -> void:
	_is_held = false
	if _holder:
		var mc := _holder.get_node_or_null("MovementCompon")
		if mc:
			mc.set_carrying(false, "")
	_holder = null
	box_dropped.emit(self)
	# Hide box from world — it's now on shelf
	if shelf:
		visible = false

func get_color() -> String:
	return box_color

func is_held() -> bool:
	return _is_held
