# US-18 — Dagelijkse streak

**Fase 4 — Retentie** · Afhankelijk van: US-17

## User story

Als speler wil ik zien hoeveel dagen op rij ik heb gespeeld, zodat ik mijn reeks niet wil verbreken.

## Relevante code / context

- Daily Challenge (US-17)

## Acceptatiecriteria

- [x] Streak +1 bij het voltooien van de daily challenge; reset bij een gemiste dag.
- [x] Weergave in het hoofdmenu (vlam-icoon + getal) en op het daily-resultaatscherm.
- [x] Mijlpalen 3 / 7 / 30 dagen krijgen een speciale animatie.
- [x] Geen push-notificaties in deze story.

## Buiten scope

Streak-freeze (kan later als rewarded/premium perk).

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `Daily.complete_day()` bij het afronden van de officiële daily: +1 als gisteren ook gedaan, anders opnieuw 1. `Daily.current_streak()` geeft 0 zodra een dag is overgeslagen. `best_streak` wordt bewaard.
- Weergave: vlam-icoon + getal op de daily-kaart in het hoofdmenu en op het daily-resultaatscherm (`ui/streak_burst.gd`).
- Mijlpalen 3 / 7 / 30: grote vlam die inpopt met stralenkrans, gouden '<n> DAY STREAK!', geluid + zware haptic.
- Geen push-notificaties. Test: `test_daily.test_streak` (zelfde dag, volgende dag, gemiste dag, best).
