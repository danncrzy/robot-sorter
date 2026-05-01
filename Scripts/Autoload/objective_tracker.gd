extends Node

signal objective_completed(objective: LevelObjective)
signal mission_completed(mission: LevelMission)
signal objective_changed(new_objective: LevelObjective)
signal progress_updated(objective: LevelObjective)
signal level_completed(stars: int, comment: String, moves: int, tries: int) # 🌟 NEW SIGNAL

var current_mission: LevelMission = null
const TILE_HINT_SCENE := preload("res://Scenes/UI/tile_hint.tscn")

var _marker_scene: PackedScene = null
var _active_markers: Array[Node] = []
var _player: Node = null

var _tilemap: Node = null
const TILE_SIZE := 16.0

# 🌟 STAR TRACKING VARIABLES
var _steps_taken: int = 0
var _commands_executed: int = 0 # Counts code commands (move, grab, etc.)
var _current_tries: int = 0 

func _ready() -> void:
	add_to_group("objective_tracker")

func init(mission: LevelMission, player: Node) -> void:
	current_mission = mission
	_player         = player
	
	# 🌟 RESET TRACKERS ON FRESH LEVEL LOAD
	_steps_taken = 0
	_current_tries = 1 
	
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
		var mc := player.get_node_or_null("MovementCompon")
		if mc:
			mc._start_position = player.global_position

	mission.reset()
	_spawn_markers()
	call_deferred("_init_hints", mission)

	# Sync HintContainer grid
	var hint_container := player.get_tree().get_first_node_in_group("hint_container")
	if hint_container:
		hint_container.show_objective_hints(mission.objectives)
		
		
func notify_command_executed() -> void:
	_commands_executed += 1
	

	
func notify_moved_to(_world_pos: Vector2) -> void:
	var obj := _current()
	if not obj: return
	if obj.type != LevelObjective.Type.MOVE_TO_POINT: return

	var tile_pos := Vector2.ZERO
	if _tilemap and _tilemap.has_method("local_to_map"):
		var local    = _tilemap.to_local(_player.global_position)
		var cell     = _tilemap.local_to_map(local)
		tile_pos = Vector2(cell.x + 1, cell.y + 1)
	else:
		tile_pos = (_player.global_position / TILE_SIZE) + Vector2(1, 1)

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
	print("[TRACKER] notify_returned_to_rack called with rack_id: ", rack_id)
	var obj := _current()
	if not obj:
		print("[TRACKER] FAIL - No current objective!")
		return
		
	print("[TRACKER] Current objective type: ", obj.type, " | target_id: ", obj.target_id, " | current_count: ", obj._current_count, " | target_count: ", obj.target_count)
	
	if obj.type == LevelObjective.Type.RETURN_TO_RACK:
		if obj.target_id == "" or obj.target_id == rack_id:
			obj._current_count += 1
			print("[TRACKER] SUCCESS - Incremented count to: ", obj._current_count)
			progress_updated.emit(obj)
			if obj._current_count >= obj.target_count:
				_complete_current()
		else:
			print("[TRACKER] FAIL - rack_id does not match target_id! (Expected: ", obj.target_id, " Got: ", rack_id, ")")
	else:
		print("[TRACKER] FAIL - Current objective is not RETURN_TO_RACK!")

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


func start_new_try() -> void:
	_current_tries += 1
	_commands_executed = 0 
	reset_mission()

# ── Internal ───────────────────────────────────────────────────

func _current() -> LevelObjective:
	if not current_mission: return null
	return current_mission.get_current_objective()

func _complete_current() -> void:
	var obj := _current()
	if not obj: return
	obj._completed = true
	_remove_marker_for(obj)
	
	AudioManager.play_sfx_random_pitch(preload("res://Assets/Sfx/succes_2.ogg"))
	
	objective_completed.emit(obj)
	
	if current_mission.is_complete():
		AudioManager.play_sfx(preload("res://Assets/Sfx/victory_level.ogg"))
		
		# 🌟 CALCULATE STARS AND EMIT FINISH UI SIGNAL
		var stars := _calculate_stars()
		var comment := _get_comment(stars)
		level_completed.emit(stars, comment, _steps_taken, _current_tries)
		
		mission_completed.emit(current_mission)
		print("🎉 STAGE DONE! Stars: ", stars, " Moves: ", _steps_taken, " Tries: ", _current_tries)
	else:
		var next := current_mission.get_current_objective()
		if next:
			objective_changed.emit(next)
			_spawn_marker_for(next)

# ── Star Calculation Logic ─────────────────────────────────────
func _calculate_stars() -> int:
	var level_data: LevelData = LevelManager.current_level
	if not level_data: return 1 
	
	# 🌟 Now reads three_star_commands / two_star_commands!
	if _commands_executed <= level_data.three_star_commands:
		return 3
	elif _commands_executed <= level_data.two_star_commands:
		return 2
	else:
		return 1

func _get_comment(stars: int) -> String:
	var is_flawless := (_current_tries <= 1)
	
	if is_flawless:
		if stars == 3: return "FLAWLESS! Sekali Percobaan"
		elif stars == 2: return "Hebat Sekali! Tapi bisa lebih cepat ;)"
		else: return "Selesai! Tapi terlalu banyak perintah..."
	else:
		if stars == 3: return "Rute Sempurna! Butuh latihan ya :)"
		elif stars == 2: return "Hebat Sekali! :)"
		else: return "Ayo Coba Lagi!"

# ── Markers & Hints ───────────────────────────────────────────

func _spawn_markers() -> void:
	_clear_markers()
	var hint_container := get_tree().get_first_node_in_group("hint_container")
	if hint_container:
		hint_container.show_objective_hints(current_mission.objectives)

func _spawn_marker_for(_obj: LevelObjective) -> void:
	pass 

func _remove_marker_for(obj: LevelObjective) -> void:
	var hint_container := get_tree().get_first_node_in_group("hint_container")
	if hint_container:
		hint_container.deactivate_hint(int(obj.target_pos.x), int(obj.target_pos.y))

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
	if hint_container:
		hint_container.show_objective_hints(mission.objectives)

func _on_tile_stepped_on(tile_id: String) -> void:
	var obj := _current()
	if not obj: return
	
	if obj.type != LevelObjective.Type.MOVE_TO_POINT: return
	
	var parts := tile_id.split(".")
	if parts.size() != 2: return
	
	var tile_pos := Vector2(int(parts[0]), int(parts[1]))
	if tile_pos == obj.target_pos:
		_complete_current()
