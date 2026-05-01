# res://Scripts/Autoload/level_manager.gd
extends Node

var current_level: LevelData = null
var scene_tree_panel: SceneTreePanel = null
var text_editor_ui: TextEditorUI = null
var _game_root: Node = null

var _instanced_scenes: Array[Node] = []

const SCRIPTS_DIR: String = "res://Scripts/Game/"

func _ready() -> void:
	_wait_for_ui()
	
func _wait_for_ui() -> void:
	while not scene_tree_panel or not text_editor_ui \
	or not scene_tree_panel.is_node_ready() \
	or not text_editor_ui.is_node_ready():
		scene_tree_panel = get_tree().get_first_node_in_group("scene_tree_panel")
		text_editor_ui   = get_tree().get_first_node_in_group("text_editor_ui")
		if not scene_tree_panel or not text_editor_ui:
			await get_tree().process_frame
		elif not scene_tree_panel.is_node_ready() or not text_editor_ui.is_node_ready():
			await get_tree().process_frame

	if current_level:
		load_level(current_level)
	else:
		push_warning("LevelManager: no level queued — did you set current_level before changing scene?")
	
func load_level(level_res: LevelData) -> void:
	current_level = level_res
	_game_root = get_tree().current_scene
	_populate_scene_tree()
	_register_level_scripts()
	_instance_scenes()
	_load_mission()

func _instance_scenes() -> void:
	if not current_level: return

	# Find InstancedScenes container
	var root  := get_tree().current_scene
	var container: Node = null
	for path in ["GameNodes/Main/InstancedScenes", "GameNodes/GameMain/InstancedScenes"]:
		container = root.get_node_or_null(path)
		if container: break

	if not container:
		push_warning("LevelManager: InstancedScenes node not found")
		return

	# Clear previous instances
	for node in _instanced_scenes:
		if is_instance_valid(node):
			node.queue_free()
	_instanced_scenes.clear()

	# Instance each scene link
	for packed in current_level.scene_links:
		if not packed: continue
		var instance := packed.instantiate()
		container.add_child(instance)
		_instanced_scenes.append(instance)
		print("INSTANCED: ", instance.name, " into ", container.name)
func _populate_scene_tree() -> void:
	if not current_level or not scene_tree_panel: return
	scene_tree_panel.clear_tabs()
	for node_def in current_level.nodes:
		# Resolve actual node reference
		var node_ref: Node = null
		if _game_root and node_def.node_path != ^"":
			node_ref = _game_root.get_node_or_null(node_def.node_path)

		var data := {
			"structure":    node_def.structure,
			"node_type":    node_def.node_type,
			"script_state": node_def.script_state,
			"script_name":  node_def.script_name,
			"node_ref":     node_ref,  
		}
		scene_tree_panel.add_scene_tab(node_def.structure.get_file(), data)

func _register_level_scripts() -> void:
	if not current_level: return
	ScriptManager.clear()
	for node_def in current_level.nodes:
		if node_def.script_state == "enabled" and node_def.script_name != "":
			var content := _load_script_content(node_def.script_name)
			ScriptManager.register_script(node_def.script_name, content)
			# Push into editor immediately so tabs exist before user clicks
			if text_editor_ui:
				text_editor_ui.add_script(node_def.script_name, content)

func open_script_for_node(data: Dictionary) -> void:
	if not text_editor_ui: return
	if data.get("script_state") != "enabled": return
	var s_name: String = data.get("script_name", "")
	if s_name == "": return

	# Ensure script exists in editor (guard for late calls)
	if not ScriptManager.has_script(s_name):
		var content := _load_script_content(s_name)
		ScriptManager.register_script(s_name, content)
		text_editor_ui.add_script(s_name, content)

	text_editor_ui.open_script(s_name)
	text_editor_ui.open_editor()

func _load_script_content(script_name: String) -> String:
	var path := SCRIPTS_DIR + script_name
	if not ResourceLoader.exists(path):
		return "# %s\nextends Node\n" % script_name
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "# %s\nextends Node\n" % script_name
	var content := file.get_as_text()
	file.close()
	return content

func _load_mission() -> void:
	print("LOAD MISSION | level_id: ", current_level.level_id)
	var mission_path := "res://Data/Missions/objective_%s.tres" % current_level.level_id
	print("MISSION PATH: ", mission_path)
	print("PATH EXISTS: ", ResourceLoader.exists(mission_path))
	if not ResourceLoader.exists(mission_path): 
		print("MISSION FILE NOT FOUND — aborting")
		return
	var mission: LevelMission = load(mission_path)
	print("MISSION LOADED: ", mission)
	print("OBJECTIVES: ", mission.objectives.size())
	var player := get_tree().current_scene.get_node_or_null("GameNodes/Main/Player")
	print("PLAYER: ", player)
	if mission and player:
		ObjectiveTracker.init(mission, player)
		print("TRACKER INIT DONE")
