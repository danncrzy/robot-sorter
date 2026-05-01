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
	print("[BOX] on_grabbed() - color: ", box_color)
	_is_held = true
	_holder  = player
	var mc := player.get_node_or_null("MovementComponent")
	if mc:
		mc.set_carrying(true, box_color)
	else:
		print("[BOX] ERROR - MovementComponent not found on player!")
		
	visible = false
	monitoring = false  # Turn off completely so it doesn't trigger anything while held
	box_grabbed.emit(self)

# Added drop_position parameter so it doesn't just spawn inside the player if dropped on floor
func on_dropped(shelf: Node = null, drop_position: Vector2 = Vector2.ZERO) -> void:
	print("[BOX] on_dropped() - Shelf: ", shelf.name if shelf else "None")
	_is_held = false
	
	if _holder:
		var mc := _holder.get_node_or_null("MovementComponent")
		if mc:
			mc.set_carrying(false, "")
	_holder = null

	if shelf:
		visible = false
		monitoring = false # FIX: Keep monitoring off so invisible shelf boxes don't trigger grabs
		print("[BOX] Dropped on shelf. Hiding and keeping monitoring off.")
	else:
		# Dropped on floor
		if drop_position != Vector2.ZERO:
			global_position = drop_position
		visible = true
		monitoring = true # Turn back on so it can be picked up again
		print("[BOX] Dropped on floor at: ", global_position)
		
	box_dropped.emit(self)

func get_color() -> String:
	return box_color

func is_held() -> bool:
	return _is_held
