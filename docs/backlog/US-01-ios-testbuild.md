# US-01 — iOS test-build via TestFlight

**Fase 1 — MVP valideren**

## User story

Als ontwikkelaar wil ik de huidige Score Mode als build op mijn iPhone en iPad kunnen installeren, zodat ik de game feel op echte hardware (touch, haptics, 120 Hz) kan valideren.

## Relevante code / context

- `project.godot` (Mobile renderer, portrait)
- Godot 4.7 export templates

## Acceptatiecriteria

- [x] iOS export preset staat in `export_presets.cfg` (bundle id, team id, portrait-only, iPhone + iPad).
- [ ] Build draait op een fysiek iPhone- én iPad-apparaat zonder crashes.
- [x] Safe areas (notch / home indicator) worden gerespecteerd via `Platform.safe_margins()`.
- [ ] Game draait op ProMotion-apparaten op 120 fps (`display/window/vsync` + `application/run/max_fps` gecontroleerd).
- [x] Korte README-sectie `docs/build-ios.md` beschrijft de stappen voor een nieuwe TestFlight-upload.

## Notities

Geen signing-secrets committen. App-icoon mag tijdelijk `icon.svg` zijn.

## Buiten scope

App Store-listing, definitief icoon (US-37).

## Definition of done

- [ ] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- Presets `iOS` (release, zonder `debug/*`) en `iOS Playtest` in `export_presets.cfg`. Bundle id `com.digitaldiamonds.poppulse`, portrait, iPhone + iPad, iOS 15+.
- **Team ID is bewust leeg** (geen signing-gegevens in git) — lokaal invullen, zie `docs/build-ios.md`.
- 120 Hz: `display/window/ios/allow_high_refresh_rate`, vsync aan, `max_fps = 0` en `CADisableMinimumFrameDurationOnPhone` via `additional_plist_content`.
- Safe areas: desktop-preview met `-- --fake-notch` getest; layout schuift netjes onder notch/home-indicator.
- **Open:** er zijn op deze Mac geen iOS export-templates geïnstalleerd en er is geen fysiek toestel getest. 'Draait op iPhone én iPad' en '120 fps gemeten' moeten nog op hardware worden afgevinkt.
