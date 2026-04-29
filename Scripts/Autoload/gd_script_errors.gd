# gdscript_errors.gd  (Autoload name: GDScriptErrors)
# ─────────────────────────────────────────────────────────────────────────────
#  Single source of truth for ALL GDScript error detection and translation.
#  Uses Levenshtein fuzzy matching + dirty token detection for special chars.
#  error_handler.gd calls into this exclusively.
#
#  VERSION 6 — three more fixes:
#    Check B FIX: "funcs run():" no longer skipped — lines ending ":" bypass
#                 _looks_like_expression, so func typos are always caught.
#    Check H FIX: token-based is_for_line → catches "for:" (colon, no variable).
#    Check L EXT: empty-body look-ahead now covers ALL block-starters
#                 (func, for, if, elif, else, while, match, class).
#  Plus all v5/v4/v3 improvements.
# ─────────────────────────────────────────────────────────────────────────────
extends Node

## ═══════════════════════════════════════════════════════════════
##  CANDIDATE LISTS
## ═══════════════════════════════════════════════════════════════

const LINE_KEYWORDS: Array[String] = [
	"extends", "func", "var", "const", "class", "class_name",
	"signal", "enum", "static", "if", "elif", "else", "for",
	"while", "match", "break", "continue", "return", "pass",
	"await", "breakpoint",
]

const ANNOTATIONS: Array[String] = [
	"onready", "export", "tool", "static_unload",
	"export_group", "export_subgroup", "export_range", "export_enum",
	"export_flags", "export_node_path", "export_file", "export_dir",
	"export_color_no_alpha", "export_placeholder", "export_multiline",
	"export_exp_easing", "warning_ignore", "rpc",
]

const TYPE_NAMES: Array[String] = [
	"void", "int", "float", "bool", "String",
	"Vector2", "Vector2i", "Vector3", "Vector3i", "Vector4", "Vector4i",
	"Rect2", "Rect2i", "Color", "Plane", "Quaternion",
	"AABB", "Basis", "Transform2D", "Transform3D",
	"Array", "Dictionary", "Object", "Node", "Node2D", "Node3D",
	"PackedScene", "Resource", "Callable", "StringName", "NodePath", "RID",
	"PackedByteArray", "PackedInt32Array", "PackedInt64Array",
	"PackedFloat32Array", "PackedFloat64Array", "PackedStringArray",
	"PackedVector2Array", "PackedVector3Array", "PackedColorArray",
	"Signal", "Variant",
]

const BUILTIN_TYPES: Array[String] = [
	"Vector2", "Vector2i", "Vector3", "Vector3i", "Vector4", "Vector4i",
	"Rect2", "Rect2i", "Color", "Plane", "Quaternion",
	"AABB", "Basis", "Transform2D", "Transform3D",
	"Array", "Dictionary", "Object", "Node", "Node2D", "Node3D",
	"PackedScene", "Resource", "Callable", "StringName", "NodePath", "RID",
	"PackedByteArray", "PackedInt32Array", "PackedInt64Array",
	"PackedFloat32Array", "PackedFloat64Array", "PackedStringArray",
	"PackedVector2Array", "PackedVector3Array", "PackedColorArray",
	"CharacterBody2D", "CharacterBody3D",
	"RigidBody2D", "RigidBody3D",
	"AnimatableBody2D", "AnimatableBody3D",
	"StaticBody2D", "StaticBody3D",
	"AnimatedSprite2D", "AnimatedSprite3D",
	"Sprite2D", "Sprite3D",
	"CollisionShape2D", "CollisionShape3D",
	"CollisionPolygon2D", "CollisionPolygon3D",
	"Area2D", "Area3D",
	"Camera2D", "Camera3D",
	"Label", "RichTextLabel", "Button", "TextureButton",
	"Control", "Panel", "PanelContainer",
	"HBoxContainer", "VBoxContainer", "GridContainer", "MarginContainer",
	"NinePatchRect", "TextureRect",
	"Timer", "Tween",
	"AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D",
	"AnimationPlayer", "AnimationTree",
	"TileMap", "TileMapLayer",
	"NavigationAgent2D", "NavigationAgent3D",
	"RayCast2D", "RayCast3D",
	"Line2D", "Polygon2D",
	"CPUParticles2D", "GPUParticles2D",
	"Marker2D", "Marker3D",
	"RemoteTransform2D", "RemoteTransform3D",
	"Path2D", "PathFollow2D",
	"MeshInstance3D",
	"DirectionalLight3D", "SpotLight3D", "OmniLight3D",
	"WorldEnvironment", "Environment",
	"VisibleOnScreenNotifier2D", "VisibleOnScreenNotifier3D",
]

## ═══════════════════════════════════════════════════════════════
##  PASS-2  UNDECLARED IDENTIFIER CHECK
##  Collects all declared names in scope, flags unknowns.
## ═══════════════════════════════════════════════════════════════

# GDScript built-in functions always available globally
const BUILTIN_FUNCTIONS: Array[String] = [
	"print", "printerr", "printraw", "print_rich", "push_error", "push_warning",
	"range", "len", "abs", "sign", "ceil", "floor", "round", "sqrt", "pow",
	"min", "max", "clamp", "lerp", "remap", "smoothstep", "move_toward",
	"deg_to_rad", "rad_to_deg", "sin", "cos", "tan", "atan", "atan2",
	"snapped", "wrap", "fmod", "fposmod", "posmod",
	"randf", "randi", "randf_range", "randi_range", "randomize", "seed",
	"str", "int", "float", "bool",
	"typeof", "type_string", "is_instance_of", "is_instance_valid",
	"weakref", "inst_to_dict", "dict_to_inst",
	"load", "preload", "ResourceLoader",
	"get_node", "has_node", "add_child", "remove_child", "queue_free",
	"create_tween", "get_tree", "get_parent", "get_children",
	"emit_signal", "connect", "disconnect", "has_signal",
	"set", "get", "call", "callv", "has_method",
	"await", "yield",
	"linear_to_db", "db_to_linear",
	"bytes_to_var", "var_to_bytes", "var_to_str", "str_to_var",
	"assert", "breakpoint",
	"Vector2", "Vector2i", "Vector3", "Vector3i", "Vector4",
	"Rect2", "Rect2i", "Color", "Transform2D", "Transform3D",
	"Basis", "Quaternion", "Plane", "AABB",
	"Array", "Dictionary", "PackedStringArray", "PackedInt32Array",
	"PackedFloat32Array", "PackedVector2Array", "PackedColorArray",
	"OS", "Engine", "Input", "InputMap", "ProjectSettings",
	"FileAccess", "DirAccess", "JSON",
	"Time", "Performance",
]

