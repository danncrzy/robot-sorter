extends Control

@onready var error_bg:      NinePatchRect  = $ErrorBg
@onready var error_message: RichTextLabel  = $ErrorMessage

const ERROR_COLOR   := Color(0.9,  0.2,  0.2,  0.9)
const WARNING_COLOR := Color(0.95, 0.7,  0.1,  0.9)
const LINE_HL_COLOR := Color(0.8,  0.0,  0.0,  0.18)

var _highlighted_lines: Array[int] = []
var _code_edit: CodeEdit = null

func _ready() -> void:
	error_bg.mouse_filter    = Control.MOUSE_FILTER_IGNORE
	error_message.bbcode_enabled = true
	error_message.scroll_active = false
	error_message.fit_content   = true
	hide()

func init(code_edit: CodeEdit) -> void:
	_code_edit = code_edit

func show_errors(errors: Array) -> void:
	_clear_highlights()
	var bb := ""
	for e in errors:
		var line:    int    = e.get("line",    1)
		var msg:     String = e.get("message", "Unknown error")
		bb += "[color=#e83333]● Line %d:[/color] %s\n" % [line, msg]
		_highlight_line(line)
	error_message.text = bb.strip_edges()
	show()
	_update_layout()

func hide_error() -> void:
	_clear_highlights()
	hide()

func _highlight_line(line: int) -> void:
	if not _code_edit: return
	# line is 1-based, CodeEdit is 0-based
	_code_edit.set_line_background_color(line - 1, LINE_HL_COLOR)
	_highlighted_lines.append(line - 1)

func _clear_highlights() -> void:
	if not _code_edit: return
	for l in _highlighted_lines:
		_code_edit.set_line_background_color(l, Color(0, 0, 0, 0))
	_highlighted_lines.clear()

func _update_layout() -> void:
	if not is_node_ready(): return
	var w: float = get_parent().size.x
	var pad := 6.0
	position      = Vector2(pad, pad)
	size.x        = w - pad * 2.0
	error_bg.size = size
	error_message.position = Vector2(pad, pad * 0.5)
	error_message.size     = Vector2(size.x - pad * 2.0, size.y)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_layout()
