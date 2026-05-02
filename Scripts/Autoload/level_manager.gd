# res://Scripts/Autoload/level_manager.gd
extends Node

var current_level: LevelData = null
var scene_tree_panel: SceneTreePanel = null
var text_editor_ui: TextEditorUI = null
var _game_root: Node = null
var current_level_index: int  = 0
var level_resources: Array    = []   # Populated by main_menu before scene change

var _instanced_scenes: Array[Node] = []

const SCRIPTS_DIR: String = "res://Scripts/Game/"

func _ready() -> void:
	# Re-run _wait_for_ui every time ANY node is added to the tree.
	# When main.tscn loads, scene_tree_panel and text_editor_ui
	# add themselves — this catches that moment reliably.
	get_tree().node_added.connect(_on_node_added)
	_wait_for_ui()
 
# ── ADD this function ─────────────────────────────────────────
func _on_node_added(node: Node) -> void:
	# Only care about the two UI nodes we need.
	if not (node.is_in_group("scene_tree_panel") or node.is_in_group("text_editor_ui")):
		return
	# Null out stale references from the previous scene so
	# _wait_for_ui re-discovers the fresh instances.
	scene_tree_panel = null
	text_editor_ui   = null
	# Deferred so the node finishes its own _ready() first.
	call_deferred("_wait_for_ui")
 
# ── ADD this helper (called by finish_ui NextBtn) ─────────────
func get_next_scene_path() -> String:
	var next_index := current_level_index + 1
	if next_index < level_resources.size():
		current_level       = level_resources[next_index]
		current_level_index = next_index
		return "res://Scenes/main.tscn"
	return ""
	
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
	var mission_path := "res://Data/Missions/objective_%s.tres" % current_level.level_id

	if not ResourceLoader.exists(mission_path): 

		return
	var mission: LevelMission = load(mission_path)
	var player := get_tree().current_scene.get_node_or_null("GameNodes/Main/Player")

	if mission and player:
		ObjectiveTracker.init(mission, player)

		
