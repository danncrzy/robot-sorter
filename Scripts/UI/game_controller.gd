extends Control

@onready var play_btn:  TextureButton = $PlayBtn
@onready var reset_btn: TextureButton = $ResetBtn

var _player: CharacterBody2D = null
var _original_script: GDScript = null
var _play_running: bool = false

# Prepended to user code so built-in commands work without "movement."
const ACTUAL_MOVEMENT_NODE := "GameMovementCompon"
const ACTUAL_INTERACT_NODE := "GameInteractionComponent"

const PROXY_HEADER := """
func move(x: int, y: int) -> void:         get_node("GameMovementCompon").move(x, y)
func step_forward() -> void:               get_node("GameMovementCompon").step_forward()
func step_back() -> void:                  get_node("GameMovementCompon").step_back()
func stop() -> void:                       get_node("GameMovementCompon").stop()
func turn_left() -> void:                  get_node("GameMovementCompon").turn_left()
func turn_right() -> void:                 get_node("GameMovementCompon").turn_right()
func rotate_deg(deg: float) -> void:       get_node("GameMovementCompon").rotate_deg(deg)
func face(direction: String) -> void:      get_node("GameMovementCompon").face(direction)
func move_right(steps: int = 1) -> void:   get_node("GameMovementCompon").move_right(steps)
func move_left(steps: int = 1) -> void:    get_node("GameMovementCompon").move_left(steps)
func move_up(steps: int = 1) -> void:      get_node("GameMovementCompon").move_up(steps)
func move_down(steps: int = 1) -> void:    get_node("GameMovementCompon").move_down(steps)
func move_to(x: int, y: int) -> void:      get_node("GameMovementCompon").move_to(x, y)
func is_moving() -> bool:                  return get_node("GameMovementCompon").is_moving()
func get_facing() -> String:               return get_node("GameMovementCompon").get_facing()
func get_grid_position() -> Vector2:       return get_node("GameMovementCompon").get_grid_position()
func grab() -> void:                       get_node("GameInteractionComponent").grab()
func drop() -> void:                       get_node("GameInteractionComponent").drop()
func interact() -> void:                   get_node("GameInteractionComponent").interact()
func is_holding() -> bool:                 return get_node("GameInteractionComponent").is_holding()
"""

func _ready() -> void:
	if not play_btn.pressed.is_connected(_on_play):
		play_btn.pressed.connect(_on_play)
	if not reset_btn.pressed.is_connected(_on_reset):
		reset_btn.pressed.connect(_on_reset)
	await get_tree().process_frame
	_player = get_tree().current_scene.get_node_or_null(
		"GameNodes/GameMain/GamePlayer"
	)
	if _player:
		# Store original before any hot-swap
		_original_script = _player.get_script()

func _on_play() -> void:
	if _play_running:
		return          # ← Drop every duplicate call, no matter the cause
	_play_running = true

	if not _player: 
		_play_running = false
		return
	print("Movement node: ", _player.get_node_or_null("GameMovementCompon"))
	print("Script content length: ", ScriptManager.get_content("game_player.gd").length())

	var user_code := ScriptManager.get_content("game_player.gd")
	if user_code == "": return

	# Strip extends line and var _start_position — header provides them
	var lines := user_code.split("\n")
	var filtered := PackedStringArray()
	for line in lines:
		var stripped := line.strip_edges()
		if stripped.begins_with("extends"): continue
		if stripped.begins_with("var _start_position"): continue
		if stripped.begins_with("func _ready"): continue
		if stripped.begins_with("func reset"): continue
		filtered.append(line)
	var clean_user_code := "\n".join(filtered)

	var full_code := "extends CharacterBody2D\n" \
		+ PROXY_HEADER \
		+ "\nvar _start_position: Vector2 = Vector2.ZERO\n" \
		+ "func _ready() -> void:\n\t_start_position = global_position\n" \
		+ "func reset() -> void:\n\tget_node(\"GameMovementCompon\").reset()\n\tglobal_position = _start_position\n" \
		+ clean_user_code

	var src := GDScript.new()
	src.source_code = full_code
	var err := src.reload()
	if err != OK:
		push_error("Compile error: %d" % err)
		return

	_player.set_script(src)
	await get_tree().process_frame
	if _player.has_method("run"):
		_player.run()

	_play_running = false

func _on_reset() -> void:
	if not _player: return
	if _original_script:
		_player.set_script(_original_script)
	await get_tree().process_frame
	await get_tree().process_frame  # ← two frames for @onready to rebind
	if _player.has_method("reset"):
		_player.reset()
