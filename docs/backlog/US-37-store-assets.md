# US-37 — App-icoon, launch screen en App Store-assets

**Fase 7 — Launch-ready** · Afhankelijk van: US-24

## User story

Als potentiële speler wil ik in de App Store direct zien hoe de game eruitziet en aanvoelt, zodat ik hem download.

## Relevante code / context

- `tools/capture.gd` (bestaande capture-tool)
- `icon.svg`

## Acceptatiecriteria

- [x] Definitief app-icoon (alle iOS-formaten) in de neon-stijl.
- [x] Launch screen sluit naadloos aan op het eerste frame van de game.
- [x] Screenshots voor 6,9" iPhone en 13" iPad automatisch gegenereerd via de capture-tool.
- [x] App preview-video (15–30 s) van een combo-run.
- [x] Eigen naam en uitstraling; geen verwijzing naar namen of merkuitingen van het fysieke speelgoed.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `tools/store_assets.tscn` rendert alles offscreen: icoon (1024 + alle iOS-formaten, opaak), launch images en 5 screenshots per toestel op exact 1320×2868 (6,9") en 2064×2752 (13" iPad), in de 720-brede design-units van de game.
- Launch screen: storyboard-afbeelding + Godot-bootsplash = de achtergrond-shader van het eerste frame, dus naadloze overgang. Icoon ook als projecticoon.
- App preview: 24 s combo-run (combo 49, x8), 886×1920 H.264 MP4 via Godot Movie Maker + `tools/make_preview.swift` (AVFoundation, geen ffmpeg nodig).
- Eigen naam: zichtbare naam is nu **Pop Pulse** (`core/app_info.gd`) — 'Pop It' is de merknaam van het speelgoed. User-map blijft 'PopIt' zodat bestaande saves blijven werken. **Werktitel: merkcheck vóór launch.**
- Uitleg in `docs/store-assets.md`.
