extends Control

@onready var error_bg:      NinePatchRect  = $ErrorBg
@onready var error_message: RichTextLabel  = $ErrorMessage

const ERROR_COLOR   := Color(0.9,  0.2,  0.2,  0.9)
const WARNING_COLOR := Color(0.95, 0.7,  0.1,  0.9)
const LINE_HL_COLOR := Color(0.8,  0.0,  0.0,  0.18)

const PADDING := Vector2(10.0, 8.0)
const LINE_HEIGHT := 10.0       # Height per line of text
const MIN_LINES := 2        # Minimum lines to show
const MAX_LINES := 12     # Maximum lines before scrolling

var _highlighted_lines: Array[int] = []
var _code_edit: CodeEdit = null
var _error_count: int = 0        # Track how many errors we have

func _ready() -> void:
	# Setup background
	error_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	error_bg.modulate = Color(1,1,1,0.2)
	
	# ══════════════════════════════════════
	# 👇 CRITICAL SETTINGS TO FIX OVERFLOW!
	# ══════════════════════════════════════
	error_message.bbcode_enabled = true
	error_message.fit_content = false     # Don't auto-size!
	error_message.clip_contents = true     # Clip overflow!
	error_message.autowrap_mode = TextServer.AUTOWRAP_WORD  # Wrap long lines!
	error_message.scroll_active = true     # Enable scroll if needed
	
	# Set fixed line spacing for consistent height calculation
	error_message.set("theme_override_constants/line_separation", 4)
	
	error_message.modulate = ERROR_COLOR
	
	hide()

func init(code_edit: CodeEdit) -> void:
	_code_edit = code_edit

func show_errors(errors: Array) -> void:
	_clear_highlights()
	
	# Count errors for height calculation
	_error_count = errors.size()
	
	var bb := ""
	for e in errors:
		var line:    int    = e.get("line",    1)
		var msg:     String = e.get("message", "Unknown error")
		bb += "● Baris %d: %s\n" % [line, msg]
		_highlight_line(line)
	
	error_message.text = bb.strip_edges()
	show()
	
	_calculate_and_set_height()

func hide_error() -> void:
	_clear_highlights()
	hide()

func _highlight_line(line: int) -> void:
	if not _code_edit: return
	_code_edit.set_line_background_color(line - 1, LINE_HL_COLOR)
	_highlighted_lines.append(line - 1)

func _clear_highlights() -> void:
	if not _code_edit: return
	for l in _highlighted_lines:
		_code_edit.set_line_background_color(l, Color(0, 0, 0, 0))
	_highlighted_lines.clear()

## ────────────────────── SIMPLE HEIGHT CALCULATION ──────────────────────
func _calculate_and_set_height() -> void:
	# Get number of lines from text
	var line_count := _count_display_lines()
	
	# Clamp between min/max lines
	line_count = clamp(line_count, MIN_LINES, MAX_LINES)
	
	var total_height := (line_count * LINE_HEIGHT) + (PADDING.y * 2.0)
	
	# Apply height
	size.y = total_height
	
	# Update children layout
	_update_layout()

func _count_display_lines() -> int:
	if not error_message or error_message.text.is_empty():
		return MIN_LINES
	
	# Method 1: Count newlines + estimate wraps
	var newline_count := error_message.text.count("\n") + 1
	
	# Check for long lines that might wrap (rough estimate)
	var lines := error_message.text.split("\n")
	var total_visual_lines := 0
	
	for line in lines:
		# Estimate how many visual lines this takes
		# Assuming ~50 chars fit per line at normal font size
		var char_count := line.length()
		var visual_lines_for_this := ceilf(float(char_count) / 50.0)
		total_visual_lines += int(visual_lines_for_this)
	
	return max(total_visual_lines, newline_count)

## ────────────────────── LAYOUT ──────────────────────
func _update_layout() -> void:
	if not is_node_ready():
		return

	var w: float = size.x  
	var h: float = size.y
	var p: Vector2 = PADDING

	# ── Background (fills entire control) ──
	error_bg.position = Vector2(4,4)
	error_bg.size     = Vector2(w - 8, h)

	# ── Message Text (with padding inset) ──
	error_message.position = p
	error_message.size     = Vector2(w - p.x * 2.0, h - p.y * 2.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and visible:
		_update_layout()
