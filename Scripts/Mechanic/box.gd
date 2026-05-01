extends Area2D

signal box_grabbed(box: Node)
signal box_dropped(box: Node)

@export_enum("Yellow", "Green") var box_color: String = "Yellow"

var _is_held: bool = false
var _holder:  Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		print("[BOX] Player entered box area: ", name)
		var ic := body.get_node_or_null("InteractionComponent")
		if ic:
			ic.register_nearby_box(self)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		print("[BOX] Player left box area: ", name)
		var ic := body.get_node_or_null("InteractionComponent")
		if ic:
			ic.unregister_nearby_box(self)

func on_grabbed(player: Node) -> void:
	print("[BOX] on_grabbed() — color: ", box_color)
	_is_held = true
	_holder  = player
	var mc := player.get_node_or_null("MovementComponent")
	if mc:
		mc.set_carrying(true, box_color)
		print("[BOX] Carry animation started")
	else:
		print("[BOX] ERROR — MovementComponent not found!")
		for c in player.get_children():
			print("[BOX]   child: ", c.name)
	visible = false
	set_deferred("monitoring", false)
	box_grabbed.emit(self)

func on_dropped(shelf: Node = null) -> void:
	print("[BOX] on_dropped()")
	_is_held = false
	if _holder:
		var mc := _holder.get_node_or_null("MovementComponent")
		if mc:
			mc.set_carrying(false, "")
	_holder = null
	monitoring = true
	if shelf:
		visible = false
	else:
		visible = true
	box_dropped.emit(self)

func get_color() -> String:
	return box_color

func is_held() -> bool:
	return _is_held
