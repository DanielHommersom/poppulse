# US-13 — Stage Mode: level-framework

**Fase 3 — Game modes** · Afhankelijk van: US-06, US-08, US-09

## User story

Als speler wil ik levels doorlopen met een duidelijk doel, zodat ik een gevoel van voortgang heb.

## Relevante code / context

- `modes/game_mode.gd`
- Difficulty Manager (US-09)

## Acceptatiecriteria

- [x] Levels staan in `data/stages/*.json` (of één bestand) met o.a.: board-grootte, doel (X targets raken), tijdslimiet, max fouten, spawn-parameters, optionele vaste patronen.
- [x] `StageMode` laadt een level op id en meldt win/verlies via `finished(results)`.
- [x] Sterren 1–3 op basis van tijd en/of fouten (drempels per level in data).
- [x] Resultaatscherm: sterren, 'Volgende level' / 'Opnieuw'.
- [x] Voortgang (beste sterren per level) opgeslagen in SaveData.
- [x] Drie test-levels om het framework te bewijzen.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- Levels in `data/stages/stages.json` (`defaults` + `levels[]`): `board`, `goal`, `time_limit`, `max_mistakes`, `difficulty` (DifficultyCurve, as `time`), optioneel `pattern` (+`pattern_loop`), `decoy_chance` ('niet tikken'-bubbles met kruis) en `stars`-drempels. Laden + mergen via `core/stage_levels.gd`.
- `modes/stage_mode.gd` laadt het level uit `context.level_id` en meldt winst/verlies via `finished(results)` (`won`, `stars`, `level_id`…). Fouten = verkeerde tik, gemiste target of decoy aangetikt; te veel fouten of tijd op = verlies.
- Sterren: 1 = gehaald; 2/3 als tijd én fouten binnen de drempels van die tier vallen (`StageLevels.stars_for`).
- Resultaat: sterren (pop-in animatie, `ui/stars_row.gd`), NEXT LEVEL / RETRY.
- Voortgang: beste sterren + beste tijd per level in `SaveData` (`stage.stars`, `stage.best_time`); het record op de mode-kaart is het totaal aantal sterren.
- Drie testlevels: basis, twee tegelijk, vast patroon + decoys. Getest met scenario `s_stage` (halen met 3 sterren, decoys laten staan, falen door fouten).
