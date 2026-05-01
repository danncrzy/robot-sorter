extends Control

@onready var play_btn:  TextureButton = $PlayBtn
@onready var reset_btn: TextureButton = $ResetBtn

var _player:          CharacterBody2D = null
var _original_script: GDScript = null
var _play_running:    bool = false

const PROXY_HEADER := """
func move(x: int, y: int) -> void:         get_node("MovementComponent").move(x, y)
func step_forward() -> void:               get_node("MovementComponent").step_forward()
func step_back() -> void:                  get_node("MovementComponent").step_back()
func stop() -> void:                       get_node("MovementComponent").stop()
func turn_left() -> void:                  get_node("MovementComponent").turn_left()
func turn_right() -> void:                 get_node("MovementComponent").turn_right()
func rotate_deg(deg: float) -> void:       get_node("MovementComponent").rotate_deg(deg)
func face(direction: String) -> void:      get_node("MovementComponent").face(direction)
func move_right(steps: int = 1) -> void:   get_node("MovementComponent").move_right(steps)
func move_left(steps: int = 1) -> void:    get_node("MovementComponent").move_left(steps)
func move_up(steps: int = 1) -> void:      get_node("MovementComponent").move_up(steps)
func move_down(steps: int = 1) -> void:    get_node("MovementComponent").move_down(steps)
func move_to(x: int, y: int) -> void:      get_node("MovementComponent").move_to(x, y)
func is_moving() -> bool:                  return get_node("MovementComponent").is_moving()
func get_facing() -> String:               return get_node("MovementComponent").get_facing()
func get_grid_position() -> Vector2:       return get_node("MovementComponent").get_grid_position()
func grab() -> void:                       get_node("InteractionComponent").grab()
func drop() -> void:                       get_node("InteractionComponent").drop()
func interact() -> void:                   get_node("InteractionComponent").interact()
func is_holding() -> bool:                 return get_node("InteractionComponent").is_holding()
"""

func _ready() -> void:
	add_to_group("game_controller")
	play_btn.pressed.connect(_on_play)
	reset_btn.pressed.connect(_on_reset)
	await get_tree().process_frame
	_player = get_tree().current_scene.get_node_or_null("GameNodes/Main/Player")
	if _player:
		_original_script = _player.get_script()

func _on_play() -> void:
	if ErrorHandler._error_control and ErrorHandler._error_control.visible:
		return
	if _play_running:
		return
	AudioManager.play_sfx_random_pitch(preload("res://Assets/Sfx/click_8.ogg"))
	_play_running = true

	# ── Lock play, unlock reset ──
	play_btn.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	play_btn.modulate.a    = 0.5          # visual feedback: greyed out
	reset_btn.mouse_filter = Control.MOUSE_FILTER_STOP

	if not _player:
		_play_running = false
		return

	var user_code = ScriptManager.get_content("game_player.gd")
	if user_code == "":
		_play_running = false
		return

	var lines    = user_code.split("\n")
	var filtered := PackedStringArray()
	var skipping_func := false

	for line in lines:
		var stripped = line.strip_edges()
		if stripped.begins_with("func _ready") or stripped.begins_with("func reset"):
			skipping_func = true
			continue
		if skipping_func:
			var is_indented = line.begins_with("\t") or line.begins_with("    ")
			if stripped != "" and not is_indented:
				skipping_func = false
			else:
				continue
		if stripped.begins_with("extends"):              continue
		if stripped.begins_with("var _start_position"):  continue
		filtered.append(line)

	var clean_user_code := "\n".join(filtered)

	var full_code := "extends CharacterBody2D\n" \
		+ PROXY_HEADER \
		+ "\nvar _start_position: Vector2 = Vector2.ZERO\n" \
		+ "func _ready() -> void:\n\t_start_position = global_position\n" \
		+ "func reset() -> void:\n\tget_node(\"MovementComponent\").reset()\n\tglobal_position = _start_position\n" \
		+ clean_user_code

	var src := GDScript.new()
	src.source_code = full_code
	var err := src.reload()
	if err != OK:
		push_error("Compile error: %d" % err)
		_play_running = false
		return

	_player.set_script(src)
	await get_tree().process_frame
	if _player.has_method("run"):
		_player.run()

func _on_reset() -> void:
	if not _player: return
	AudioManager.stop_footsteps()

	reset_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_btn.mouse_filter  = Control.MOUSE_FILTER_STOP
	play_btn.modulate.a    = 1.0
	_play_running          = false

	# Reset mission
	ObjectiveTracker.reset_mission()

	# Reset ObjectiveUI display
	var obj_ui := get_tree().get_first_node_in_group("objective_ui")
	if obj_ui and obj_ui.has_method("reset_display"):
		obj_ui.reset_display()

	if _original_script:
		_player.set_script(_original_script)
	await get_tree().process_frame
	await get_tree().process_frame
	if _player.has_method("reset"):
		_player.reset()
