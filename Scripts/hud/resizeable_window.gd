class_name ResizableWindow
extends Control

@export var win_min: Vector2 = Vector2(300, 220)
@export var win_max: Vector2 = Vector2(1600, 1000)
@export var titlebar_h: float = 32.0

const RM: int = 6  # resize grab margin px

enum Dir { NONE, N, S, E, W, NE, NW, SE, SW }

var _dir  := Dir.NONE
var _resizing := false
var _moving   := false
var _m0 := Vector2.ZERO  # global mouse at drag start
var _r0 := Rect2()       # rect at drag start

func _ready() -> void: 
	resized.connect(_on_resize)  # signal fires on size change
	await get_tree().process_frame
	_on_resize()  # initial layout pass

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_on_resize()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_m0 = get_global_mouse_position()
			var d := _dir_at(event.position)
			if d != Dir.NONE:
				_dir = d; _resizing = true
				_r0 = Rect2(global_position, size)
			elif event.position.y <= titlebar_h:
				_moving = true
				_r0 = Rect2(global_position, size)
			get_viewport().set_input_as_handled()
		else:
			_resizing = false; _moving = false; _dir = Dir.NONE
	elif event is InputEventMouseMotion:
		if _resizing:
			_do_resize(get_global_mouse_position())
			get_viewport().set_input_as_handled()
		elif _moving:
			global_position = _r0.position + (get_global_mouse_position() - _m0)
			get_viewport().set_input_as_handled()
		else:
			_set_cursor(_dir_at(event.position))

func _dir_at(p: Vector2) -> Dir:
	var l := p.x < RM;         var r := p.x > size.x - RM
	var t := p.y < RM;         var b := p.y > size.y - RM
	if t and l: return Dir.NW; if t and r: return Dir.NE
	if b and l: return Dir.SW; if b and r: return Dir.SE
	if l: return Dir.W;        if r: return Dir.E
	if t: return Dir.N;        if b: return Dir.S
	return Dir.NONE

func _do_resize(gm: Vector2) -> void:
	var d  := gm - _m0
	var np := _r0.position
	var ns := _r0.size
	match _dir:
		Dir.E:  ns.x = clamp(ns.x + d.x, win_min.x, win_max.x)
		Dir.S:  ns.y = clamp(ns.y + d.y, win_min.y, win_max.y)
		Dir.SE: ns = (ns + d).clamp(win_min, win_max)
		Dir.W:
			var w := clampf(ns.x - d.x, win_min.x, win_max.x)
			np.x = _r0.end.x - w; ns.x = w
		Dir.N:
			var h := clampf(ns.y - d.y, win_min.y, win_max.y)
			np.y = _r0.end.y - h; ns.y = h
		Dir.NE:
			var h := clampf(ns.y - d.y, win_min.y, win_max.y)
			np.y = _r0.end.y - h; ns.y = h
			ns.x = clamp(ns.x + d.x, win_min.x, win_max.x)
		Dir.SW:
			var w := clampf(ns.x - d.x, win_min.x, win_max.x)
			np.x = _r0.end.x - w; ns.x = w
			ns.y = clamp(ns.y + d.y, win_min.y, win_max.y)
		Dir.NW:
			var w := clampf(ns.x - d.x, win_min.x, win_max.x)
			var h := clampf(ns.y - d.y, win_min.y, win_max.y)
			np.x = _r0.end.x - w; np.y = _r0.end.y - h; ns = Vector2(w, h)
	global_position = np
	size = ns  # → NOTIFICATION_RESIZED → _on_resize()

func _set_cursor(d: Dir) -> void:
	if   d in [Dir.E,  Dir.W]:  mouse_default_cursor_shape = CURSOR_HSIZE
	elif d in [Dir.N,  Dir.S]:  mouse_default_cursor_shape = CURSOR_VSIZE
	elif d in [Dir.NE, Dir.SW]: mouse_default_cursor_shape = CURSOR_FDIAGSIZE
	elif d in [Dir.NW, Dir.SE]: mouse_default_cursor_shape = CURSOR_BDIAGSIZE
	else:                        mouse_default_cursor_shape = CURSOR_ARROW

func _on_resize() -> void:
	pass  # overridden by subclasses
