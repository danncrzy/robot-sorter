extends Area2D

# Type the color here in the Inspector (e.g., "red", "blue", "green")
@export var plate_color: String = "red"

func _ready() -> void:
	# Connect the detection signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# ── Player stepped on the plate ───────────────────────────────
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_toggle_walls()

# ── Player stepped off the plate (Comment out if you want it to stay open!) ──
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_toggle_walls()

# ── Toggle Logic ──────────────────────────────────────────────
func _toggle_walls() -> void:
	# Build the group name based on the color (e.g., "red_wall")
	var group_name := plate_color.to_lower() + "_wall"
	
	# Find all walls in the scene that belong to this group
	var walls := get_tree().get_nodes_in_group(group_name)
	
	for wall in walls:
		if not is_instance_valid(wall): continue
		
		# 1. Toggle Visibility (if visible = not visible)
		wall.visible = !wall.visible
		
		# 2. Toggle Collisions so the player can walk through!
		# (If we don't do this, the wall becomes an invisible blocker)
		for child in wall.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				# If the wall just turned invisible, disable collision. If visible, enable it.
				child.set_deferred("disabled", not wall.visible)
