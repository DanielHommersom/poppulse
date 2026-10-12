# US-05 — Debug tuning-overlay voor game feel

**Fase 1 — MVP valideren**

## User story

Als ontwikkelaar wil ik tijdens het spelen de parameters uit `data/score_mode.json` live kunnen aanpassen, zodat ik snel de juiste moeilijkheid en flow vind tijdens playtests.

## Relevante code / context

- `data/score_mode.json`
- `modes/score_mode.gd`

## Acceptatiecriteria

- [x] Overlay alleen in debug builds (`OS.is_debug_build()`), te openen met 3-vinger-tap of toets.
- [x] Sliders voor spawn_interval, lifetime, max_active (start/end), ramp_time en de points-waarden.
- [x] Wijzigingen werken direct in het lopende potje.
- [x] Knop 'Exporteer JSON' kopieert de huidige waarden naar het klembord / logt ze.

## Buiten scope

Release builds mogen deze code niet bevatten of tonen.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `debug/tuning_overlay.gd` wordt door `main.gd` alleen geladen als `OS.is_debug_build()` én het bestand bestaat. De release-preset `iOS` sluit `debug/*` uit, dus de code zit niet in de release-PCK. De preset `iOS Playtest` houdt hem wel.
- Openen: 3-vinger-tap, F2 of ` (backtick). Toont ook een FPS-teller.
- Sliders worden gegenereerd uit een pad-lijst; paden die de actieve mode niet heeft worden overgeslagen, zodat dezelfde overlay later ook voor Reflex/Memory/Stage werkt. Wijzigingen schrijven direct in `mode.cfg` en roepen optioneel `mode.on_tuning_changed()` aan.
- 'EXPORT JSON' zet de config op het klembord en logt hem.
