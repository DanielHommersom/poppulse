# US-19 — Records- en statistiekenscherm

**Fase 4 — Retentie** · Afhankelijk van: US-08, US-11

## User story

Als speler wil ik al mijn records en statistieken op één plek zien, zodat ik mijn progressie kan volgen.

## Relevante code / context

- SaveData (US-08)
- Reflex-geschiedenis (US-11)

## Acceptatiecriteria

- [x] Per mode: record, aantal potjes, gemiddelde, speeltijd.
- [x] Reflex: beste tijd, gemiddelde laatste 10, grafiek.
- [x] Stage: totaal sterren / 90.
- [x] Bereikbaar vanuit het hoofdmenu.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `ui/stats_panel.gd` (Modal 'RECORDS'), bereikbaar via het grafiek-icoon in de menubalk (naast settings), ook vanaf het resultaatscherm.
- Per mode: record, aantal runs, gemiddelde, speeltijd. Reflex: snelste losse tik, gemiddelde laatste 10 en de grafiek uit US-11. Stage: totaal sterren / 90. Extra: Daily-blok (streak, beste streak, dagen gespeeld).
- Trofee-knop per mode verschijnt zodra er een leaderboard bestaat (US-21).
