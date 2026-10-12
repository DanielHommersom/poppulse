# Data-formaten

Alle tuning staat in `data/*.json`. JSON-getallen zijn altijd floats; de code rondt af waar nodig. Live aanpassen tijdens een playtest kan met de tuning-overlay (debug, F2 / 3-vinger-tap) — 'EXPORT JSON' levert direct een plakbare config.

## Gemeenschappelijk (iedere mode-config)

| Veld | Type | Betekenis |
|---|---|---|
| `board` | `[cols, rows]` | Grootte van het board voor deze mode (default `[5, 6]`). |
| `difficulty` | DifficultyCurve | Zie hieronder. |

## DifficultyCurve

Gebruikt door `core/difficulty_curve.gd`. Eén curve interpoleert meerdere parameters langs één as.

```json
"difficulty": {
  "axis": "time",
  "x_start": 0,
  "x_end": 50,
  "easing": "linear",
  "params": {
    "spawn_interval": [0.9, 0.34],
    "lifetime": { "keys": [[0, 1.9], [30, 1.2], [50, 0.8]] },
    "max_active": [1, 4],
    "simultaneous_targets": 2
  }
}
```

| Veld | Waarden | Betekenis |
|---|---|---|
| `axis` | `time` · `level` · `round` | Waar x voor staat: seconden in de run, levelnummer of rondenummer. Puur documentatie: de mode bepaalt welke x hij doorgeeft. |
| `x_start`, `x_end` | getal | Bereik waarover van start- naar eindwaarde gaat. Daarbuiten wordt geclampt. |
| `easing` | `linear` · `ease_in` · `ease_out` · `ease_in_out` (= `smooth`) | Vorm van de overgang. |
| `params.<naam>` | `[start, eind]` | Interpolatie over `x_start..x_end`. |
|  | `{"keys": [[x, v], …]}` | Keyframes in as-eenheden (stuksgewijs, easing per segment). |
|  | getal | Constante. |

Ondersteunde parameters (een mode leest alleen wat hij nodig heeft):

| Parameter | Eenheid | Gebruikt door |
|---|---|---|
| `spawn_interval` | s tussen spawns | Score, Stage |
| `lifetime` | s dat een target oplicht | Score, Stage |
| `max_active` | aantal tegelijk actieve targets (afgerond) | Score, Stage |
| `simultaneous_targets` | targets die in één keer oplichten (afgerond) | Stage |
| `pattern_length` | lengte van een patroon (afgerond) | Memory |
| `show_time` | s per stap bij het tonen van een patroon | Memory |
| `wait_min`, `wait_max` | s wachttijd vóór een prikkel | Reflex |

Telparameters (`max_active`, `simultaneous_targets`, `pattern_length`, `targets`) worden afgerond naar een geheel getal.

## `data/score_mode.json`

| Veld | Betekenis |
|---|---|
| `duration` | Lengte van een run in seconden. |
| `empty_gap` | Maximale pauze (s) wanneer er geen target actief is. |
| `difficulty` | Curve, `axis = time`. |
| `points.base` | Punten per hit vóór multiplier. |
| `points.speed_bonus` / `speed_window` | Extra punten bij snelle reactie: vol bij 0 s, nul bij `speed_window` s. |
| `points.combo_step` | Hits per multiplier-stap. |
| `points.max_multiplier` | Plafond van de multiplier. |
| `points.wrong_penalty` | Aftrek bij een verkeerde tik (nooit onder 0). |
