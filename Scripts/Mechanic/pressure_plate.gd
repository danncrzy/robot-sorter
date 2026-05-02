extends Area2D

# Type the color here in the Inspector (e.g., "red", "blue", "green")
@export var plate_color: String = "red"

func _ready() -> void:
	# We ONLY care when the player steps ON the plate, not when they leave
	body_entered.connect(_on_body_entered)

# ── Player stepped on the button ──────────────────────────────
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_toggle_walls()
		
		# Optional: Add a visual click to the plate here!
		# e.g., $PlateSprite.frame = 1 

# ── Toggle Logic ──────────────────────────────────────────────
func _toggle_walls() -> void:
	# Build the group name based on the color (e.g., "red_wall")
	var group_name := plate_color.to_lower() + "_wall"
	
	# Find all walls in the scene that belong to this group
	var walls := get_tree().get_nodes_in_group(group_name)
	
	for wall in walls:
		if not is_instance_valid(wall): continue
		
		# 1. Toggle Visibility (if visible, make invisible; if invisible, make visible)
		wall.visible = !wall.visible
		
		# 2. Toggle Collisions to match the visibility
		for child in wall.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				# Disable collision if it just turned invisible, enable if it turned visible
				child.set_deferred("disabled", not wall.visible)