# Always-valid bare names (not functions, not types)
const ALWAYS_VALID: Array[String] = [
	"self", "super", "null", "true", "false",
	"PI", "TAU", "INF", "NAN",
	"OK", "FAILED", "ERR_UNAVAILABLE",
	"TYPE_NIL", "TYPE_BOOL", "TYPE_INT", "TYPE_FLOAT", "TYPE_STRING",
	"CONNECT_ONE_SHOT", "CONNECT_DEFERRED",
	"MOUSE_BUTTON_LEFT", "MOUSE_BUTTON_RIGHT", "MOUSE_BUTTON_MIDDLE",
	"KEY_ESCAPE", "KEY_ENTER", "KEY_SPACE",
	"NOTIFICATION_RESIZED", "NOTIFICATION_READY", "NOTIFICATION_PROCESS",
	"SIZE_EXPAND_FILL", "SIZE_EXPAND", "SIZE_SHRINK_BEGIN", "SIZE_SHRINK_CENTER",
	"MOUSE_FILTER_STOP", "MOUSE_FILTER_PASS", "MOUSE_FILTER_IGNORE",
	"PRESET_FULL_RECT", "PRESET_TOP_LEFT", "PRESET_CENTER",
	"HORIZONTAL_ALIGNMENT_LEFT", "HORIZONTAL_ALIGNMENT_CENTER", "HORIZONTAL_ALIGNMENT_RIGHT",
	"VERTICAL_ALIGNMENT_TOP", "VERTICAL_ALIGNMENT_CENTER", "VERTICAL_ALIGNMENT_BOTTOM",
	"CURSOR_ARROW", "CURSOR_HSIZE", "CURSOR_VSIZE", "CURSOR_FDIAGSIZE", "CURSOR_BDIAGSIZE",
	"_delta", "_event", "_process", "_physics_process",
	"global_position", "position", "rotation", "scale", "size",
	"visible", "modulate", "z_index", "name", "owner",
	"velocity", "speed", "direction",
]

## ═══════════════════════════════════════════════════════════════
##  DIRTY TOKEN DETECTION
##
##  A "dirty token" is a whitespace-separated chunk that contains BOTH
##  word characters (a-z A-Z 0-9 _) AND one or more characters that are
##  NEVER valid inside a GDScript identifier.
##
##  Examples:
##    ext/ends         → dirty → cleaned: "extends"
##    Cha!racterBody2D → dirty → cleaned: "CharacterBody2D"
##    f@unc            → dirty → cleaned: "func"   (@ is mid-word, so dirty)
##    vo@id            → dirty → cleaned: "void"
##    get_n&ode        → dirty → cleaned: "get_node"
##
##  NOT dirty (v3 fix):
##    @onready         → @ is at position-0 of chunk → valid annotation prefix
##    $PlayerAnimations→ $ is at position-0 of chunk → valid node-path prefix
## ═══════════════════════════════════════════════════════════════

# Characters that are NEVER valid INSIDE a GDScript identifier.
# IMPORTANT: @ and $ are in this list but are exempted when they appear
# at position 0 of a whitespace-separated chunk (see _find_dirty_tokens).
const DIRTY_CHARS: String = "!@#$%^&*?|~`/\\;"

var _all_types: Array = []

func _ready() -> void:
	_all_types = TYPE_NAMES.duplicate()
	for t in BUILTIN_TYPES:
		if not t in _all_types:
			_all_types.append(t)

## ═══════════════════════════════════════════════════════════════
##  PASS-0  KEYWORD / TYPO CHECK  (fuzzy + dirty token detection)
## ═══════════════════════════════════════════════════════════════

