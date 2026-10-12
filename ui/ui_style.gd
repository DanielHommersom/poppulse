class_name UiStyle
extends RefCounted
## Shared fonts, label settings and button styles.

# Palette of the active theme. ThemeManager overwrites these on apply();
# the defaults are the "Neon" theme.
static var ACCENT := Color(1.0, 0.25, 0.7)
static var CYAN := Color(0.25, 0.95, 1.0)
static var GOLD := Color(1.0, 0.85, 0.3)
static var DANGER := Color(1.0, 0.3, 0.35)
static var OK := Color(0.4, 1.0, 0.55)
static var PANEL_BG := Color(0.07, 0.05, 0.13, 0.97)
static var PANEL_BORDER := Color(0.6, 0.35, 1.0, 0.6)
static var DIM_TEXT := Color(1, 1, 1, 0.6)
static var INK := Color(0.05, 0.03, 0.1)

static var _font: Font


static func font() -> Font:
	if _font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["SF Pro Rounded", "SF Pro Display", "Avenir Next", "Helvetica Neue", "Arial"])
		f.font_weight = 800
		_font = f
	return _font


## Accessibility (US-36): text is never fainter than this, so secondary text
## keeps ≥ 4.5:1 contrast on every theme's panels (see tests/test_contrast.gd).
const MIN_TEXT_ALPHA := 0.55


static func text_color(c: Color) -> Color:
	return Color(c, maxf(c.a, MIN_TEXT_ALPHA))


static func label_settings(size: int, color: Color, glow := true) -> LabelSettings:
	var s := LabelSettings.new()
	s.font = font()
	s.font_size = size
	s.font_color = text_color(color)
	s.outline_size = maxi(2, int(size / 14.0))
	s.outline_color = Color(0, 0, 0, 0.55)
	if glow:  # neon glow via an unoffset, blurred shadow
		s.shadow_color = Color(color, 0.45)
		s.shadow_size = maxi(4, int(size / 6.0))
		s.shadow_offset = Vector2.ZERO
	return s


static func set_label_color(l: Label, color: Color) -> void:
	l.label_settings.font_color = text_color(color)
	if l.label_settings.shadow_size > 0:
		l.label_settings.shadow_color = Color(color, 0.45)


static func label(text: String, size: int, color: Color, glow := false, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.label_settings = label_settings(size, color, glow)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func button(text: String, color: Color, font_size := 44) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", font_size)
	restyle_button(b, color, font_size)
	return b


## Re-applies the filled CTA style (used when the theme changes).
static func restyle_button(b: Button, color: Color, font_size := 44) -> void:
	var pad := font_size * 1.27
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = color.darkened(0.25) if st == "pressed" else color
		if st == "disabled":
			sb.bg_color = Color(color, 0.35)
		sb.set_corner_radius_all(int(pad))
		sb.content_margin_left = pad
		sb.content_margin_right = pad
		sb.content_margin_top = font_size * 0.5
		sb.content_margin_bottom = font_size * 0.5
		sb.shadow_color = Color(color, 0.5)
		sb.shadow_size = 10 if st == "pressed" else 24
		sb.anti_aliasing = true
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		b.add_theme_color_override(c, INK)


## Outlined secondary button (less visual weight than the filled CTA).
static func ghost_button(text: String, color: Color, font_size := 34) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", font_size)
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(color, 0.22 if st == "pressed" else 0.06)
		sb.border_color = Color(color, 0.35 if st == "disabled" else 0.9)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(int(font_size * 1.1))
		sb.content_margin_left = font_size * 1.0
		sb.content_margin_right = font_size * 1.0
		sb.content_margin_top = font_size * 0.4
		sb.content_margin_bottom = font_size * 0.4
		sb.anti_aliasing = true
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, color)
	b.add_theme_color_override("font_disabled_color", Color(color, 0.4))
	return b


## Round icon-only button (gear, pause, stats…). `px` is the diameter.
static func icon_button(icon: String, color: Color, px := 84.0) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(px, px)
	b.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(color, 0.25 if st == "pressed" else 0.08)
		sb.border_color = Color(color, 0.55)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(int(px * 0.5))
		sb.anti_aliasing = true
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var ic := NeonIcon.new(icon, color)
	ic.set_anchors_preset(Control.PRESET_FULL_RECT)
	ic.offset_left = px * 0.24
	ic.offset_top = px * 0.24
	ic.offset_right = -px * 0.24
	ic.offset_bottom = -px * 0.24
	ic.name = "Icon"
	b.add_child(ic)
	return b


static func panel_style(border := PANEL_BORDER, radius := 40, margin := 40) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(3)
	sb.border_color = border
	sb.shadow_color = Color(border, 0.3)
	sb.shadow_size = 40
	sb.set_content_margin_all(margin)
	sb.anti_aliasing = true
	return sb


## Small rounded card background used by mode cards, level cells, list rows.
static func card_style(color: Color, selected := false, radius := 28) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color, 0.22) if selected else Color(0.1, 0.08, 0.18, 0.92)
	sb.border_color = Color(color, 0.95 if selected else 0.35)
	sb.set_border_width_all(4 if selected else 2)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(color, 0.45 if selected else 0.0)
	sb.shadow_size = 22 if selected else 0
	sb.set_content_margin_all(14)
	sb.anti_aliasing = true
	return sb


## A flat button that uses a card style (for tappable cards / list rows).
static func card_button(color: Color, selected := false) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	set_card_selected(b, color, selected)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


static func set_card_selected(b: Button, color: Color, selected: bool) -> void:
	var sb := card_style(color, selected)
	for st in ["normal", "hover", "disabled"]:
		b.add_theme_stylebox_override(st, sb)
	var p := card_style(color, true)
	p.bg_color = Color(color, 0.3)
	b.add_theme_stylebox_override("pressed", p)
