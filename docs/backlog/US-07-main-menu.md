# US-07 — Hoofdmenu met mode-selectie

**Fase 2 — Fundament voor meerdere modes** · Afhankelijk van: US-06

## User story

Als speler wil ik vanuit één scherm kiezen welke mode ik speel, zodat ik direct kan beginnen met wat ik leuk vind.

## Relevante code / context

- `ui/hud.gd` (`show_idle`)
- `main.gd` state machine

## Acceptatiecriteria

- [x] Idle-scherm blijft de fidget-board als achtergrond (bubbles blijven poppable).
- [x] Mode-kaarten: Score, Reflex, Memory, Stage — met per mode het persoonlijke record.
- [x] Modes die nog niet bestaan zijn verborgen (niet 'coming soon').
- [x] Laatst gespeelde mode staat voorgeselecteerd (opgeslagen in SaveData).
- [x] Van app-start tot spelen: maximaal 2 taps.
- [x] Werkt in iPhone- en iPad-layout.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `ui/main_menu.gd`: één kaart per mode uit `ModeRegistry` (icoon, naam, persoonlijk record); modes die niet in de registry staan worden niet getoond.
- Fidget-board blijft zichtbaar en poppable; in het menu staat het board iets compacter en bij PLAY glijdt het naar volle grootte (`Board.layout(area, animate)`).
- Laatst gespeelde mode (`last_mode`) is voorgeselecteerd → app-start → PLAY = 1 tik; andere mode = kaart + PLAY = 2 tikken.
- Getest op 720×1280, met notch-simulatie en op iPad-formaat 768×1024, met alle 4 modes (Score, Reflex, Memory, Stages).
