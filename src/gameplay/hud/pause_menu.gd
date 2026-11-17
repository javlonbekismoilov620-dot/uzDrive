## Pause overlay: resume, restart, sound & music toggles, exit to garage / menu.
class_name PauseMenu
extends CanvasLayer

var game: GameScreen
var _root: Control
var _title: Label
var _btns := {}
var _sound: UIToggle
var _music: UIToggle
var _sound_lbl: Label
var _music_lbl: Label


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.09, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var card := PanelContainer.new()
	card.theme_type_variation = "PanelDialog"
	card.custom_minimum_size = Vector2(520, 0)
	center.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	card.add_child(v)
	_title = Label.new()
	_title.theme_type_variation = "Title"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_title)
	_btns.resume = UIButton.make("", "BtnPrimary", "play", Vector2(0, 70))
	_btns.resume.pressed.connect(resume)
	v.add_child(_btns.resume)
	_btns.restart = UIButton.make("", "BtnBlue", "restart", Vector2(0, 62))
	_btns.restart.pressed.connect(func(): game.restart())
	v.add_child(_btns.restart)
	var toggles := HBoxContainer.new()
	toggles.add_theme_constant_override("separation", 18)
	toggles.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(toggles)
	_sound_lbl = Label.new()
	_sound = UIToggle.new()
	_sound.toggled.connect(func(on): Profile.set_setting("sound", on))
	_music_lbl = Label.new()
	_music = UIToggle.new()
	_music.toggled.connect(func(on): Profile.set_setting("music", on))
	for pair in [[_sound_lbl, _sound, "sound_on"], [_music_lbl, _music, "music_on"]]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		h.add_child(ScreenBase.icon_rect(pair[2], 28, UI.TEXT_DIM))
		h.add_child(pair[0])
		h.add_child(pair[1])
		toggles.add_child(h)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	_btns.garage = UIButton.make("", "BtnSecondary", "garage", Vector2(0, 60))
	_btns.garage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btns.garage.pressed.connect(func(): game.exit_to("garage"))
	row.add_child(_btns.garage)
	_btns.menu = UIButton.make("", "BtnSecondary", "home", Vector2(0, 60))
	_btns.menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btns.menu.pressed.connect(func(): game.exit_to("main_menu"))
	row.add_child(_btns.menu)
	Events.language_changed.connect(func(_l): _texts())
	_texts()


func _texts() -> void:
	_title.text = Loc.t("pause_title")
	_btns.resume.text = Loc.t("btn_resume")
	_btns.restart.text = Loc.t("btn_restart")
	_btns.garage.text = Loc.t("btn_garage")
	_btns.menu.text = Loc.t("btn_menu")
	_sound_lbl.text = Loc.t("set_sound")
	_music_lbl.text = Loc.t("set_music")


func open() -> void:
	_sound.set_on(bool(Profile.setting("sound", true)))
	_music.set_on(bool(Profile.setting("music", true)))
	visible = true
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.15)


func resume() -> void:
	visible = false
	get_tree().paused = false


func _unhandled_input(e: InputEvent) -> void:
	if visible and (e.is_action_pressed("pause") or e.is_action_pressed("ui_cancel")):
		resume()
		get_viewport().set_input_as_handled()
