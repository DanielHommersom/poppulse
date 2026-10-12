class_name ThemeData
extends Resource
## One visual theme as data: bubble palette + shader look, background,
## board plate, UI colours and the sound pack. Files live in res://themes/.

@export var id := "neon"
@export var display_name := "Neon"

@export_group("Bubbles")
## "hue_rows": rainbow by row (like the physical toy); "list": `palette` per row.
@export_enum("hue_rows", "list") var palette_mode := "hue_rows"
@export var hue_start := 0.0
@export var hue_span := 0.85
@export var saturation := 0.78
@export var value := 1.0
@export var palette := PackedColorArray()
## Overrides for uniforms in shaders/bubble.gdshader (dim_mix, glow_hi…).
@export var bubble_params := {}

@export_group("Background & board")
@export var bg_top := Color(0.06, 0.03, 0.13)
@export var bg_bottom := Color(0.01, 0.01, 0.04)
@export var bg_accent := Color(0.7, 0.25, 1.0)
@export var bg_grid := 0.045
@export var bg_vignette := 0.6
@export var plate_bg := Color(0.055, 0.05, 0.1)
@export var plate_border := Color(0.6, 0.4, 1.0, 0.35)
@export var plate_glow := Color(0.45, 0.2, 1.0, 0.22)

@export_group("Interface")
@export var ui_accent := Color(1.0, 0.25, 0.7)
@export var ui_cyan := Color(0.25, 0.95, 1.0)
@export var ui_gold := Color(1.0, 0.85, 0.3)
@export var ui_danger := Color(1.0, 0.3, 0.35)
@export var ui_ok := Color(0.4, 1.0, 0.55)
@export var panel_bg := Color(0.07, 0.05, 0.13, 0.97)
@export var panel_border := Color(0.6, 0.35, 1.0, 0.6)
@export var ink := Color(0.05, 0.03, 0.1)

@export_group("Audio & availability")
@export var sfx_pack := "classic"
## free | achievement | premium | event  (gating: US-29 / US-41)
@export_enum("free", "achievement", "premium", "event") var unlock := "free"
## Achievement id, product id or event id that unlocks it.
@export var unlock_ref := ""


## Colour of the bubble at grid cell (col,row) on a cols×rows board.
func bubble_color(index: int, row: int, cols: int, rows: int) -> Color:
	if palette_mode == "list" and not palette.is_empty():
		if cols * rows <= 9:
			return palette[index % palette.size()]
		return palette[row % palette.size()]
	var t := float(row) / rows
	if cols * rows <= 9:  # small boards: every bubble its own colour
		t = float(index) / (cols * rows) * (0.9 / 0.85)
	return Color.from_hsv(fposmod(hue_start + t * hue_span, 1.0), saturation, value)
