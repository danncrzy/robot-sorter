#Scripts/Autoload/error_handler.gd
extends Node

signal errors_found(errors: Array)
signal errors_cleared

var _text_editor:   TextEditorUI = null
var _error_control: Control      = null
var _check_timer:   Timer        = null

func _ready() -> void:
	_check_timer              = Timer.new()
	_check_timer.wait_time    = 0.8
	_check_timer.one_shot     = true
	_check_timer.timeout.connect(_run_check)
	add_child(_check_timer)

func init(text_editor: TextEditorUI, error_control: Control) -> void:
	_text_editor   = text_editor
	_error_control = error_control
	text_editor.script_content_changed.connect(_on_content_changed)

func _on_content_changed(_script_name: String, _content: String) -> void:
	_check_timer.stop()
	_check_timer.start()

func _run_check() -> void:
	if not _text_editor: return
	var content := _text_editor.get_current_script_content()

	if content.strip_edges() == "":
		errors_cleared.emit()
		if _error_control: _error_control.hide_error()
		_unblock_play()
		return

	# ── Find GDScript language via get_class() — this IS exposed to GDScript ──
	# get_name() → crashes (C++ only)
	# get_language() → crashes (C++ only)  
	# get_class() → ✅ works, inherited from Object
	var lang: ScriptLanguage = null
	for i in Engine.get_script_language_count():
		var l := Engine.get_script_language(i)
		if l.get_class() == "GDScriptLanguage":
			lang = l
			break

	if not lang:
		# Fallback: still safe, no session crash
		var errors := _parse_errors(content)
		if errors.is_empty():
			errors_cleared.emit()
			if _error_control: _error_control.hide_error()
			_unblock_play()
		else:
			errors_found.emit(errors)
			if _error_control: _error_control.show_errors(errors)
			_block_play()
		return

	# ── validate() = parse ONLY, never executes code, never crashes ──────────
	# Returns: { valid: bool, errors: [{line, column, message}], warnings: [...] }
	var result: Dictionary = lang.validate(content, "user_script.gd", true, true)

	if result.get("valid", false):
		errors_cleared.emit()
		if _error_control: _error_control.hide_error()
		_unblock_play()
	else:
		var errors: Array = []
		for e in result.get("errors", []):
			errors.append({
				"line":    e.get("line",    1),
				"message": e.get("message", "Unknown error")
			})
		if errors.is_empty():
			errors.append({ "line": 1, "message": "Unknown error" })
		errors_found.emit(errors)
		if _error_control: _error_control.show_errors(errors)
		_block_play()
		
func _indent_content(content: String) -> String:
	var lines  := content.split("\n")
	var result := PackedStringArray()
	for line in lines:
		result.append("\t" + line)
	return "\n".join(result)

func _parse_errors(content: String) -> Array:
	var errors: Array = []
	var lines         := content.split("\n")
	var open_parens   := 0
	var open_brackets := 0
	var in_multiline_string := false

	for i in lines.size():
		var line     := lines[i]
		var stripped := line.strip_edges()

		# Track multiline strings
		if '"""' in line:
			in_multiline_string = !in_multiline_string
		if in_multiline_string: continue
		if stripped.begins_with("#"): continue

		# Unmatched double quotes
		var dq := 0
		var j  := 0
		while j < line.length():
			var ch := line[j]
			if ch == "\\" : j += 2; continue
			if ch == '"'  : dq += 1
			j += 1
		if dq % 2 != 0:
			errors.append({ "line": i + 1, "message": "Unmatched '\"'" })

		# Unmatched single quotes
		var sq := 0
		j = 0
		while j < line.length():
			var ch := line[j]
			if ch == "\\" : j += 2; continue
			if ch == "'"  : sq += 1
			j += 1
		if sq % 2 != 0:
			errors.append({ "line": i + 1, "message": "Unmatched \"'\"" })

		# Parentheses
		open_parens += line.count("(") - line.count(")")
		if open_parens < 0:
			errors.append({ "line": i + 1, "message": "Unexpected ')'" })
			open_parens = 0

		# Brackets
		open_brackets += line.count("[") - line.count("]")
		if open_brackets < 0:
			errors.append({ "line": i + 1, "message": "Unexpected ']'" })
			open_brackets = 0

		# Colon missing after if/for/while/func/else/elif/match
		if stripped.begins_with("if ")   or stripped.begins_with("elif ") or \
		   stripped.begins_with("for ")  or stripped.begins_with("while ") or \
		   stripped.begins_with("func ") or stripped == "else" or \
		   stripped.begins_with("match "):
			if not stripped.ends_with(":") and not stripped.ends_with("\\"):
				errors.append({ "line": i + 1, "message": "'%s' block missing ':'" % stripped.split(" ")[0] })

	if open_parens > 0:
		errors.append({ "line": lines.size(), "message": "Unclosed '('" })
	if open_brackets > 0:
		errors.append({ "line": lines.size(), "message": "Unclosed '['" })

	return errors

func _block_play() -> void:
	var gc := get_tree().get_first_node_in_group("game_controller")
	if gc:
		gc.play_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gc.play_btn.modulate.a   = 0.4

func _unblock_play() -> void:
	var gc := get_tree().get_first_node_in_group("game_controller")
	if gc and not gc._play_running:
		gc.play_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		gc.play_btn.modulate.a   = 1.0
