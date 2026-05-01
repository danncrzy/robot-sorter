extends Node

var _parent:       CharacterBody2D = null
var _held_item:    Node            = null
var _nearby_shelf: Node            = null
var _nearby_box: Node = null

signal item_grabbed(item: Node)
signal item_dropped(item: Node)

func _ready() -> void:
	_parent = get_parent()

func register_nearby_box(box: Node) -> void:
	_nearby_box = box
	print("[IC] Nearby box registered: ", box.name)

func unregister_nearby_box(box: Node) -> void:
	if _nearby_box == box:
		_nearby_box = null
		print("[IC] Nearby box unregistered: ", box.name)
		
func register_nearby_shelf(shelf: Node) -> void:
	_nearby_shelf = shelf
	print("[IC] Nearby shelf registered: ", shelf.name)

func unregister_nearby_shelf(shelf: Node) -> void:
	if _nearby_shelf == shelf:
		_nearby_shelf = null
		print("[IC] Nearby shelf unregistered: ", shelf.name)

func grab() -> void:
	if _held_item:
		print("[GRAB] Already holding: ", _held_item.name)
		return
	if not _nearby_box:
		print("[GRAB] FAIL - no box in range")
		return
		
	print("[GRAB] Grabbing: ", _nearby_box.name)
	_held_item = _nearby_box
	_nearby_box = null
	_held_item.on_grabbed(_parent)
	item_grabbed.emit(_held_item)
	
	var tracker := get_tree().get_first_node_in_group("objective_tracker")
	if tracker:
		var color = _held_item.get_color() if _held_item.has_method("get_color") else ""
		tracker.notify_grabbed(color)

func drop() -> void:
	if not _held_item: return
		
	print("[IC] Drop called. Held item: ", _held_item.name)
	print("[IC] Nearby shelf: ", _nearby_shelf.name if _nearby_shelf else "None")
	
	if _nearby_shelf and _nearby_shelf.has_method("try_receive_box"):
		var accepted = _nearby_shelf.try_receive_box(_held_item)
		print("[IC] Shelf accepted box: ", accepted)
		if accepted:
			item_dropped.emit(_held_item)
			_held_item = null
			return
			
	# No shelf nearby or shelf rejected - drop on the floor
	var drop_pos := _parent.global_position
	var movement := _parent.get_node_or_null("MovementComponent")
	if movement:
		var fv = movement._facing_vector()
		drop_pos = _parent.global_position + Vector2(fv.x, fv.y) * movement.TILE_SIZE

	print("[IC] Dropping on floor at: ", drop_pos)
	if _held_item.has_method("on_dropped"):
		_held_item.on_dropped(null, drop_pos) # Pass null shelf, and the position!
		
	item_dropped.emit(_held_item)
	_held_item = null
	
func interact() -> void:
	pass # Handle other interactions if needed

func is_holding() -> bool:    return _held_item != null
func get_held_item() -> Node: return _held_item

func reset() -> void:
	if _held_item:
		if _held_item.has_method("on_dropped"):
			_held_item.on_dropped()
		_held_item = null
