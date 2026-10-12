# US-28 — Premium Unlock via StoreKit

**Fase 6 — Monetization** · Afhankelijk van: US-01, US-27

## User story

Als speler wil ik met één aankoop de volledige game ontgrendelen en advertenties verwijderen, zodat ik ongestoord kan spelen.

## Relevante code / context

- Monetization-interface (US-27)

## Acceptatiecriteria

- [ ] Non-consumable product `premium_unlock` in App Store Connect, aangesloten via de iOS in-app-store plugin.
- [x] Aankoop, annuleren, fout en 'pending' (Ask to Buy) correct afgehandeld.
- [x] 'Aankopen herstellen' in settings.
- [x] Lokale prijs getoond vanuit StoreKit, nooit hardcoded.
- [ ] Getest met StoreKit sandbox-account op device.

## Definition of done

- [ ] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `platform/app_store.gd` (`AppStore`): StoreKit via de officiële `InAppStore`-plugin; Platform kiest hem automatisch als de singleton bestaat, anders de mock. Events worden elk frame gepolld.
- Afhandeling: gelukt → direct ontgrendeld; geannuleerd; fout; *Ask to Buy* / deferred → 'pending' (de latere transactie wordt alsnog verwerkt). Restore herstelt Premium én packs.
- 'RESTORE PURCHASES' in settings (en straks op het Premium-scherm, US-29).
- Prijs komt uit `localized_prices` van StoreKit; tot die binnen is wordt er geen prijs getoond.
- `ios/PopPulse.storekit`: StoreKit-configuratie om aankopen/annuleren/Ask to Buy in de simulator te testen zonder App Store Connect. Setup + testplan in `docs/storekit.md`.
- Test met een nep-plugin: `tests/test_app_store.gd` (productinfo, aankoop, annuleren, fout, pending, restore).
- **Open:** product `premium_unlock` (ID `com.digitaldiamonds.poppulse.premium`) aanmaken in App Store Connect, `InAppStore`-plugin in `ios/plugins/` zetten en testen met een sandbox-account op een toestel.