func check_keywords(content: String) -> Array:
	var errors: Array = []
	var lines         := content.split("\n")

	for i in lines.size():
		var raw      := lines[i]
		var stripped := raw.strip_edges()
		if stripped == "" or stripped.begins_with("#"): continue

		# Strip trailing inline comments (outside strings) before analysis.
		var code := _remove_comment(stripped)
		if code.strip_edges() == "": continue

		var clean  := _strip_strings(code)
		var tokens := _tokenize(clean)
		if tokens.is_empty(): continue

		var reported: Dictionary = {}

		# ── A) Annotation names  (@onreedy → @onready) ─────────────────────
		# stripped is used here (not code) so the full @annotation is visible.
		if stripped.begins_with("@"):
			var ann := stripped.substr(1).split("(")[0].split(" ")[0].strip_edges()
			if ann != "" and not ann in ANNOTATIONS:
				var s := _fuzzy_match(ann, ANNOTATIONS, _max_dist(ann))
				if s != "":
					reported[ann] = true
					errors.append({ "line": i + 1,
						"message": 'Anotasi "@%s" tidak dikenal → apakah maksudmu "@%s"?' \
							% [ann, s] })

		# ── B) Line-starting declaration keywords  (funcs→func, vaer→var) ──
		# Lines ending with ":" are always block-starters, never expressions.
		# Bypassing _looks_like_expression for them catches "funcs run():" etc.
		var first = tokens[0]
		var is_block_line := stripped.ends_with(":")
		if not reported.has(first) and (is_block_line or not _looks_like_expression(stripped)):
			if not first in LINE_KEYWORDS and not first.begins_with("_"):
				var s := _fuzzy_match(first, LINE_KEYWORDS, _max_dist(first))
				if s != "":
					reported[first] = true
					errors.append({ "line": i + 1,
						"message": 'Kemungkinan salah ketik kata kunci: "%s" → apakah maksudmu "%s"?' \
							% [first, s] })

		# ── C) Return type after ->  (vaid→void, Voctor2→Vector2) ──────────
		var arrow := clean.find("->")
		if arrow != -1:
			var after  := clean.substr(arrow + 2).strip_edges().trim_suffix(":").strip_edges()
			var rt_tok := _tokenize(after)
			if not rt_tok.is_empty():
				var rt = rt_tok[0]
				if not reported.has(rt) and not rt in _all_types:
					var s := _fuzzy_match(rt, _all_types, _max_dist(rt))
					if s != "":
						reported[rt] = true
						errors.append({ "line": i + 1,
							"message": 'Kemungkinan salah ketik tipe kembalian: "%s" → apakah maksudmu "%s"?' \
								% [rt, s] })

		# ── D) PascalCase tokens → builtin types ────────────────────────────
		for token in tokens:
			if reported.has(token): continue
			if not _is_pascal_case(token): continue
			if token in BUILTIN_TYPES: continue
			var s := _fuzzy_match(token, BUILTIN_TYPES, _max_dist_pascal(token))
			if s != "":
				reported[token] = true
				errors.append({ "line": i + 1,
					"message": 'Kemungkinan salah ketik tipe: "%s" → apakah maksudmu "%s"?' \
						% [token, s] })

		# ── E) DIRTY TOKENS — special chars embedded inside identifiers ─────
		# Catches: ext/ends, Cha!racterBody2D, f@unc, vo@id, Vec!tor2,
		#          get_n&ode, g#et_node, fu_nc (underscore is fine), etc.
		#
		# v3 FIX: @ at chunk[0] = annotation prefix (valid, NOT dirty).
		#          $ at chunk[0] = node-path prefix  (valid, NOT dirty).
		# So @onready and $PlayerAnimations are never flagged here.
		var dirty_results := _find_dirty_tokens(clean)
		for dt in dirty_results:
			var chunk_raw:   String = dt["raw"]
			var chunk_clean: String = dt["cleaned"]
			var bad_chars:   String = dt["bad_chars"]

			if reported.has(chunk_raw): continue

			var suggestion := ""

			# Keyword match
			var s := _fuzzy_match(chunk_clean, LINE_KEYWORDS, _max_dist(chunk_clean))
			if s != "": suggestion = s

			# Type match (PascalCase)
			if suggestion == "" and _is_pascal_case(chunk_clean):
				s = _fuzzy_match(chunk_clean, BUILTIN_TYPES, _max_dist_pascal(chunk_clean))
				if s != "": suggestion = s

			# Annotation match (if @ was the only bad char and it was mid-word)
			if suggestion == "" and "@" in bad_chars:
				s = _fuzzy_match(chunk_clean, ANNOTATIONS, _max_dist(chunk_clean))
				if s != "": suggestion = "@" + s

			# Exact match after cleaning — 100% confident, no need for fuzzy
			var is_exact := (chunk_clean in LINE_KEYWORDS) or \
							(chunk_clean in BUILTIN_TYPES) or \
							(chunk_clean in TYPE_NAMES)

			reported[chunk_raw] = true

			if is_exact:
				errors.append({ "line": i + 1,
					"message": 'Karakter "%s" tidak valid di dalam "%s" → hapus karakter tersebut.' \
						% [bad_chars, chunk_raw] })
			elif suggestion != "":
				errors.append({ "line": i + 1,
					"message": 'Karakter "%s" tidak valid di dalam "%s" → apakah maksudmu "%s"?' \
						% [bad_chars, chunk_raw, suggestion] })
			else:
				errors.append({ "line": i + 1,
					"message": 'Karakter tidak valid "%s" ditemukan di dalam kata "%s".' \
						% [bad_chars, chunk_raw] })

		# ── F) Mid-line # check (comment silently cuts off code) ────────────
		var hash_pos := _find_mid_line_hash(stripped)
		if hash_pos > 0:
			var before := stripped.substr(0, hash_pos).strip_edges()
			if before != "" and not reported.has("__hash__"):
				reported["__hash__"] = true
				errors.append({ "line": i + 1,
					"message": 'Tanda "#" di tengah baris memulai komentar — semua setelah "#" diabaikan oleh GDScript.' })

		# ── G) Missing type specifier after ":" in var/const declarations ───
		# Catches:  var x:          → "Expected type specifier after ':'"
		#           var x: = 5      → same (: followed by = with no type)
		# Safe:     var x: int = 5  → "int" is after the colon, no error.
		#           var x := 5      → ":=" walrus, the colon is part of :=, no error.
		if (stripped.begins_with("var ") or stripped.begins_with("const ")) \
		   and not reported.has("__type_colon__"):
			var tc := _find_type_colon(clean)
			if tc != -1:
				var after_colon := clean.substr(tc + 1).strip_edges()
				# Empty after colon, OR starts with "=" (no type between : and =)
				if after_colon == "" or after_colon.begins_with("="):
					reported["__type_colon__"] = true
					errors.append({ "line": i + 1,
						"message": 'Tipe data tidak ditulis setelah ":" — tulis tipe yang valid (misal: int, String, Vector2) setelah tanda titik dua.' })

		# ── H) Missing or invalid loop variable after "for" ─────────────────
		# Token-based check covers all sub-cases:
		#   "for"    → lone keyword,  tokens == ["for"]
		#   "for:"   → ":" is stripped by tokenizer, leaves ["for"]
		#   "for in" → variable missing before "in"
		var is_for_line = not tokens.is_empty() and tokens[0] == "for"
		if is_for_line and not reported.has("__for_var__"):
			if tokens.size() == 1:
				# "for" or "for:" — nothing meaningful after the keyword.
				reported["__for_var__"] = true
				errors.append({ "line": i + 1,
					"message": 'Pernyataan "for" tidak lengkap — format yang benar: for <variabel> in <iterable>:  (contoh: for i in range(5):).' })
			elif tokens[1] == "in":
				# "for in ..." — variable name missing before "in".
				reported["__for_var__"] = true
				errors.append({ "line": i + 1,
					"message": 'Nama variabel loop tidak ada setelah "for" — tulis nama variabel sebelum "in" (contoh: for i in range(5):).' })

		# ── I) range() called with zero arguments ────────────────────────────
		# Catches:  range()   → "Invalid call for range(). Expected at least 1 argument"
		# Skips substrings like "arrange()" by checking the char before "range(".
		if not reported.has("__range_empty__"):
			var ri := 0
			while true:
				var rp := clean.find("range(", ri)
				if rp < 0: break
				# Make sure "range" is not the tail of a longer word (e.g. "arrange")
				var preceded_by_word := rp > 0 and _is_word_char_code(clean[rp - 1].unicode_at(0))
				if not preceded_by_word:
					# Check that immediately after "range(" there is ")"
					var after_rp := clean.substr(rp + 6).strip_edges()
					if after_rp.begins_with(")"):
						reported["__range_empty__"] = true
						errors.append({ "line": i + 1,
							"message": 'Fungsi "range()" dipanggil tanpa argumen — berikan minimal 1 angka (contoh: range(5) atau range(1, 10)).' })
						break
				ri = rp + 1

	return errors

