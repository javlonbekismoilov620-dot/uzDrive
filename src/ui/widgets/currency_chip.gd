## Coin / gem counter pill with animated count-up.
class_name CurrencyChip
extends PanelContainer

var kind := "coins"
var _label: Label
var _shown := 0.0
var _target := 0


static func make(currency: String) -> CurrencyChip:
	var c := CurrencyChip.new()
	c.kind = currency
	return c


func _ready() -> void:
	var sb := UI.flat(Color(0.03, 0.06, 0.12, 0.65), 24, Color(1, 1, 1, 0.08), 2)
	sb.content_margin_left = 8
	sb.content_margin_right = 18
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	add_child(h)
	var ic := TextureRect.new()
	ic.texture = UI.icon("coin" if kind == "coins" else "gem")
	ic.custom_minimum_size = Vector2(36, 36)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(ic)
	_label = Label.new()
	_label.theme_type_variation = "Number"
	_label.custom_minimum_size = Vector2(70, 0)
	h.add_child(_label)
	_target = Economy.coins() if kind == "coins" else Economy.gems()
	_shown = _target
	_label.text = Loc.num(_target)
	if kind == "coins":
		Events.coins_changed.connect(_on_changed)
	else:
		Events.gems_changed.connect(_on_changed)
	Events.language_changed.connect(func(_l): _label.text = Loc.num(int(_shown)))


func _on_changed(total: int, _delta: int) -> void:
	_target = total
	var tw := create_tween()
	tw.tween_method(func(v: float):
		_shown = v
		_label.text = Loc.num(int(round(v))), _shown, float(total), 0.45)
	pivot_offset = size * 0.5
	var tw2 := create_tween()
	tw2.tween_property(self, "scale", Vector2(1.08, 1.08), 0.08)
	tw2.tween_property(self, "scale", Vector2.ONE, 0.15)
