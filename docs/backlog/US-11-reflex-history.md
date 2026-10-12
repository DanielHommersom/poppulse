# US-11 — Reflex-geschiedenis en voortgang

**Fase 3 — Game modes** · Afhankelijk van: US-10

## User story

Als speler wil ik zien hoe mijn reactietijd zich ontwikkelt, zodat ik gemotiveerd blijf om te oefenen.

## Relevante code / context

- Reflex Mode (US-10)
- SaveData (US-08)

## Acceptatiecriteria

- [x] Op het resultatenscherm een kleine lijngrafiek van de laatste 20 rondes (gemiddelde per ronde).
- [x] Weergave: beste ooit, gemiddelde van laatste 10, trend (↑/↓).
- [x] Getekend met `_draw()` in de neon-stijl, geen externe library.

## Buiten scope

Uitgebreid stats-scherm (US-19). Premium-gating hiervan gebeurt in US-29.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `ui/reflex_graph.gd`: lijngrafiek met `_draw()` (glow-lijn, punten, gestippelde gouden BEST-lijn). Y-as omgedraaid: hoger = sneller.
- Data: `recent` (laatste 20 gemiddelden) uit de save; rondes zonder geldige meting worden niet in de grafiek opgenomen.
- Onder de grafiek: BEST, gemiddelde laatste 10 en trend (↑ sneller / ↓ trager, vergelijking laatste 5 vs. 5 daarvoor).
- Getoond via `main._result_extras()` (presentatie blijft buiten de mode). Test: `test_reflex_summary`.
