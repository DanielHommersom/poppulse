# US-14 — Stage Mode: level-select scherm

**Fase 3 — Game modes** · Afhankelijk van: US-13

## User story

Als speler wil ik een overzicht van alle levels met mijn sterren zien, zodat ik weet waar ik ben en wat ik nog kan verbeteren.

## Relevante code / context

- Stage-framework (US-13)
- `ui/ui_style.gd`

## Acceptatiecriteria

- [x] Scrollbaar grid met levelnummers, sterren en slotjes.
- [x] Level N+1 ontgrendelt na het halen van level N (≥1 ster).
- [x] Huidige level is visueel uitgelicht en wordt in beeld gescrold bij openen.
- [x] Werkt in iPhone- en iPad-layout; touch-scrolling voelt native (geen per-ongeluk starten bij scrollen).

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `ui/stage_select.gd` (Modal): grid van 5 kolommen in een ScrollContainer, per cel nummer + sterren of een slotje; totaal ★ bovenaan. Opent via PLAY wanneer Stage geselecteerd is (en via 'ALL LEVELS' op het resultaat).
- Ontgrendelen: level N+1 zodra N ≥ 1 ster heeft (`StageLevels.is_unlocked`). Gelockte cel: schud-animatie + fout-haptic; signal `locked_tapped(id, reason)` voor premium-gating (US-29).
- Huidige level (eerste zonder sterren) goud uitgelicht en met `ensure_control_visible` in beeld gescrold.
- Scrollen vs. tikken: knoppen reageren op loslaten en een tik telt alleen als de scrollpositie sinds het indrukken < 8 px veranderde (plus `scroll_deadzone`). Getest op 720×1280 en 768×1024 (iPad).