## ═══════════════════════════════════════════════════════════════
##  DIRTY TOKEN FINDER
## ═══════════════════════════════════════════════════════════════

## Scans a code line (strings already stripped) and returns all
## whitespace-separated chunks that contain both word chars AND dirty chars.
##
## v3 KEY FIX:
##   @ is exempt from "dirty" when it is chunk[0]  → @onready stays clean.
##   $ is exempt from "dirty" when it is chunk[0]  → $PlayerAnimations stays clean.
##
## Returns: Array of { raw, cleaned, bad_chars }
func _find_dirty_tokens(line: String) -> Array:
	var results: Array = []

	# Split on whitespace
	var chunks: Array = []
	var current := ""
	for i in line.length():
		var c := line[i].unicode_at(0)
		if c == 32 or c == 9:          # space / tab
			if current != "": chunks.append(current); current = ""
		else:
			current += line[i]
	if current != "": chunks.append(current)

	for chunk in chunks:
		if chunk.length() < 2: continue   # single char can't be a dirty identifier

		var has_word  := false
		var has_dirty := false
		var bad       := ""

		for ci in chunk.length():
			var ch = chunk[ci]
			var cc = ch.unicode_at(0)
			if _is_word_char_code(cc):
				has_word = true
			elif ch in DIRTY_CHARS:
				# v3 FIX: @ or $ at position 0 of the chunk are valid GDScript
				# prefixes (annotation / node path) — do NOT count as dirty.
				if ci == 0 and (ch == "@" or ch == "$"):
					pass   # valid leading prefix, skip
				else:
					has_dirty = true
					if ch not in bad:
						bad += ch

		if not (has_word and has_dirty): continue

		# Build the cleaned version: keep only word chars.
		# If the chunk started with @/$, strip that leading prefix too.
		var cleaned := ""
		for ci in chunk.length():
			if _is_word_char_code(chunk[ci].unicode_at(0)):
				cleaned += chunk[ci]

		if cleaned == "": continue

		results.append({ "raw": chunk, "cleaned": cleaned, "bad_chars": bad })

	return results

## ═══════════════════════════════════════════════════════════════
##  PASS-1  STRUCTURAL PARSE  (brackets, quotes, colons, indentation)
## ═══════════════════════════════════════════════════════════════

