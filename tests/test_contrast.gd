extends TestCase
## US-36: text contrast (WCAG 2.x) for every theme. Normal text ≥ 4.5:1 on
## panels and the background; text on filled buttons ≥ 4.5:1.


static func _lin(c: float) -> float:
	return c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)


static func lum(c: Color) -> float:
	return 0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b)


static func ratio(fg: Color, bg: Color) -> float:
	var blended := Color(bg.r + (fg.r - bg.r) * fg.a, bg.g + (fg.g - bg.g) * fg.a, bg.b + (fg.b - bg.b) * fg.a)
	var a := lum(blended)
	var b := lum(bg)
	return (maxf(a, b) + 0.05) / (minf(a, b) + 0.05)


func test_all_themes() -> void:
	for t: ThemeData in ThemeManager.themes:
		var bgs := {"panel": Color(t.panel_bg, 1.0), "background": t.bg_top}
		var texts := {
			"faint white": UiStyle.text_color(Color(1, 1, 1, 0.4)),
			"dim": UiStyle.text_color(Color(1, 1, 1, 0.6)),
			"cyan": t.ui_cyan, "gold": t.ui_gold, "accent": t.ui_accent, "danger": t.ui_danger, "ok": t.ui_ok,
		}
		for bn in bgs:
			for tn in texts:
				var r := ratio(texts[tn], bgs[bn])
				check(r >= 4.5, "%s: %s on %s = %.2f" % [t.id, tn, bn, r])
		for btn in ["accent", "cyan", "gold"]:
			var fill: Color = {"accent": t.ui_accent, "cyan": t.ui_cyan, "gold": t.ui_gold}[btn]
			var r2 := ratio(t.ink, fill)
			check(r2 >= 4.5, "%s: button text on %s = %.2f" % [t.id, btn, r2])
