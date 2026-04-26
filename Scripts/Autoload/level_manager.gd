# res://Scripts/Autoload/level_manager.gd
extends Node

var current_level: LevelData = null

var scene_tree_panel: SceneTreePanel = null
var text_editor_ui: TextEditorUI = null

func _ready() -> void:
	_wait_for_ui()
	
func _wait_for_ui() -> void:
	# Loop until both UI panels are found AND fully ready
	while not scene_tree_panel or not text_editor_ui or not scene_tree_panel.is_node_ready() or not text_editor_ui.is_node_ready():
		scene_tree_panel = get_tree().get_first_node_in_group("scene_tree_panel")
		text_editor_ui = get_tree().get_first_node_in_group("text_editor_ui")
		
		if not scene_tree_panel or not text_editor_ui:
			await get_tree().process_frame
		elif not scene_tree_panel.is_node_ready() or not text_editor_ui.is_node_ready():
			await get_tree().process_frame
			
	# Once found and ready, load the level!
	var test_level = load("res://Resources/Levels/level_01.tres")
	if test_level:
		load_level(test_level)

func load_level(level_res: LevelData) -> void:
	current_level = level_res
	_populate_scene_tree()

func _populate_scene_tree() -> void:
	if not current_level or not scene_tree_panel: return
	
	scene_tree_panel.clear_tabs()
	
	for node_def in current_level.nodes:
		var data = {
			"structure": node_def.structure,
			"node_type": node_def.node_type,
			"script_state": node_def.script_state,
			"script_name": node_def.script_name
		}
		
		var node_name = node_def.structure.get_file()
		scene_tree_panel.add_scene_tab(node_name, data)

func open_script_for_node(data: Dictionary) -> void:
	if not text_editor_ui: return
	
	if data.get("script_state") == "enabled" and data.get("script_name") != "":
		var s_name = data["script_name"]
		if not text_editor_ui.get_all_script_names().has(s_name):
			text_editor_ui.add_script(s_name)
		text_editor_ui.open_script(s_name)
		text_editor_ui.open_editor()
