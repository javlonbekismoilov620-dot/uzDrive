extends TestCase
## Smoke test: every menu screen builds in every language without showing raw
## keys or unformatted placeholders.

const SCREENS := ["language", "main_menu", "maps", "garage", "shop", "missions", "achievements", "settings"]


func _texts(n: Node, out: Array) -> void:
	if n is Label or n is Button:
		var t: String = n.text
		if t != "":
			out.append(t)
	for c in n.get_children():
		_texts(c, out)


func test_screens_all_languages() -> void:
	fresh_profile()
	Profile.data.rewards.login = {"last": Util.today_str(), "day": 0}
	var en: Dictionary = Util.load_json("res://data/i18n/en.json")
	var main_script: GDScript = load("res://src/main/main.gd")
	var paths: Dictionary = main_script.SCREENS
	for lang in K.LANGS:
		Loc.set_language(lang, false)
		for sname in SCREENS:
			var node: Node = (load(paths[sname]) as GDScript).new()
			tree.root.add_child(node)
			await wait_frames(3)
			var texts: Array = []
			_texts(node, texts)
			check(texts.size() > 0, "%s/%s shows text" % [lang, sname])
			for t in texts:
				check(not en.has(t), "%s/%s: raw key shown: %s" % [lang, sname, t])
				check(not t.contains("%s") and not t.contains("%d"), "%s/%s: unformatted '%s'" % [lang, sname, t])
			tree.root.remove_child(node)
			node.queue_free()
			await wait_frames(1)
	UI.close_all_dialogs()
	Loc.set_language("uz", false)


func test_purchase_requires_confirmation() -> void:
	fresh_profile()
	Profile.data.wallet.coins = 100000
	var shop: Node = (load("res://src/ui/screens/shop_screen.gd") as GDScript).new()
	shop.params = {"vehicle": "sarbon_lola"}
	tree.root.add_child(shop)
	await wait_frames(3)
	shop._on_buy()
	await wait_frames(2)
	check(not Profile.owns("sarbon_lola"), "tapping Buy alone does not purchase")
	check(UI.has_dialog(), "a confirmation dialog is shown")
	UI.close_all_dialogs()
	tree.root.remove_child(shop)
	shop.queue_free()
	await wait_frames(1)
