# US-09 — Gedeelde, data-driven Difficulty Manager

**Fase 2 — Fundament voor meerdere modes** · Afhankelijk van: US-06

## User story

Als ontwikkelaar wil ik moeilijkheid in alle modes vanuit JSON-curves sturen, zodat ik balans kan aanpassen zonder gameplaycode te wijzigen.

## Relevante code / context

- `modes/score_mode.gd` (huidige start/end ramp)
- `data/score_mode.json`

## Acceptatiecriteria

- [x] `DifficultyCurve`-klasse: interpoleert parameters op basis van tijd, level of ronde (lineair + easing-optie).
- [x] Ondersteunde parameters minimaal: spawn_interval, lifetime, max_active, simultaneous_targets, pattern_length.
- [x] Score Mode gebruikt de nieuwe klasse; gedrag identiek aan nu.
- [x] JSON-schema is gedocumenteerd in `docs/data-format.md`.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `core/difficulty_curve.gd`: as `time`/`level`/`round`, `x_start`/`x_end`, easing `linear`/`ease_in`/`ease_out`/`ease_in_out`; parameters als `[start, eind]`, keyframes of constante. Telparameters worden afgerond.
- Score Mode leest nu `difficulty` uit `data/score_mode.json`. `tests/test_difficulty.gd` vergelijkt elke 0,25 s van 0–65 s met de oude lineaire ramp: identiek.
- Schema in `docs/data-format.md`; wordt per nieuwe mode aangevuld.
