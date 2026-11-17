## First-launch language picker (Uzbek preselected as the default).
extends ScreenBase

var _title2: Label


func _init() -> void:
	show_back = false
	show_currencies = false


func build() -> void:
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_child(c)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	v.custom_minimum_size = Vector2(520, 0)
	c.add_child(v)
	v.add_child(ScreenBase.icon_rect("globe", 72, UI.BLUE))
	_title2 = Label.new()
	_title2.theme_type_variation = "Heading"
	_title2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_title2)
	for l in K.LANGS:
		var b := UIButton.make(Loc.NAMES[l], "BtnPrimary" if l == K.DEFAULT_LANG else "BtnSecondary", "", Vector2(0, 74))
		b.pressed.connect(func():
			Loc.set_language(l)
			Profile.set_setting("lang_chosen", true)
			Profile.save_now()
			UI.go("main_menu"))
		v.add_child(b)


func refresh_texts() -> void:
	title_label.text = ""
	_title2.text = "Tilni tanlang  •  Выберите язык  •  Choose language"


func on_back() -> void:
	pass