func parse_structural(content: String) -> Array:
	var errors: Array       = []
	var lines               := content.split("\n")
	var open_parens         := 0
	var open_brackets       := 0
	var in_multiline_string := false

	# ── J) Pre-scan: determine indentation style from first indented line ─
	# GDScript requires a single consistent style throughout the file.
	# We find the very first line that starts with whitespace and record
	# whether it uses a tab or a space, then flag every line that differs.
	var indent_style := ""   # "tab" | "space" | "" = not yet determined
	for raw_line in lines:
		if raw_line.length() == 0: continue
		if raw_line[0] == "\t":
			indent_style = "tab";   break
		elif raw_line[0] == " " and raw_line.strip_edges() != "":
			indent_style = "space"; break

	for i in lines.size():
		var line     := lines[i]
		var stripped := line.strip_edges()

		# ── J) Per-line indentation consistency ──────────────────────────
		# Checked on EVERY non-blank line, including comment lines,
		# because the parser rejects mixed indent even inside comments.
		if indent_style != "" and stripped != "" and line.length() > 0:
			var fc := line[0]
			if indent_style == "tab" and fc == " ":
				errors.append({ "line": i + 1,
					"message": 'Indentasi baris ini menggunakan spasi, tapi file ini menggunakan tab — ganti spasi dengan tab (atau tekan Tab di editor).' })
			elif indent_style == "space" and fc == "\t":
				errors.append({ "line": i + 1,
					"message": 'Indentasi baris ini menggunakan tab, tapi file ini menggunakan spasi — ganti tab dengan spasi.' })

		var triple_count := line.count('"""')
		if triple_count % 2 != 0:
			in_multiline_string = !in_multiline_string
		if in_multiline_string: continue
		if stripped.begins_with("#"): continue

		# Unmatched double quotes
		var dq := 0; var j := 0
		while j < line.length():
			var ch := line[j]
			if ch == "\\": j += 2; continue
			if ch == '"' : dq += 1
			j += 1
		if dq % 2 != 0:
			errors.append({ "line": i + 1, "message": "Unmatched '\"'" })

		# Unmatched single quotes
		var sq := 0; j = 0
		while j < line.length():
			var ch := line[j]
			if ch == "\\": j += 2; continue
			if ch == "'" : sq += 1
			j += 1
		if sq % 2 != 0:
			errors.append({ "line": i + 1, "message": "Unmatched \"'\"" })

		# Parentheses balance
		open_parens += line.count("(") - line.count(")")
		if open_parens < 0:
			errors.append({ "line": i + 1, "message": "Unexpected ')'" })
			open_parens = 0

		# Bracket balance
		open_brackets += line.count("[") - line.count("]")
		if open_brackets < 0:
			errors.append({ "line": i + 1, "message": "Unexpected ']'" })
			open_brackets = 0

		# Missing colon after block-starters
		if stripped.begins_with("if ")    or stripped.begins_with("elif ") or \
		   stripped.begins_with("for ")   or stripped.begins_with("while ") or \
		   stripped.begins_with("func ")  or stripped == "else" or \
		   stripped.begins_with("match ") or stripped.begins_with("class "):
			if not stripped.ends_with(":") and not stripped.ends_with("\\") \
			   and not stripped.ends_with(","):
				errors.append({ "line": i + 1,
					"message": "'%s' block missing ':'" % stripped.split(" ")[0] })

		# ── L) Block with no indented body (func / for / if / while / else …) ─
		# Any block-starter ending in ":" whose next non-blank, non-comment
		# line is NOT indented deeper has an empty body → GDScript will crash.
		# Tab depth is the signal: each nested level adds one more leading \t.
		var BLOCK_STARTERS_L := ["for ", "func ", "if ", "elif ", "else", "while ", "match ", "class "]
		var _is_block_starter_L := false
		for _bs in BLOCK_STARTERS_L:
			if stripped.begins_with(_bs) or stripped == _bs.strip_edges():
				_is_block_starter_L = true; break
		if _is_block_starter_L and stripped.ends_with(":"):
			var ni := i + 1
			while ni < lines.size():
				var ns := lines[ni].strip_edges()
				if ns != "" and not ns.begins_with("#"):
					break
				ni += 1
			var block_indent := _count_indent(lines[i])
			var block_word   := stripped.split(" ")[0].trim_suffix(":")
			if ni >= lines.size() or _count_indent(lines[ni]) <= block_indent:
				errors.append({ "line": i + 1,
					"message": 'Blok "%s" tidak memiliki isi — tambahkan setidaknya satu perintah di dalamnya, atau tulis "pass" jika belum ada kode.' % block_word })

	if open_parens > 0:
		errors.append({ "line": lines.size(), "message": "Unclosed '('" })
	if open_brackets > 0:
		errors.append({ "line": lines.size(), "message": "Unclosed '['" })

	return errors

## ═══════════════════════════════════════════════════════════════
##  TRANSLATION  (engine English messages → Bahasa Indonesia)
## ═══════════════════════════════════════════════════════════════

