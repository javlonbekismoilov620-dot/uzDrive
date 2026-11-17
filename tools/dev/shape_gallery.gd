## Dev tool: renders a gallery of vehicle shapes to a PNG.
## Usage: godot --path . --rendering-driver opengl3 -s tools/dev/shape_gallery.gd -- out.png [json]
extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "gallery.png"
	var defs: Array = []
	if args.size() > 1:
		defs = Util.load_json(args[1])
	else:
		defs = (Util.load_json("res://data/vehicles.json") as Dictionary).vehicles
	var page := int(args[2]) if args.size() > 2 else 0
	var per := 20
	defs = defs.slice(page * per, page * per + per)
	var root := Node2D.new()
	get_root().add_child(root)
	var bg := ColorRect.new()
	bg.color = Color("dfe8f0")
	bg.size = Vector2(1600, 1200)
	root.add_child(bg)
	var cols := 4
	for i in defs.size():
		var v := VehicleVisual.new()
		v.setup(defs[i])
		var cx := 200 + (i % cols) * 400
		var cy := 150 + (i / cols) * 230
		v.position = Vector2(cx, cy)
		root.add_child(v)
		var lbl := Label.new()
		lbl.text = "%s (%s)" % [defs[i].get("name", "?"), defs[i].body.type]
		lbl.position = Vector2(cx - 150, cy + 70)
		lbl.add_theme_color_override("font_color", Color.BLACK)
		root.add_child(lbl)
		var ln := Line2D.new()
		ln.points = PackedVector2Array([Vector2(cx - 180, cy + v.shape.ground_y), Vector2(cx + 180, cy + v.shape.ground_y)])
		ln.width = 2
		ln.default_color = Color(0.3, 0.5, 0.2)
		root.add_child(ln)
	DisplayServer.window_set_size(Vector2i(1600, 1200))
	get_root().size = Vector2i(1600, 1200)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(out)
	print("saved ", out)
	quit()
