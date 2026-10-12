# US-17 — Daily Challenge

**Fase 4 — Retentie** · Afhankelijk van: US-07, US-08

## User story

Als speler wil ik iedere dag een nieuwe uitdaging, zodat ik een reden heb om dagelijks terug te komen.

## Relevante code / context

- ModeRegistry (US-06)
- SaveData (US-08)

## Acceptatiecriteria

- [x] Iedere dag een challenge op basis van een seed uit de datum (UTC) → iedereen krijgt dezelfde challenge.
- [x] Challenge = een bestaande mode met gevarieerde parameters (bv. 'Score Mode, 45 s, alleen 2 tegelijk').
- [x] Eén officiële poging per dag; daarna onbeperkt oefenen (telt niet).
- [x] Kaart in het hoofdmenu met status (open / gespeeld + score) en aftellen tot de volgende.
- [x] Bescherming tegen klok terugzetten: een dag kan maar één keer gespeeld worden.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `core/daily.gd`: dag = UTC-dagnummer; challenge = sjabloon + parameterkeuzes uit `data/daily.json`, gekozen met een RNG geseed op `hash("poppulse-daily-<dag>")` → wereldwijd dezelfde challenge. De run zelf krijgt ook een vaste seed (`context.seed`), zodat de spawn-volgorde voor iedereen gelijk start.
- Modes gebruiken nu een eigen `GameMode.rng` (+ `pick()`/`shuffled()`) i.p.v. de globale RNG.
- Challenge = bestaande mode (Score / Reflex / Memory) met overrides op config-paden, bv. 'SCORE · 45s · max 2 at once'. Dagelijkse runs tellen nooit mee voor de gewone mode-records.
- Eén officiële poging: telt zodra GO valt (stoppen via pauze verbruikt hem dus ook). Daarna 'PRACTICE' = onbeperkt, telt niet. Extra officiële pogingen (rewarded, US-32) houden de beste score.
- Menukaart (`ui/daily_card.gd`) boven het board: titel van vandaag + PLAY, of 'DONE <score> · next in HH:MM:SS' (live aftellend).
- Klok terugzetten: hoogste ooit geziene dag wordt bewaard; een eerdere datum geeft nooit een eerdere (al gespeelde) dag terug.
- Tests: `tests/test_daily.gd` (determinisme, overrides, één poging + retry, klok terug, seed).