const PATTERNS: Array = [
	# Scope / identifier
	{ "p": "not declared in the current scope",
	  "t": 'Variabel atau fungsi "{ID}" tidak ditemukan di scope ini.' },
	{ "p": "already declared in this scope",
	  "t": 'Nama "{ID}" sudah dipakai di scope yang sama.' },
	{ "p": "shadows a variable",
	  "t": 'Variabel "{ID}" menyembunyikan variabel lain di scope luar.' },
	# Function / method
	{ "p": "nonexistent function",
	  "t": 'Fungsi "{ID}" tidak ada.' },
	{ "p": "function not found in base",
	  "t": 'Fungsi "{ID}" tidak ada di tipe ini.' },
	{ "p": "method not found",
	  "t": 'Metode "{ID}" tidak ditemukan pada tipe ini.' },
	{ "p": "too many arguments",
	  "t": "Terlalu banyak argumen yang diberikan ke fungsi ini." },
	{ "p": "too few arguments",
	  "t": "Argumen yang diberikan kurang dari yang dibutuhkan." },
	{ "p": "expected a return value",
	  "t": "Fungsi ini harus mengembalikan nilai." },
	{ "p": "return type mismatch",
	  "t": "Tipe nilai yang dikembalikan tidak sesuai dengan deklarasi fungsi." },
	{ "p": "cannot return a value",
	  "t": "Fungsi bertipe void tidak boleh mengembalikan nilai." },
	{ "p": "callable is not a method",
	  "t": "Nilai ini bukan sebuah fungsi yang bisa dipanggil." },
	# Type
	{ "p": "cannot assign a value of type",
	  "t": "Tipe data tidak cocok saat menetapkan nilai." },
	{ "p": "cannot convert",
	  "t": "Tidak bisa mengkonversi tipe data ini ke tipe yang diharapkan." },
	{ "p": "invalid assignment",    "t": "Penugasan nilai tidak valid." },
	{ "p": "read-only",
	  "t": "Variabel ini bersifat read-only, tidak bisa diubah nilainya." },
	{ "p": "invalid operand",       "t": "Operand tidak valid untuk operasi ini." },
	{ "p": "invalid operator",      "t": "Operator tidak valid di sini." },
	{ "p": "incompatible",
	  "t": "Tipe data tidak kompatibel untuk operasi ini." },
	{ "p": "is not an object",
	  "t": "Nilai ini bukan objek, tidak bisa mengakses properti atau metode." },
	{ "p": "type mismatch",         "t": "Tipe data tidak sesuai di sini." },
	# Syntax / parse
	{ "p": "expected end of statement",
	  "t": "Pernyataan tidak lengkap atau ada karakter yang tidak terduga." },
	{ "p": "expected newline",
	  "t": "Diharapkan baris baru setelah pernyataan ini." },
	{ "p": "unexpected token",
	  "t": "Token atau simbol yang tidak terduga di sini." },
	{ "p": "unexpected character",  "t": "Karakter yang tidak dikenal di sini." },
	{ "p": "expected indented block after function",
	  "t": 'Fungsi ini tidak memiliki isi — tambahkan setidaknya satu perintah, atau tulis "pass".' },
	{ "p": "expected indented block",
	  "t": "Blok kode setelah pernyataan ini harus di-indent — tambahkan isi blok, atau tulis 'pass'." },
	{ "p": "unindent does not match",
	  "t": "Indentasi tidak konsisten — periksa jumlah spasi atau tab." },
	{ "p": "unexpected indent",
	  "t": "Indentasi tidak terduga di baris ini." },
	{ "p": "used space character for indentation",
	  "t": "Baris ini menggunakan spasi untuk indentasi, tapi file ini menggunakan tab — ganti spasi dengan tab." },
	{ "p": "used tab character for indentation",
	  "t": "Baris ini menggunakan tab untuk indentasi, tapi file ini menggunakan spasi — ganti tab dengan spasi." },
	{ "p": "expected ':'",          "t": "Tanda titik dua ':' hilang di akhir baris ini." },
	{ "p": "missing ':'",           "t": "Tanda titik dua ':' hilang di akhir baris ini." },
	{ "p": "expected '('",          "t": "Tanda kurung buka '(' tidak ada." },
	{ "p": "expected ')'",          "t": "Tanda kurung tutup ')' tidak ada." },
	{ "p": "expected '['",          "t": "Tanda kurung siku buka '[' tidak ada." },
	{ "p": "expected ']'",          "t": "Tanda kurung siku tutup ']' tidak ada." },
	{ "p": "expected expression",   "t": "Ekspresi tidak lengkap atau kosong di sini." },
	{ "p": "expected identifier",
	  "t": "Diharapkan nama variabel atau fungsi yang valid di sini." },
	{ "p": "unexpected end of file",
	  "t": "File berakhir terlalu cepat — mungkin ada blok yang belum ditutup." },
	{ "p": "unmatched",             "t": "Tanda kutip atau kurung tidak berpasangan." },
	{ "p": "unclosed '('",          "t": "Tanda kurung '(' tidak ditutup." },
	{ "p": "unclosed '['",          "t": "Tanda kurung siku '[' tidak ditutup." },
	{ "p": "unexpected ')'",        "t": "Tanda ')' muncul tanpa ada '(' sebelumnya." },
	{ "p": "unexpected ']'",        "t": "Tanda ']' muncul tanpa ada '[' sebelumnya." },
	# Control flow
	{ "p": "return outside function",
	  "t": "Pernyataan 'return' digunakan di luar fungsi." },
	{ "p": "break outside loop",
	  "t": "Pernyataan 'break' digunakan di luar loop." },
	{ "p": "continue outside loop",
	  "t": "Pernyataan 'continue' digunakan di luar loop." },
	{ "p": "await not in async",
	  "t": "'await' hanya bisa dipakai di dalam fungsi async." },
	# Property / member
	{ "p": "property not found",
	  "t": 'Properti "{ID}" tidak ada di objek ini.' },
	{ "p": "member not found",
	  "t": 'Anggota "{ID}" tidak ditemukan di tipe ini.' },
	{ "p": "cannot access member",
	  "t": "Tidak bisa mengakses anggota dari objek yang mungkin null." },
	{ "p": "is not a valid member of",
	  "t": 'Nama "{ID}" bukan anggota yang valid dari tipe ini.' },
	# Signal
	{ "p": "signal not declared",
	  "t": 'Sinyal "{ID}" tidak dideklarasikan.' },
	{ "p": "signal already exists",
	  "t": 'Sinyal "{ID}" sudah dideklarasikan sebelumnya.' },
	# Class / extends
	{ "p": "class not found",       "t": 'Kelas "{ID}" tidak ditemukan.' },
	{ "p": "invalid extends",
	  "t": "Kelas induk yang dipakai di 'extends' tidak valid." },
	{ "p": "cannot extend",         "t": "Kelas ini tidak bisa di-extends." },
	{ "p": "cyclic inheritance",
	  "t": "Ditemukan siklus pewarisan — kelas tidak boleh mewarisi dirinya sendiri." },
	# Annotation
	{ "p": "invalid annotation",
	  "t": "Anotasi ini tidak valid atau dipakai di tempat yang salah." },
	{ "p": "unknown annotation",    "t": "Anotasi ini tidak dikenal." },
	# Variable / constant
	{ "p": "constant value must be a literal",
	  "t": "Nilai 'const' harus berupa nilai tetap (literal), bukan variabel." },
	{ "p": "cannot assign to constant",
	  "t": "Konstanta tidak bisa diubah nilainya setelah dideklarasikan." },
	{ "p": "variable is not assigned",
	  "t": 'Variabel "{ID}" dipakai sebelum diberi nilai.' },
	# Structural (from parse_structural)
	{ "p": "block missing ':'",
	  "t": "Blok kode membutuhkan tanda titik dua ':' di akhir baris ini." },
	# Pass-0 G/H/I syntax checks (also used as fallback for engine messages)
	{ "p": "expected type specifier after",
	  "t": 'Tipe data tidak ditulis setelah ":" — tulis tipe yang valid (misal: int, String, Vector2).' },
	{ "p": "expected loop variable",
	  "t": 'Nama variabel loop tidak ada setelah "for" — tulis nama variabel sebelum "in" (contoh: for i in range(5):).' },
	{ "p": "expected at least 1 argument",
	  "t": 'Fungsi "range()" dipanggil tanpa argumen — berikan minimal 1 angka (contoh: range(5) atau range(1, 10)).' },
	# Warnings
	{ "p": "unused variable",
	  "t": 'Variabel "{ID}" dideklarasikan tapi tidak pernah digunakan.' },
	{ "p": "unused parameter",
	  "t": 'Parameter "{ID}" tidak pernah digunakan di dalam fungsi.' },
	{ "p": "return value discarded", "t": "Nilai kembalian fungsi ini diabaikan." },
	{ "p": "narrowing conversion",
	  "t": "Konversi tipe mempersempit nilai (misalnya float ke int)." },
	{ "p": "integer division",
	  "t": "Pembagian antar integer menghasilkan integer, bukan float." },
]

