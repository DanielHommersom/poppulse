# US-34 — Analytics en soft-launch metrics

**Fase 6 — Monetization** · Afhankelijk van: US-31

## User story

Als ontwikkelaar wil ik retentie, sessies en opbrengst kunnen meten, zodat ik op basis van data beslis over balans en monetization.

## Relevante code / context

- `autoload/platform.gd`

## Acceptatiecriteria

- [x] `Platform.track(event, params)` met een gekozen backend (bv. Firebase Analytics of een privacyvriendelijk alternatief).
- [x] Events: app_open, mode_start, mode_end (score, duur), level_complete/fail, upsell_shown, purchase, ad_shown, ad_rewarded.
- [x] Respecteert consent uit US-31.
- [x] Dashboard/notitie in `docs/metrics.md` met doelen: D1, D7, sessies per dag, conversie premium, ARPDAU.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- Gekozen backend: **TelemetryDeck** via de HTTP-ingest-API (`platform/analytics.gd`), privacy-vriendelijk en zonder native SDK. `Platform.track(event, params)`; batches elke 20 s. `app_id` in `data/analytics.json` nog invullen; zonder id wordt niets verstuurd.
- Events: `app_open`, `mode_start`, `mode_end` (score, duur), `level_complete`/`level_fail`, `upsell_shown`, `purchase`, `ad_shown`, `ad_rewarded`.
- Consent uit US-31: events wachten in het geheugen tot de consent-flow klaar is; alleen verstuurd bij toestemming, gedropt bij weigeren (test: `tests/test_analytics.gd`). Geen IDFA, alleen een willekeurige install-id.
- `docs/metrics.md`: eventlijst, doelen (D1 ≥ 35 %, D7 ≥ 12 %, sessies/dag, Premium-conversie ≥ 2 %, ARPDAU ≥ €0,03, …) met acties en dashboard-opzet.

**Vervallen (5 okt 2026, keuze product owner):** TelemetryDeck en alle analytics-events zijn uit de code verwijderd. Metingen via App Store Connect en AdMob, zie `docs/metrics.md`.
