## Centralised localisation (Uzbek Latin default, Russian, English).
## Strings live in data/i18n/<lang>.json (UTF-8). They are registered with
## Godot's TranslationServer, so tr() works everywhere; screens listen to
## Events.language_changed to rebuild formatted text.
extends Node

const NAMES := {"uz": "Oʻzbekcha", "ru": "Русский", "en": "English"}

var lang := K.DEFAULT_LANG
var tables := {}


func _ready() -> void:
	for l in K.LANGS:
		var d = Util.load_json("res://data/i18n/%s.json" % l)
		tables[l] = d if d is Dictionary else {}
		var tr_res := Translation.new()
		tr_res.locale = l
		for k in tables[l]:
			tr_res.add_message(k, tables[l][k])
		TranslationServer.add_translation(tr_res)
	set_language(str(Profile.setting("language", K.DEFAULT_LANG)), false)


func set_language(l: String, persist := true) -> void:
	if not K.LANGS.has(l):
		l = K.DEFAULT_LANG
	lang = l
	TranslationServer.set_locale(l)
	if persist:
		Profile.set_setting("language", l)
	Events.language_changed.emit(l)


## Translate key, optionally formatting with args (uses % formatting).
func t(key: String, args: Variant = null) -> String:
	var s: String = tables.get(lang, {}).get(key, "")
	if s.is_empty():
		s = tables.get("en", {}).get(key, key)
	if args == null:
		return s
	if args is Array:
		return s % args
	return s % [args]


func has_key(key: String) -> bool:
	return tables.get(lang, {}).has(key)


func num(n: int) -> String:
	return Util.fmt_int(n, "," if lang == "en" else " ")


func meters(m: float) -> String:
	return t("unit_m", num(int(m)))
