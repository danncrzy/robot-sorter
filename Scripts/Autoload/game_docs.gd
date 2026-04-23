# res://Scripts/Autoload/game_docs.gd
extends Node

# Each page is a dictionary. "toc" determines if it shows in the Table of Contents.
var pages: Array[Dictionary] = [
	{
		"title": "Table of Contents",
		"content": "", # Generated automatically by DocumentsUI
		"is_toc": true,
		"toc_visible": true,
		"toc_indent": 0
	},
	{
		"title": "1. Variables",
		"content": "Variables are containers for storing data values. In GDScript, you can create a variable using the 'var' keyword.",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 0
	},
	{
		"title": "1.1 Bool",
		"content": "A Bool (boolean) represents one of two values: true or false. They are often used for conditions and checks.\n\nExample:\nvar is_open = false",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},
	{
		"title": "1.2 String",
		"content": "A String is a sequence of characters used to store text.\n\nExample:\nvar name = \"Robot\"",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	},
	{
		"title": "2. Functions",
		"content": "A function is a block of organized, reusable code that is used to perform a single, related action. Define one using the 'func' keyword.",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 0
	},
	{
		"title": "2.1 Built-in Functions",
		"content": "These are functions already provided by the engine, such as move_and_slide() or get_node(). You can call them directly.",
		"is_toc": false,
		"toc_visible": true,
		"toc_indent": 1
	}
]

func get_page(index: int) -> Dictionary:
	if index >= 0 and index < pages.size():
		return pages[index]
	return {}
