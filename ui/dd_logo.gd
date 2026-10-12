class_name DigitalDiamondsLogo
extends Control
## The Digital Diamonds logo, drawn as vectors from the same geometry as
## assets/brand/digital_diamonds_logo.svg (CombatTimer), so it stays sharp at
## any size. `shine` (0..1) sweeps a highlight across the diamond.

## SVG viewBox "55 0 584 280".
const VIEW := Rect2(55, 0, 584, 280)
const G1 := [Color("#7C3AED"), Color("#3B82F6"), Color("#22D3EE")]
const G2 := [Color("#A78BFA"), Color("#60A5FA")]
const G3 := [Color("#4C1D95"), Color("#1D4ED8")]
const G4 := [Color("#3B82F6"), Color("#22D3EE")]
## [points, fill (Color or gradient stops), opacity] — in SVG order.
const FACETS := [
	[[Vector2(105, 90), Vector2(175, 70), Vector2(120, 120)], G2, 0.9],
	[[Vector2(105, 90), Vector2(85, 140), Vector2(120, 120)], Color("#5B21B6"), 0.9],
	[[Vector2(175, 70), Vector2(210, 120), Vector2(120, 120)], G1, 0.95],
	[[Vector2(175, 70), Vector2(245, 90), Vector2(210, 120)], G2, 0.75],
	[[Vector2(245, 90), Vector2(265, 140), Vector2(210, 120)], G4, 0.85],
	[[Vector2(85, 140), Vector2(120, 120), Vector2(175, 255)], Color("#1E1B4B"), 0.95],
	[[Vector2(120, 120), Vector2(210, 120), Vector2(175, 255)], G3, 0.9],
	[[Vector2(210, 120), Vector2(265, 140), Vector2(175, 255)], Color("#1D4ED8"), 0.85],
	[[Vector2(85, 140), Vector2(175, 255), Vector2(265, 140)], G1, 0.15],
]

var shine := -1.0:
	set(v):
		shine = v
		queue_redraw()

static var _font: SystemFont


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


static func font() -> Font:
	if _font == null:
		_font = SystemFont.new()
		_font.font_names = PackedStringArray(["Arial Black", "Helvetica Neue", "Arial"])
		_font.font_weight = 900
	return _font


## Logo aspect (width / height) so callers can size it.
static func aspect() -> float:
	return VIEW.size.x / VIEW.size.y


func _draw() -> void:
	var k := minf(size.x / VIEW.size.x, size.y / VIEW.size.y)
	var off := (size - VIEW.size * k) * 0.5 - VIEW.position * k
	draw_set_transform(off, 0.0, Vector2(k, k))
	# soft glow under the tip
	_ellipse(Vector2(175, 258), Vector2(50, 7), Color(Color("#3B82F6"), 0.18))
	for f: Array in FACETS:
		var pts := PackedVector2Array(f[0])
		var cols := PackedColorArray()
		var bb := Rect2(pts[0], Vector2.ZERO)
		for p in pts:
			bb = bb.expand(p)
		for p in pts:
			cols.append(Color(_fill(f[1], p, bb), float(f[2])))
		draw_polygon(pts, cols)
	# facet edges
	draw_polyline(PackedVector2Array([Vector2(105, 90), Vector2(85, 140), Vector2(120, 120), Vector2(175, 70), Vector2(105, 90)]), Color(0.65, 0.55, 0.98, 0.3), 0.5, true)
	draw_polyline(PackedVector2Array([Vector2(245, 90), Vector2(265, 140), Vector2(210, 120), Vector2(175, 70), Vector2(245, 90)]), Color(0.38, 0.65, 0.98, 0.3), 0.5, true)
	if shine >= 0.0 and shine <= 1.0:
		_shine()
	draw_set_transform(Vector2.ZERO)
	# Text in screen space (crisp glyphs at any scale)
	var fs := int(52 * k)
	_word("DIGITAL", off + Vector2(305, 130) * k, fs, [Color("#F8FAFC")])
	_word("DIAMONDS", off + Vector2(305, 194) * k, fs, G1)


## objectBoundingBox gradient from top-left to bottom-right of the facet.
static func _fill(fill: Variant, p: Vector2, bb: Rect2) -> Color:
	if fill is Color:
		return fill
	var stops: Array = fill
	var u := (p.x - bb.position.x) / maxf(bb.size.x, 0.001)
	var v := (p.y - bb.position.y) / maxf(bb.size.y, 0.001)
	return _ramp(stops, clampf((u + v) * 0.5, 0.0, 1.0))


static func _ramp(stops: Array, t: float) -> Color:
	if stops.size() == 1:
		return stops[0]
	var seg := t * (stops.size() - 1)
	var i := mini(int(seg), stops.size() - 2)
	return (stops[i] as Color).lerp(stops[i + 1], seg - i)


func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	draw_colored_polygon(pts, col)


## A bright diagonal band clipped (approximately) to the diamond silhouette.
func _shine() -> void:
	var x := lerpf(60.0, 300.0, shine)
	var band := PackedVector2Array([Vector2(x - 18, 60), Vector2(x + 8, 60), Vector2(x - 60, 260), Vector2(x - 86, 260)])
	var clipped := Geometry2D.intersect_polygons(band, PackedVector2Array([
		Vector2(105, 90), Vector2(175, 70), Vector2(245, 90), Vector2(265, 140), Vector2(175, 255), Vector2(85, 140)]))
	for poly in clipped:
		draw_colored_polygon(poly, Color(1, 1, 1, 0.28 * sin(shine * PI)))


## Draws a word left-aligned at `pos` (baseline-centred like the SVG's
## dominant-baseline="middle"), with a per-letter colour ramp.
func _word(text: String, pos: Vector2, fs: int, stops: Array) -> void:
	var f := font()
	var x := pos.x
	var y := pos.y + (f.get_ascent(fs) - f.get_descent(fs)) * 0.5
	var total := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	for i in text.length():
		var ch := text[i]
		var w := f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var t := ((x - pos.x) + w * 0.5) / maxf(total, 1.0)
		draw_string(f, Vector2(x, y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _ramp(stops, t))
		x += w
