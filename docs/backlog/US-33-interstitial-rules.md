# US-33 — Interstitials met strikte frequentieregels

**Fase 6 — Monetization** · Afhankelijk van: US-31

## User story

Als gratis speler wil ik zo min mogelijk gestoord worden door advertenties, zodat het spel leuk blijft.

## Relevante code / context

- Ads SDK (US-31)
- `main.gd` (RESULTS → IDLE overgang)

## Acceptatiecriteria

- [x] Alleen bij de overgang resultaten → menu/volgende potje, nooit tijdens spel of countdown.
- [x] Niet in de eerste sessie; niet binnen 3 potjes na de vorige; minimaal 120 s ertussen.
- [x] Niet direct na een persoonlijk record of na het kijken van een rewarded ad.
- [x] Alle drempels in `data/ads.json` zodat ze tijdens soft launch aanpasbaar zijn.
- [x] Nooit voor premium-gebruikers.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `core/ad_rules.gd` (`AdRules.may_show`): pure regelfunctie, unit-getest in `tests/test_ad_rules.gd`.
- Alleen bij de overgang resultaat → menu (`results_to_menu`) of resultaat → volgende run (`results_to_next`: PLAY AGAIN / NEXT LEVEL / RETRY); `main._leave_results()` is de enige plek die `maybe_show_interstitial` aanroept — nooit tijdens spel of countdown.
- Niet in de eerste sessie (`min_sessions`), niet binnen 3 runs (`runs_between`), min. 120 s ertussen (`min_seconds_between`), niet na een persoonlijk record of na een rewarded ad (`skip_after_record`, `skip_after_rewarded`). Alles in `data/ads.json` → `interstitial`.
- Nooit voor premium (`Platform.ads_disabled()`), en nooit vóór de consent-flow uit US-31 klaar is.
- Scenario `s_interstitial`: 5 runs → precies 1 interstitial (na run 3).

- 17 oktober 2026 (build 2): gebalanceerde regels — eerste sessie vanaf 3e potje, nieuwe sessie na 30 min achtergrond, 90 s tussenruimte, records blokkeren niet meer (wel het 1e potje per modus). Getest in tests/test_ad_rules.gd.
