# US-12 — Memory Mode

**Fase 3 — Game modes** · Afhankelijk van: US-06, US-09

## User story

Als speler wil ik een oplichtend patroon onthouden en naspelen, zodat ik mijn geheugen en focus kan uitdagen.

## Relevante code / context

- `modes/game_mode.gd`
- `core/bubble.gd`
- `autoload/sfx.gd`

## Acceptatiecriteria

- [x] Ronde 1 toont een patroon van 3 bubbles; iedere geslaagde ronde +1.
- [x] Tijdens het tonen is input uitgeschakeld; daarna 'JOUW BEURT'-indicatie.
- [x] Iedere bubble heeft een eigen toon (bestaande toonladder in `Sfx`), zodat het patroon ook hoorbaar is.
- [x] Fout = game over, het juiste patroon wordt nog één keer getoond.
- [x] Toon-snelheid neemt toe per ronde (curve in `data/memory_mode.json`).
- [x] Score = hoogste voltooide patroonlengte; opgeslagen als record.

## Notities

Kleur mag niet de enige aanwijzing zijn: positie + toon tellen mee (zie ook US-38).

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `modes/memory_mode.gd` + `data/memory_mode.json` (board 3×3, `start_length` 3, DifficultyCurve op as `round` voor `show_time` en `show_gap`). Simon-stijl: het patroon groeit met één stap per geslaagde ronde; geen directe herhaling van dezelfde bubble.
- Tijdens tonen: nieuw signal `input_locked` → `main` zet het board uit. Daarna 'YOUR TURN'.
- Iedere bubble speelt zijn eigen toon uit de pentatonische ladder via het nieuwe signal `cue(bubble, note)`; op kleine boards krijgt iedere bubble ook een eigen kleur. Positie + toon + kleur → kleur is nooit de enige aanwijzing.
- Fout → 'IT WAS…' en het juiste patroon wordt nog één keer afgespeeld, daarna resultaat. Score/record = langste voltooide patroon.
- Alles in `_tick` op mode-tijd, dus pauzeerbaar.
