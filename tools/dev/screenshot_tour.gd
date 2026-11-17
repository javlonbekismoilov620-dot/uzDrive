## Dev tool: boots the real app, visits screens and saves screenshots.
## Usage: godot --path . --rendering-driver opengl3 -s tools/dev/screenshot_tour.gd -- <outdir> [lang] [steps]
extends SceneTree

var out := "."
var steps: Array = []

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "."
	var lang: String = args[1] if args.size() > 1 else "uz"
	var w := int(args[3]) if args.size() > 3 else 1280
	var h := int(args[4]) if args.size() > 4 else 720
	DisplayServer.window_set_size(Vector2i(w, h))
	steps = (args[2] if args.size() > 2 else "language,main_menu,maps,garage,shop,missions,achievements,settings,game").split(",")
	_run.call_deferred(lang)

func _run(lang: String) -> void:
	var profile = root.get_node("/root/Profile")
	var loc = root.get_node("/root/Loc")
	profile.reset_progress()
	profile.data.settings.lang_chosen = steps[0] != "language"
	profile.data.wallet.coins = 125000
	profile.data.wallet.gems = 42
	profile.data.garage.owned.append_array(["sarbon_uchqun", "sarbon_kumush", "dev_monster", "sarbon_burgut"])
	profile.data.maps.unlocked.append_array(["countryside", "desert_road"])
	profile.data.maps.best["green_hills"] = 870
	profile.data.stats["total_distance"] = 5400.0
	profile.data.stats["best_run"] = 870.0
	profile.data.rewards.login = {"last": Util.today_str(), "day": 0}
	profile.data.tutorial.done = true
	profile.data.garage.selected = "sarbon_burgut"
	loc.set_language(lang, false)
	var main = load("res://src/main/main.tscn").instantiate()
	root.add_child(main)
	await _wait(1.2)
	var i := 0
	for s in steps:
		if s == "language":
			await _shot("%02d_language" % i)
		elif s.begins_with("game"):
			var parts: PackedStringArray = s.split(":")
			var map_id := parts[1] if parts.size() > 1 else "green_hills"
			var vid := parts[2] if parts.size() > 2 else "sarbon_mitti"
			main.go("game", {"map": map_id, "vehicle": vid})
			await _wait(1.0)
			Input.action_press("gas")
			await _wait(5.0)
			await _shot("%02d_game_%s_a" % [i, map_id])
			await _wait(5.0)
			await _shot("%02d_game_%s_b" % [i, map_id])
			Input.action_release("gas")
		elif s == "pause":
			main.current.pause()
			await _wait(0.5)
			await _shot("%02d_pause" % i)
			main.current.pause_menu.resume()
		elif s == "results":
			Input.action_release("gas")
			main.current.run_coins = 1240
			main.current.trick_coins = 250
			main.current._end_run("fuel")
			await _wait(3.0)
			await _shot("%02d_results" % i)
		elif s == "daily":
			profile.data.rewards.login = {"last": "", "day": -1}
			main.go("maps")
			await _wait(0.6)
			main.go("main_menu")
			await _wait(1.6)
			await _shot("%02d_daily" % i)
		else:
			main.go(s)
			await _wait(1.0)
			await _shot("%02d_%s" % [i, s])
		i += 1
	quit()

func _wait(t: float) -> void:
	await create_timer(t).timeout

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
	print("shot ", name)
