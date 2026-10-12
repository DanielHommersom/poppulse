# US-42 — Android-versie

**Fase 8 — Na launch** · Afhankelijk van: US-27, US-21

## User story

Als Android-gebruiker wil ik dezelfde game kunnen spelen.

## Relevante code / context

- `autoload/platform.gd` (alle platform-API's)

## Acceptatiecriteria

- [ ] Android export preset; draait op telefoon en tablet.
- [ ] Platformlaag-implementaties: haptics, Google Play Billing, Play Games leaderboards/achievements, AdMob Android, share.
- [x] Back-knop gedrag correct (pauze / terug naar menu).
- [ ] Getest op minimaal één goedkoop en één high-end toestel.

## Definition of done

- [ ] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- Android-preset in `export_presets.cfg` (AAB, gradle build, arm64 + armv7, min SDK 24 / target 35, telefoon + tablet, immersive, vibrate/billing/AD_ID-permissies).
- Platformlaag: `PlayBilling` (`platform/play_billing.gd`: prijzen, aankoop, pending, annuleren, acknowledge, stille restore; test met nep-plugin), Play Games Services in `Platform` (sign-in, scores, leaderboard tonen, achievements; id's in `data/game_services.json`), AdMob via dezelfde `AdMobAds` (Android-units in `data/ads.json`), en een Android-versie van `PopPulseNative` in Kotlin (haptics met predefined effects, share sheet via FileProvider, 'animaties verwijderen') met dezelfde API als iOS + export-plugin `addons/poppulse_native`.
- Back-knop (`main._on_back`): sluit sheet/modal, hervat vanuit pauze, pauzeert een run, resultaten → menu, menu → app sluiten (getest in scenario `s_back`).
- Stappen in `docs/build-android.md`.
- **Open:** Android-plugins bouwen/installeren (PopPulseNative-AAR, Play Billing, Play Games, AdMob), Play Console-producten + Play Games-id's invullen, en testen op een goedkoop én een high-end toestel. Er is hier niets voor Android gebouwd of op een toestel gedraaid.
