## Saves the runtime-built design-system theme as the project default theme
## (res://assets/ui/theme.tres) so every Control - including ones under
## CanvasLayers or plain Nodes - is styled consistently.
## Usage: godot --headless --path . -s tools/dev/build_theme.gd
extends SceneTree

func _initialize() -> void:
	_go.call_deferred()

func _go() -> void:
	var ui = root.get_node("/root/UI")
	var t: Theme = ui.build_theme()
	var err := ResourceSaver.save(t, "res://assets/ui/theme.tres")
	print("theme saved: ", err)
	quit(0 if err == OK else 1)
