# US-16 — Eerste keer spelen zonder tutorial

**Fase 3 — Game modes** · Afhankelijk van: US-07, US-08

## User story

Als nieuwe speler wil ik binnen enkele seconden snappen wat ik moet doen, zonder lange uitleg.

## Relevante code / context

- `ui/hud.gd`
- `main.gd`

## Acceptatiecriteria

- [x] Eerste app-start: direct het board; een pulserende hint 'Tik de oplichtende bubble' bij de eerste lit bubble.
- [x] Eerste potje Score Mode start iets makkelijker (zachtere start-curve) — alleen de eerste keer.
- [x] Per mode één zin uitleg op de mode-kaart of vóór de eerste keer spelen; nooit meer dan één scherm.
- [x] Hints verdwijnen permanent na eerste succesvolle actie (vlag in SaveData).

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- Eerste start: direct het board (menu = fidget-board) met één regel 'Tap the bubbles, then hit PLAY'. Na de eerste fidget-pop wordt dat de uitlegzin van de geselecteerde mode (`blurb` in `ModeRegistry`), zolang die mode nog nooit gespeeld is. Nooit een apart tutorialscherm.
- Eerste oplichtende target in een run krijgt een pulserende coach-mark 'TAP THE GLOWING BUBBLE' (`core/hint_marker.gd`, via nieuw signal `target_lit`); verdwijnt bij de eerste geslaagde hit en komt nooit terug (flag `hint_tap_done`).
- Eerste Score-run ooit: zachtere curve uit `first_run` in `data/score_mode.json` (o.a. spawn 1,15 s, lifetime 2,6 s, ramp over 60 s), alleen als `played == 0`.
- Flags in `SaveData.flags`: `hint_fidget_done`, `hint_tap_done`.
