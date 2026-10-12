# US-04 — Pauze en app-onderbreking

**Fase 1 — MVP valideren**

## User story

Als speler wil ik dat het spel pauzeert als ik een melding krijg of de app wegklik, zodat ik niet onterecht een slechte score krijg.

## Relevante code / context

- `main.gd` (GameState)
- `modes/game_mode.gd`

## Acceptatiecriteria

- [x] Nieuwe state `PAUSED` in de state machine van `main.gd`.
- [x] `NOTIFICATION_APPLICATION_FOCUS_OUT` / `PAUSED` tijdens PLAYING of COUNTDOWN → automatisch pauzeren.
- [x] Pauzeknop in de HUD tijdens PLAYING; pauze-overlay met Doorgaan / Stoppen.
- [x] Bij Doorgaan: korte 3-2-1 countdown voordat de timer weer loopt.
- [x] Actieve bubbles bevriezen (lifetime telt niet door) tijdens pauze.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `GameState.PAUSED` in `main.gd`; de 3-2-1-countdown draait nu in `_process` (geen `await`-keten meer), zodat ook een countdown pauzeerbaar is.
- Auto-pauze op `NOTIFICATION_APPLICATION_FOCUS_OUT` / `APPLICATION_PAUSED` / `WM_WINDOW_FOCUS_OUT` tijdens PLAYING of COUNTDOWN.
- Pauzeknop bovenin het midden tijdens PLAYING; `ui/pause_overlay.gd` met RESUME / QUIT RUN (X = hervatten). Stoppen slaat geen score op.
- `GameMode.paused` bevriest `elapsed`, dus ook lifetimes en de countdown-ring van actieve bubbles. Vastgehouden vingers worden losgelaten (`Board.release_touches()`).
- Getest met scenario `tools/scenario.gd` → `s_pause` (elapsed bevroren tijdens pauze én countdown; hervat daarna).
