## App root: owns the current screen and performs faded transitions.
extends Node

const SCREENS := {
	"language": "res://src/ui/screens/language_screen.gd",
	"main_menu": "res://src/ui/screens/main_menu.gd",
	"maps": "res://src/ui/screens/map_select.gd",
	"garage": "res://src/ui/screens/garage_screen.gd",
	"shop": "res://src/ui/screens/shop_screen.gd",
	"missions": "res://src/ui/screens/missions_screen.gd",
	"achievements": "res://src/ui/screens/achievements_screen.gd",
	"settings": "res://src/ui/screens/settings_screen.gd",
	"game": "res://src/gameplay/game_screen.gd",
}

var current: Node
var current_name := ""
var _switching := false


func _ready() -> void:
	UI.router = self
	get_tree().set_auto_accept_quit(false)
	get_tree().set_quit_on_go_back(false)
	_recover_pending_run()
	var first := "main_menu"
	if not bool(Profile.setting("lang_chosen", false)):
		first = "language"
	go(first, {}, false)


## A run that was interrupted (app killed) is paid out on next launch.
func _recover_pending_run() -> void:
	var pr = Profile.data.get("pending_run", null)
	if pr is Dictionary and pr.has("run_id"):
		var payout := GameScreen.commit_summary(pr)
		Profile.data.erase("pending_run")
		Profile.save_now()
		if not payout.is_empty() and int(payout.total) > 0:
			call_deferred("_toast_recovered", int(payout.total))


func _toast_recovered(n: int) -> void:
	UI.toast(Loc.t("toast_run_recovered", Loc.num(n)), "gold")


func go(screen: String, params := {}, fade := true) -> void:
	if _switching:
		return
	_switching = true
	if fade and current:
		await UI.fade_out()
	UI.close_all_dialogs()
	get_tree().paused = false
	Engine.time_scale = 1.0
	if current:
		current.queue_free()
		current = null
		await get_tree().process_frame
	var script: GDScript = load(SCREENS.get(screen, SCREENS.main_menu))
	var node: Node = script.new()
	node.set("params", params)
	current = node
	current_name = screen
	add_child(node)
	if screen != "game":
		Audio.music("menu")
	_switching = false
	if fade:
		UI.fade_in()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Save.flush()
		get_tree().quit()
