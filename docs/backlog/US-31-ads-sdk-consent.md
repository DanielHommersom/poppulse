# US-31 — Advertentie-SDK, ATT en toestemming

**Fase 6 — Monetization** · Afhankelijk van: US-01, US-27

## User story

Als speler in de EU wil ik zelf kiezen of mijn data voor advertenties gebruikt wordt, en als ontwikkelaar wil ik advertenties tonen die voldoen aan de wet en de App Store-regels.

## Relevante code / context

- Monetization-interface (US-27)

## Acceptatiecriteria

- [x] AdMob (of gekozen netwerk) geïntegreerd via een Godot 4-compatibele plugin, alleen achter `Platform`.
- [x] Google UMP consent-formulier (AVG/TCF) bij eerste start in de EER/VK, pas na de eerste gespeelde game.
- [x] App Tracking Transparency-prompt correct volgorde: consent → ATT; weigeren = niet-gepersonaliseerde ads.
- [x] Ads worden nooit geladen of getoond als `premium_unlock` actief is.
- [x] Test-ad-units in debug, echte units alleen in release-config.
- [x] Privacy-instelling 'Advertentietoestemming wijzigen' in settings.

## Notities

Controleer vooraf of de gekozen plugin Godot 4.7 ondersteunt.

## Definition of done

- [ ] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [ ] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `platform/admob_ads.gd` (`AdMobAds`): rewarded + interstitial + Google UMP via de Poing Studios godot-admob-addon (ondersteunt Godot 4.1+; build voor 4.7 vóór installatie controleren, zie `docs/ads.md`). Addon-scripts worden dynamisch geladen, dus zonder addon compileert alles en draait de mock.
- Volgorde: eerste potje → UMP-consent (Google toont het alleen in EER/VK) → ATT (eigen `PopPulseNative.request_tracking_authorization`) → SDK start; weigeren = niet-gepersonaliseerde ads (`npa=1`). Status in `SaveData.ads`.
- Premium: SDK wordt nooit gestart, `can_show_rewarded`/`maybe_show_interstitial` tonen nooit iets.
- Test-units in debug, echte units alleen in release (`data/ads.json`; release-id's en `GADApplicationIdentifier` nog invullen).
- Settings ▸ PRIVACY ▸ CHANGE AD CONSENT.
- **Open:** addon + iOS-plugin installeren, eigen AdMob-app/unit-id's invullen en de volledige flow (UMP-formulier in de EER, ATT-prompt, ads) op een toestel testen.

**Update 5 okt 2026:** Poing Studios godot-admob **v5.1.0** geïnstalleerd (`addons/admob`, iOS-library voor Godot 4.7.2 in `addons/admob/ios/bin`), echte iOS app-id en units ingevuld. Proef-export "iOS Playtest" (debug) → ARCHIVE + EXPORT SUCCEEDED; Info.plist bevat `GADApplicationIdentifier`, 50 SKAdNetwork-id's en `NSUserTrackingUsageDescription`. ATT-vraag loopt via Google UMP (IDFA explainer-bericht in AdMob moet gepubliceerd zijn). Nog open: de flow op een toestel testen.
