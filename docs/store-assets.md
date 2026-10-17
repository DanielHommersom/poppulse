# App Store-assets

Alles wordt gegenereerd door de game zelf, dus na een visuele wijziging opnieuw draaien.

| Asset | Pad | Opnieuw maken |
|---|---|---|
| App-icoon 1024 + alle iOS-formaten (20–180), zonder alpha | `store/icon/` | `Godot --path . res://tools/store_assets.tscn -- --test-save --fresh` |
| Launch images (@2x, @3x) = het eerste frame van de game (achtergrond-shader zonder UI) | `store/launch/` | idem |
| Screenshots 6,9" iPhone (1320×2868) en 13" iPad (2064×2752): menu, combo, resultaat, levels, thema's | `store/screenshots/` | idem |
| App preview 886×1920, H.264, ~24 s combo-run | `store/preview/app_preview_886x1920.mp4` | zie hieronder |

## Launch screen

De preset gebruikt `store/launch/launch@2x/@3x.png` als storyboard-afbeelding op dezelfde achtergrondkleur, en het Godot-bootsplash toont dezelfde afbeelding full-size. Daarna tekent de game exact die achtergrond, waarna pas de UI verschijnt: geen zichtbare sprong.

## App preview opnemen

```bash
printf '[display]\n\nwindow/size/window_width_override=443\nwindow/size/window_height_override=960\n' > override.cfg
/Applications/Godot.app/Contents/MacOS/Godot --path . --write-movie store/preview/frames/f.png --fixed-fps 30 res://tools/scenario.tscn -- --test-save --fresh --scenario=preview
rm override.cfg
swift tools/make_preview.swift store/preview/frames store/preview/app_preview_886x1920.mp4
```

(`override.cfg` zet het venster tijdelijk op 443×960, de helft van 886×1920; `make_preview.swift` schaalt ×2 en encodeert met AVFoundation.)

## Naam

**App Store-naam: "Pop Pulse: Bubble Reflex"** (App Store Connect, 13 oktober 2026). "Pop Pulse" alleen was al gereserveerd in de App Store. Op het beginscherm (`config/name`) en in de game blijft het "Pop Pulse"; Apple staat een kortere naam op het beginscherm toe.

De game heet in de build **Pop Pulse** (werktitel, `core/app_info.gd`). 'Pop It' is de merknaam van het fysieke speelgoed en wordt nergens meer getoond; interne id's (`com.digitaldiamonds.poppulse`, user-map) zijn onzichtbaar voor spelers. **Doe vóór launch een merkcheck** (EUIPO / USPTO / App Store-zoekopdracht) en pas zo nodig `AppInfo`, `config/name` in `project.godot` en de producttitels aan.
