# US-06 — Game modes loskoppelen van main.gd

**Fase 2 — Fundament voor meerdere modes**

## User story

Als ontwikkelaar wil ik dat `main.gd` iedere `GameMode` kan draaien zonder hardcoded `ScoreMode`, zodat nieuwe modes toegevoegd kunnen worden zonder de game manager te wijzigen.

## Relevante code / context

- `main.gd` (`mode = ScoreMode.new()`)
- `modes/game_mode.gd`
- `modes/score_mode.gd`

## Acceptatiecriteria

- [x] `ModeRegistry` (of const dictionary) koppelt `mode_id` → script + config + weergavenaam + icoon.
- [x] `main.gd` heeft `start_mode(mode_id)` die de oude mode netjes opruimt (signals los, `queue_free`) en de nieuwe koppelt.
- [x] `GameMode` krijgt optionele hooks die HUD-elementen aan/uit zetten (bv. `uses_timer()`, `uses_combo()`).
- [x] Score Mode werkt exact zoals nu (regressie handmatig getest).
- [x] Board-grootte (cols/rows) kan per mode verschillen.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `modes/mode_registry.gd`: `MODES` (id → script, config, naam, icoon, kleur, blurb) + `ORDER`; ids die niet in `MODES` staan worden overgeslagen.
- `main.start_mode(id)` koppelt alle mode-signals via één lijst (`_mode_links()`), ontkoppelt/verwijdert de oude mode en herbouwt het board als `board_size()` verschilt.
- Hooks op `GameMode`: `uses_timer()`, `uses_combo()`, `uses_score()`, `board_size()` (uit `"board": [cols, rows]` in de JSON), `lower_is_better()`, `format_value()`, `on_tuning_changed()`. Config laadt nu centraal (diep gekopieerd, zodat tuning de gecachte JSON niet wijzigt).
- Resultaatkaart losgetrokken naar `ui/results_panel.gd`; modes leveren `title` + `stats` in hun results-dictionary.
- Regressie: scenario `s_score` (combo, x4, fout, resultaat, NEW BEST) gedraagt zich als voorheen.
