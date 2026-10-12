# US-24 — Extra themes en theme-kiezer

**Fase 5 — Themes & cosmetics** · Afhankelijk van: US-23

## User story

Als speler wil ik kiezen uit verschillende visuele themes, zodat ik de game naar mijn smaak kan maken.

## Relevante code / context

- Theme-systeem (US-23)

## Acceptatiecriteria

- [x] Minimaal 4 extra themes (bv. Sunset, Ice, Candy, Mono/Retro LCD).
- [x] Theme-kiezer in het menu met live preview op het fidget-board.
- [x] Themes hebben een status: gratis / unlock via prestatie / premium / los te kopen (veld in data; gating zelf in US-29/US-30).
- [x] Gekozen thema wordt opgeslagen.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- 6 extra thema's in `themes/`: **Sunset** (gratis), **Ice** (achievement 'On a Roll' / combo 25), **Candy**, **Retro LCD**, **Aurora** (premium), **Galaxy** (pack `pack_galaxy`, US-30). Elk met eigen palet, shader-look, achtergrond, plaat, UI-kleuren en sound pack.
- Status per thema in data (`unlock` = free/achievement/premium/pack + `unlock_ref`); `ThemeManager.is_available()` / `status_text()`. Premium/pack-checks lopen via `Platform.is_entitled()`; de koop-flow zelf volgt in US-29/30.
- Kiezer (`ui/theme_picker.gd`) is een bottom sheet via het palet-icoon in de menubalk. Het fidget-board blijft zichtbaar én poppable: tikken op een thema = live preview (ook gelockte), 'USE THEME' slaat op, sluiten zonder kiezen zet het opgeslagen thema terug.
- Keuze opgeslagen als setting `theme` en bij start toegepast.