func translate(msg: String) -> String:
	if msg == "": return ""
	var ml := msg.to_lower()
	for entry in PATTERNS:
		if (entry["p"] as String).to_lower() in ml:
			var t: String = entry["t"]
			if "{ID}" in t:
				t = t.replace("{ID}", _extract_quoted(msg))
			return t
	return "Kesalahan: " + msg

## ═══════════════════════════════════════════════════════════════
##  LEVENSHTEIN FUZZY MATCHING
## ═══════════════════════════════════════════════════════════════

func _levenshtein(a: String, b: String) -> int:
	var la := a.length(); var lb := b.length()
	if la == 0: return lb
	if lb == 0: return la
	if la > 40 or lb > 40: return 99

	var prev := PackedInt32Array(); var curr := PackedInt32Array()
	prev.resize(lb + 1);             curr.resize(lb + 1)
	for j in (lb + 1): prev[j] = j

	for i in range(1, la + 1):
		curr[0] = i
		for j in range(1, lb + 1):
			var cost := 0 if a[i - 1] == b[j - 1] else 1
			curr[j] = mini(mini(curr[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost)
		var tmp := prev; prev = curr; curr = tmp

	return prev[lb]

func _fuzzy_match(token: String, candidates: Array, max_dist: int) -> String:
	if token in candidates: return ""
	var best_dist := max_dist + 1; var best := ""; var tl := token.to_lower()
	for c in candidates:
		var d := _levenshtein(tl, (c as String).to_lower())
		if d < best_dist: best_dist = d; best = c
	return best if best_dist <= max_dist else ""

func _max_dist(token: String) -> int:
	var l := token.length()
	if l <= 3: return 1
	if l <= 6: return 2
	return 2

func _max_dist_pascal(token: String) -> int:
	return 1 if token.length() <= 5 else 2

## ═══════════════════════════════════════════════════════════════
##  PRIVATE HELPERS
## ═══════════════════════════════════════════════════════════════

## Count the number of leading whitespace characters in a line.
## Used by check L to compare indentation depth between two lines.
func _count_indent(line: String) -> int:
	var count := 0
	for ch in line:
		if ch == "\t" or ch == " ":
			count += 1
		else:
			break
	return count

## Remove everything from the first unquoted # onward (inline comment strip).
func _remove_comment(line: String) -> String:
	var in_str := false; var str_ch := ""; var i := 0
	while i < line.length():
		var ch := line[i]
		if not in_str:
			if ch == "#": return line.substr(0, i)
			if ch == '"' or ch == "'": in_str = true; str_ch = ch
		else:
			if ch == "\\": i += 1
			elif ch == str_ch: in_str = false
		i += 1
	return line

## Find position of first # that is NOT inside a string and NOT at pos 0.
## Returns -1 if none found.
func _find_mid_line_hash(line: String) -> int:
	var in_str := false; var str_ch := ""; var i := 0
	while i < line.length():
		var ch := line[i]
		if not in_str:
			if ch == "#" and i > 0: return i
			if ch == '"' or ch == "'": in_str = true; str_ch = ch
		else:
			if ch == "\\": i += 1
			elif ch == str_ch: in_str = false
		i += 1
	return -1

## Returns true when a line looks like an expression/assignment, not a declaration.
func _looks_like_expression(stripped: String) -> bool:
	if stripped.contains("=") and not stripped.contains("->"):
		return true
	if stripped.begins_with("_"):
		return true
	if stripped.contains("("):
		var tok := _tokenize(_strip_strings(stripped))
		if not tok.is_empty():
			if not tok[0] in ["func", "if", "elif", "while", "for", "match", "class"]:
				return true
	return false

## Find the position of the first ":" in a line that is NOT part of ":=".
## Used by check G to detect missing type specifiers in var/const lines.
## Returns -1 if no such colon exists.
func _find_type_colon(line: String) -> int:
	for k in line.length():
		if line[k] == ":":
			# Skip ":=" — that is the walrus / infer operator, not a type colon.
			if k + 1 < line.length() and line[k + 1] == "=":
				continue
			return k
	return -1

## Replace string contents with spaces (prevents false matches inside strings).
func _strip_strings(line: String) -> String:
	var result := ""; var in_str := false; var str_ch := ""; var i := 0
	while i < line.length():
		var ch := line[i]
		if not in_str:
			if ch == '"' or ch == "'": in_str = true; str_ch = ch; result += " "
			else: result += ch
		else:
			if ch == "\\": i += 1
			elif ch == str_ch: in_str = false
			result += " "
		i += 1
	return result

## Split into pure word-char tokens (a-z A-Z 0-9 _).
func _tokenize(line: String) -> Array:
	var tokens: Array = []; var current := ""
	for i in line.length():
		var c := line[i].unicode_at(0)
		if _is_word_char_code(c): current += line[i]
		else:
			if current != "": tokens.append(current); current = ""
	if current != "": tokens.append(current)
	return tokens

func _is_word_char_code(c: int) -> bool:
	return (c >= 97 and c <= 122) or (c >= 65 and c <= 90) \
		   or (c >= 48 and c <= 57) or c == 95

func _is_pascal_case(s: String) -> bool:
	if s.length() < 2: return false
	var c := s[0].unicode_at(0)
	return c >= 65 and c <= 90

func _extract_quoted(msg: String) -> String:
	var dq_o := msg.find('"');  var dq_c := msg.find('"', dq_o + 1)
	if dq_o != -1 and dq_c != -1: return msg.substr(dq_o + 1, dq_c - dq_o - 1)
	var sq_o := msg.find("'");  var sq_c := msg.find("'", sq_o + 1)
	if sq_o != -1 and sq_c != -1: return msg.substr(sq_o + 1, sq_c - sq_o - 1)
	return msg
	
	
func check_undeclared(content: String) -> Array:
	var errors: Array = []
	var lines := content.split("\n")

	# ── Step 1: collect global scope names ──────────────────────
	var global_names: Dictionary = {}
	for kw in LINE_KEYWORDS:       global_names[kw]  = true
	for kw in ANNOTATIONS:         global_names[kw]  = true
	for kw in TYPE_NAMES:          global_names[kw]  = true
	for kw in BUILTIN_TYPES:       global_names[kw]  = true
	for kw in BUILTIN_FUNCTIONS:   global_names[kw]  = true
	for kw in ALWAYS_VALID:        global_names[kw]  = true

	# Collect class-level var/const/func/signal names
	var func_names: Dictionary = {}
	for line in lines:
		var s := line.strip_edges()
		if s.begins_with("var ")    or s.begins_with("const ") \
		or s.begins_with("@onready var ") or s.begins_with("@export var "):
			var name := _extract_declared_name(s)
			if name != "": global_names[name] = true
		elif s.begins_with("func "):
			var fname := _extract_func_name(s)
			if fname != "":
				global_names[fname] = true
				func_names[fname]   = true
		elif s.begins_with("signal "):
			var sname := s.substr(7).split("(")[0].strip_edges()
			if sname != "": global_names[sname] = true
		elif s.begins_with("enum "):
			var ename := s.substr(5).split("{")[0].strip_edges()
			if ename != "": global_names[ename] = true
		elif s.begins_with("class_name "):
			var cname := s.substr(11).strip_edges()
			if cname != "": global_names[cname] = true

	# ── Step 2: per-function scope check ────────────────────────
	var in_func       := false
	var func_scope:   Dictionary = {}
	var func_indent   := 0
	var current_func  := ""

	for i in lines.size():
		var raw      := lines[i]
		var stripped := raw.strip_edges()
		if stripped == "" or stripped.begins_with("#"): continue

		var indent := _count_indent(raw)

		# Entering a new function
		if stripped.begins_with("func "):
			in_func      = true
			current_func = _extract_func_name(stripped)
			func_indent  = indent
			func_scope   = global_names.duplicate()

			# Add parameters to scope
			var params := _extract_func_params(stripped)
			for p in params:
				func_scope[p] = true
			continue

		if not in_func: continue

		# Left function scope
		if indent <= func_indent and stripped != "" and not stripped.begins_with("#"):
			if not stripped.begins_with("func "):
				in_func = false
				func_scope = {}
				continue

		# Collect local var declarations inside function
		if stripped.begins_with("var ") or stripped.begins_with("const "):
			var lname := _extract_declared_name(stripped)
			if lname != "": func_scope[lname] = true
			continue

		# Collect for-loop variable
		if stripped.begins_with("for "):
			var fvar := _extract_for_var(stripped)
			if fvar != "": func_scope[fvar] = true
			continue

		# Skip lines that are pure structure (else:, elif ...:, match ...:)
		if stripped == "else:" or stripped.begins_with("elif ") \
		or stripped.begins_with("match ") or stripped == "pass" \
		or stripped.begins_with("return") or stripped.begins_with("break") \
		or stripped.begins_with("continue"):
			continue

		# ── Check identifiers on this line ──────────────────────
		var code    := _remove_comment(stripped)
		var clean   := _strip_strings(code)
		# Strip node paths ($Node) and annotations (@name)
		clean = _strip_node_paths(clean)
		var tokens  := _tokenize(clean)

		for token in tokens:
			# Skip pure numbers
			if token.is_valid_int() or token.is_valid_float(): continue
			# Skip single chars likely to be loop vars (i, j, k, x, y, z, n)
			if token.length() == 1: continue
			# Skip _ prefix (private/unused convention)
			if token.begins_with("_"): continue
			# Skip if declared
			if func_scope.has(token): continue
			# Skip ALL_CAPS constants (user-defined enums etc.)
			if token == token.to_upper() and token.length() > 1: continue

			errors.append({
				"line":    i + 1,
				"message": 'Identifier "%s" tidak dikenal di fungsi ini — apakah sudah dideklarasikan?' % token
			})
			# Only report first unknown per line to avoid spam
			break

	return errors

# ── Helpers ────────────────────────────────────────────────────
func _extract_declared_name(line: String) -> String:
	# "var foo : int = 5"  →  "foo"
	# "@onready var foo"   →  "foo"
	var s := line
	if s.begins_with("@"): s = s.split("var ", true, 1)[-1]
	else: s = s.substr(s.find(" ") + 1)
	s = s.split(":")[0].split("=")[0].split(" ")[0].strip_edges()
	return s if s != "" else ""

func _extract_func_name(line: String) -> String:
	# "func my_func(a, b) -> void:"  →  "my_func"
	var after := line.substr(5).strip_edges()
	return after.split("(")[0].strip_edges()

func _extract_func_params(line: String) -> Array:
	# "func run(speed: int, name: String) -> void:"  →  ["speed", "name"]
	var params: Array = []
	var op := line.find("(")
	var cp := line.find(")")
	if op == -1 or cp == -1 or cp <= op + 1: return params
	var inner := line.substr(op + 1, cp - op - 1)
	for part in inner.split(","):
		var pname := part.strip_edges().split(":")[0].strip_edges()
		if pname != "" and not pname.begins_with("_"):
			params.append(pname)
	return params

func _extract_for_var(line: String) -> String:
	# "for i in range(5):"  →  "i"
	var after := line.substr(4).strip_edges()
	return after.split(" ")[0].split(":")[0].strip_edges()

func _strip_node_paths(line: String) -> String:
	# Replace $NodeName and %NodeName with spaces so tokens aren't flagged
	var result := ""
	var i := 0
	while i < line.length():
		var ch := line[i]
		if ch == "$" or ch == "%":
			result += " "
			i += 1
			while i < line.length():
				var c := line[i].unicode_at(0)
				if _is_word_char_code(c) or line[i] == "/":
					result += " "
					i += 1
				else: break
		else:
			result += ch
			i += 1
	return result
