extends TestCase


func _load(l: String) -> Dictionary:
	return Util.load_json("res://data/i18n/%s.json" % l)


func test_complete_and_consistent() -> void:
	var uz := _load("uz")
	var ru := _load("ru")
	var en := _load("en")
	check(uz.size() > 200, "substantial string table")
	eq(uz.keys().size(), ru.keys().size(), "uz/ru key count")
	eq(uz.keys().size(), en.keys().size(), "uz/en key count")
	var re := RegEx.create_from_string("%[-0-9.]*[sdf]")
	for k in uz:
		check(ru.has(k) and en.has(k), "key %s in all languages" % k)
		for tbl in [uz, ru, en]:
			check(str(tbl.get(k, "")).strip_edges() != "", "key %s non-empty" % k)
		var ph := func(s: String) -> Array:
			var out := []
			for m in re.search_all(s):
				out.append(m.get_string())
			out.sort()
			return out
		eq(ph.call(uz[k]), ph.call(en.get(k, "")), "placeholders uz/en for %s" % k)
		eq(ph.call(ru.get(k, "")), ph.call(en.get(k, "")), "placeholders ru/en for %s" % k)


func test_uzbek_orthography() -> void:
	var uz := _load("uz")
	for k in uz:
		var s: String = uz[k]
		check(not s.contains("o'") and not s.contains("g'") and not s.contains("O'") and not s.contains("G'"), "%s uses ʻ (U+02BB), not ASCII apostrophe" % k)
		check(not s.contains("`"), "%s has no stray backtick" % k)
	check(uz.btn_play.contains("ʻ"), "oʻ rendered with U+02BB")


func test_no_mixed_languages() -> void:
	var ru := _load("ru")
	var uz := _load("uz")
	var cyr := RegEx.create_from_string("[А-Яа-яЁё]")
	for k in uz:
		check(cyr.search(uz[k]) == null, "Uzbek (Latin) text %s contains no Cyrillic" % k)
	var latin_words := RegEx.create_from_string("\\b[a-zA-Z]{4,}\\b")
	var allowed := ["Drive", "Hill", "Adventure", "Exo", "Nunito", "Godot", "Engine", "SIL", "Open", "Font", "License", "UZ"]
	for k in ru:
		for m in latin_words.search_all(ru[k]):
			check(allowed.has(m.get_string()), "Russian text %s has no stray Latin word '%s'" % [k, m.get_string()])


func test_all_referenced_keys_exist() -> void:
	var en := _load("en")
	var keys := {}
	var re := RegEx.create_from_string("Loc\\.t\\(\"([a-z0-9_]+)\"")
	for f in _gd_files("res://src"):
		for m in re.search_all(FileAccess.get_file_as_string(f)):
			keys[m.get_string(1)] = f
	for k in keys:
		if k.ends_with("_"):
			continue
		check(en.has(k), "key '%s' used in %s exists" % [k, keys[k]])
	for v in DB.vehicles:
		check(en.has(v.desc_key), "vehicle desc %s" % v.desc_key)
		check(en.has("cat_" + v.category), "category name %s" % v.category)
		check(en.has("rarity_" + v.rarity), "rarity name %s" % v.rarity)
	for e in DB.environments:
		check(en.has(e.name_key) and en.has(e.desc_key), "map texts %s" % e.id)
	for t in DB.missions.templates:
		check(en.has("mission_" + t.id), "mission text %s" % t.id)
	for a in DB.achievements:
		check(en.has("ach_" + a.id) and en.has("achd_" + a.id), "achievement text %s" % a.id)
	for u in K.UPGRADE_TYPES:
		check(en.has("upg_" + u), "upgrade text %s" % u)


func test_switching() -> void:
	var loc = tree.root.get_node("/root/Loc")
	var got := []
	var cb := func(l): got.append(l)
	Events.language_changed.connect(cb)
	for l in ["ru", "en", "uz"]:
		loc.set_language(l, false)
		eq(TranslationServer.get_locale(), l, "locale set to %s" % l)
	Events.language_changed.disconnect(cb)
	eq(got, ["ru", "en", "uz"], "language_changed emitted")
	loc.set_language("uz", false)
	eq(loc.t("btn_garage"), "Garaj", "Uzbek default")
	loc.set_language("ru", false)
	eq(loc.t("btn_garage"), "Гараж", "Russian")
	eq(loc.t("unit_m", "5"), "5 м", "formatting")
	loc.set_language("en", false)
	eq(loc.num(1234567), "1,234,567", "English thousands separator")
	loc.set_language("uz", false)


func _gd_files(dir: String) -> Array:
	var out := []
	var d := DirAccess.open(dir)
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		var p := dir + "/" + n
		if d.current_is_dir():
			out.append_array(_gd_files(p))
		elif n.ends_with(".gd"):
			out.append(p)
		n = d.get_next()
	return out
