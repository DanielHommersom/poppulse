# US-15 — 30 levels ontwerpen

**Fase 3 — Game modes** · Afhankelijk van: US-13, US-14

## User story

Als speler wil ik 30 levels met een geleidelijke, afwisselende moeilijkheidscurve, zodat het uitdagend blijft zonder frustrerend te worden.

## Relevante code / context

- `data/stages/`
- Tuning-overlay (US-05)

## Acceptatiecriteria

- [x] 30 levels in data, verdeeld in 3 blokken van 10 met elk een nieuw element (bv. meerdere tegelijk, kortere lifetime, vaste patronen/'niet tikken'-bubbles).
- [x] Iedere 5e level is een piek, daarna kort wat makkelijker.
- [ ] Alle levels zijn door de ontwikkelaar gehaald met ≥1 ster; drempels voor 3 sterren zijn haalbaar.
- [x] Overzichtstabel in `docs/levels.md` (id, nieuw element, doel, tijd).

## Definition of done

- [ ] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- 30 levels in `data/stages/stages.json`, gegenereerd met `tools/gen_levels.py` en daarna gebalanceerd met `tools/level_bot.tscn` (twee gesimuleerde spelers, 5 runs per level).
- Blokken: 1–10 meerdere targets tegelijk / in paren, 11–20 kortere lifetime, 21–30 vaste patronen + 'niet tikken'-bubbles. Levels 5/10/15/20/25/30 zijn pieken; 6/16/26 zijn bewust rustiger.
- Tijdslimieten en sterdrempels zijn afgeleid uit de gemeten bot-tijden (zie `docs/levels.md`). Resultaat laatste run: skilled-bot haalt alles, meestal ★★★; casual-bot haalt 141/150 runs, meestal ★★, en faalt alleen af en toe op pieken.
- **Open:** 'door de ontwikkelaar gehaald' kan ik niet voor je doen — de bot-runs zijn een onderbouwing, geen vervanging voor zelf spelen op een toestel. Daarna drempels zo nodig bijstellen in de JSON of met de tuning-overlay.

- 12 oktober 2026: getest op iPhone door product owner — akkoord.
