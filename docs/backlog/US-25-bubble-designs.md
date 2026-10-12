# US-25 — Unlockable bubble-designs

**Fase 5 — Themes & cosmetics** · Afhankelijk van: US-23

## User story

Als speler wil ik de vorm en look van de bubbles kunnen veranderen, zodat het speelveld persoonlijker voelt.

## Relevante code / context

- `core/bubble.gd`
- `shaders/bubble.gdshader`

## Acceptatiecriteria

- [x] Shader ondersteunt minimaal 3 varianten (rond, hart/ster of afgeronde vierkant, 'jelly').
- [x] Hitbox blijft gelijk ongeacht design (geen gameplay-verschil).
- [x] Design is los te kiezen van het thema.
- [x] Unlock-voorwaarden in data.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `shaders/bubble.gdshader`: uniform `shape` met SDF-varianten 0 rond, 1 tegel (afgeronde vierkant), 2 hart, 3 ster, 4 jelly (wiebelende blob), 5 gem (hexagon). Dezelfde dome-belichting werkt op iedere vorm (diepte vanaf de rand + normaal van de omtrek). Vorm 0 volgt exact het oude codepad, dus Neon/Classic blijft pixel-gelijk.
- Hitbox blijft altijd de cirkel in `Board.bubble_at()` — design is puur visueel (gecheckt in scenario `s_designs`).
- Los van het thema: setting `design`, `ThemeManager.apply_design()` + signal `design_changed`.
- Unlocks in `data/designs.json`: Classic/Tile gratis, Jelly (eerste run), Heart (eerste daily), Star (level 10), Gem (Galaxy-pack).
- Kiezen via het style-sheet (palet-icoon), tab BUBBLES, met live preview op het board; de chips tonen een echte shader-bubble.
