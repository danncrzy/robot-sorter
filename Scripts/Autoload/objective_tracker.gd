extends Node

signal objective_completed(objective: LevelObjective)
signal mission_completed(mission: LevelMission)
signal objective_changed(new_objective: LevelObjective)
signal progress_updated(objective: LevelObjective)

var current_mission: LevelMission = null
const TILE_HINT_SCENE := preload("res://Scenes/UI/tile_hint.tscn")

var _marker_scene: PackedScene = null
var _active_markers: Array[Node] = []
var _player: Node = null

var _tilemap: Node = null
const TILE_SIZE := 16.0

func _ready() -> void:
	add_to_group("objective_tracker")

func init(mission: LevelMission, player: Node) -> void:
	current_mission = mission
	_player         = player

	
	# Find tilemap
	var world: Node = null
	for path in ["GameNodes/Main", "GameNodes/GameMain"]:
		world = player.get_tree().current_scene.get_node_or_null(path)
		if world: break
	if world:
		for path in ["FactoryFloor", "GameFactoryFloor", "TileMap", "TileMapLayer"]:
			var tm := world.get_node_or_null(path)
			if tm: _tilemap = tm; break

	# Snap player to tile (0,0) of the tilemap
	if _tilemap and _tilemap.has_method("map_to_local"):
		var tile_zero = _tilemap.map_to_local(Vector2i(0, 0))
		player.global_position = _tilemap.to_global(tile_zero)
		# Update movement component start position
		var mc := player.get_node_or_null("MovementCompon")
		if mc:
			mc._start_position = player.global_position

	mission.reset()
	_spawn_markers()
	call_deferred("_init_hints", mission)

	# Sync HintContainer grid
	var hint_container := player.get_tree().get_first_node_in_group("hint_container")
	print("HINT CONTAINER: ", hint_container)
	if hint_container:
		hint_container.show_objective_hints(mission.objectives)
	else:
		print("HINT CONTAINER NOT FOUND — is it in the scene and added to group?")
		
func notify_moved_to(_world_pos: Vector2) -> void:
	var obj := _current()
	if not obj: return
	if obj.type != LevelObjective.Type.MOVE_TO_POINT: return

	var tile_pos := Vector2.ZERO
	if _tilemap and _tilemap.has_method("local_to_map"):
		var local    = _tilemap.to_local(_player.global_position)
		var cell     = _tilemap.local_to_map(local)
		# Convert to 1-based to match target_pos
		tile_pos = Vector2(cell.x + 1, cell.y + 1)
	else:
		tile_pos = (_player.global_position / TILE_SIZE) + Vector2(1, 1)

	print("PLAYER TILE (1-based): ", tile_pos, " TARGET: ", obj.target_pos)
	if tile_pos == obj.target_pos:
		_complete_current()

func notify_grabbed(item_id: String) -> void:
	var obj := _current()
	if not obj: return
	if obj.type == LevelObjective.Type.GRAB_ITEM:
		if obj.target_id == "" or obj.target_id == item_id:
			obj._current_count += 1
			progress_updated.emit(obj)
			if obj._current_count >= obj.target_count:
				_complete_current()

func notify_returned_to_rack(rack_id: String) -> void:
	var obj := _current()
	if not obj: return
	if obj.type == LevelObjective.Type.RETURN_TO_RACK:
		if obj.target_id == "" or obj.target_id == rack_id:
			obj._current_count += 1
			progress_updated.emit(obj)
			if obj._current_count >= obj.target_count:
				_complete_current()

func notify_command_used(command_name: String) -> void:
	var obj := _current()
	if not obj: return
	if obj.type == LevelObjective.Type.USE_COMMAND:
		if obj.target_id == command_name:
			_complete_current()

func notify_step_taken() -> void:
	var obj := _current()
	if not obj: return
	if obj.type == LevelObjective.Type.REACH_STEP_COUNT:
		obj._current_count += 1
		progress_updated.emit(obj)
		if obj._current_count >= obj.target_count:
			_complete_current()

# ── Internal ───────────────────────────────────────────────────

func _current() -> LevelObjective:
	if not current_mission: return null
	return current_mission.get_current_objective()

func _complete_current() -> void:
	var obj := _current()
	if not obj: return
	obj._completed = true
	_remove_marker_for(obj)
	objective_completed.emit(obj)
	if current_mission.is_complete():
		mission_completed.emit(current_mission)
	else:
		var next := current_mission.get_current_objective()
		if next:
			objective_changed.emit(next)
			_spawn_marker_for(next)

func _spawn_markers() -> void:
	_clear_markers()
	# Delegate to HintContainer only
	var hint_container := get_tree().get_first_node_in_group("hint_container")
	if hint_container:
		hint_container.show_objective_hints(current_mission.objectives)

func _spawn_marker_for(_obj: LevelObjective) -> void:
	pass  # HintContainer handles this now

func _remove_marker_for(obj: LevelObjective) -> void:
	var hint_container := get_tree().get_first_node_in_group("hint_container")
	if hint_container:
		hint_container.deactivate_hint(
			int(obj.target_pos.x),
			int(obj.target_pos.y)
		)

func _clear_markers() -> void:
	for m in _active_markers:
		if is_instance_valid(m):
			m.queue_free()
	_active_markers.clear()
	var hint_container := get_tree().get_first_node_in_group("hint_container")
	if hint_container:
		hint_container.deactivate_all()
		
func get_current_description() -> String:
	var obj := _current()
	if not obj: return ""
	var progress := obj.get_progress()
	return obj.description + (" " + progress if progress != "" else "")

func get_current_hint() -> String:
	var obj := _current()
	if not obj: return ""
	return obj.hint
	
func reset_mission() -> void:
	if not current_mission: return
	current_mission.reset()
	_spawn_markers()
	var first := current_mission.get_current_objective()
	if first:
		objective_changed.emit(first)

func _init_hints(mission: LevelMission) -> void:
	var hint_container := get_tree().get_first_node_in_group("hint_container")
	print("DEFERRED HINT CONTAINER: ", hint_container)
	if hint_container:
		hint_container.show_objective_hints(mission.objectives)
