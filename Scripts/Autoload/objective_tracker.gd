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

const TILE_SIZE := 32.0

func _ready() -> void:
	add_to_group("objective_tracker")

func init(mission: LevelMission, player: Node) -> void:
	current_mission = mission
	_player         = player
	mission.reset()
	_spawn_markers()
	var first := mission.get_current_objective()
	if first:
		objective_changed.emit(first)

# ── Called by game systems ─────────────────────────────────────

func notify_moved_to(grid_pos: Vector2) -> void:
	var obj := _current()
	if not obj: return
	if obj.type == LevelObjective.Type.MOVE_TO_POINT:
		if grid_pos.is_equal_approx(obj.target_pos):
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
	for obj in current_mission.objectives:
		if not obj.is_complete():
			_spawn_marker_for(obj)

func _spawn_marker_for(obj: LevelObjective) -> void:
	if not obj.show_marker: return
	if obj.type != LevelObjective.Type.MOVE_TO_POINT: return

	var marker := TILE_HINT_SCENE.instantiate()
	marker.set_meta("objective", obj)

	var world := get_tree().current_scene.get_node_or_null("GameNodes/Main")
	if world:
		world.add_child(marker)
		marker.setup(obj.target_pos)

		# Apply best shader params
		var mat := marker.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("glow_color",  Color(0.6,  1.0,  0.4,  1.0))
			mat.set_shader_parameter("intensity",   0.511)
			mat.set_shader_parameter("spread",      0.102)
			mat.set_shader_parameter("pulse_speed", 2.428)

		_active_markers.append(marker)

func _remove_marker_for(obj: LevelObjective) -> void:
	for m in _active_markers:
		if is_instance_valid(m) and m.get_meta("objective", null) == obj:
			m.queue_free()
			_active_markers.erase(m)
			break

func _clear_markers() -> void:
	for m in _active_markers:
		if is_instance_valid(m):
			m.queue_free()
	_active_markers.clear()

func get_current_description() -> String:
	var obj := _current()
	if not obj: return ""
	var progress := obj.get_progress()
	return obj.description + (" " + progress if progress != "" else "")

func get_current_hint() -> String:
	var obj := _current()
	if not obj: return ""
	return obj.hint
