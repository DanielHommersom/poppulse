# US-38 — Privacy, leeftijdsclassificatie en App Store-compliance

**Fase 7 — Launch-ready** · Afhankelijk van: US-31, US-34

## User story

Als ontwikkelaar wil ik dat de app in één keer door de App Store-review gaat en voldoet aan de AVG.

## Relevante code / context

- Ads (US-31)
- Analytics (US-34)

## Acceptatiecriteria

- [ ] Privacyverklaring online (Digital Diamonds-domein) en gelinkt in settings en App Store Connect.
- [x] App Privacy-labels kloppen met de daadwerkelijk gebruikte SDK's.
- [x] Leeftijdsclassificatie 12+ en de app is niet ingediend in de Kids-categorie.
- [x] Privacy manifest (PrivacyInfo.xcprivacy) aanwezig voor app en SDK's.
- [x] Checklist `docs/release-checklist.md`.

## Definition of done

- [ ] Alle acceptatiecriteria afgevinkt
- [ ] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- Privacy policy klaar om te publiceren: `docs/index.html` (EN; AVG-grondslagen, AdMob/UMP, ATT, RevenueCat, events-bestand, 12+, rechten). Terms: `docs/terms/`, support: `docs/support/`. Gelinkt in Settings ▸ PRIVACY ▸ PRIVACY POLICY via `Platform.PRIVACY_URL`.
- App Privacy-labels: tabel in `docs/release-checklist.md`, afgeleid van de daadwerkelijk ingebouwde SDK's.
- Leeftijd 12+ en níet Kids-categorie vastgelegd in de checklist (incl. AdMob max. rating T).
- Privacy manifest: preset genereert hem (tracking aan + Google-trackingdomeinen, required-reason-API's); gecontroleerde referentie `ios/PrivacyInfo.xcprivacy` (`plutil -lint` OK). SDK's leveren hun eigen manifest.
- `docs/release-checklist.md` aangemaakt.
- **Open:** KvK/adres/e-mail invullen, de pagina online zetten op het Digital Diamonds-domein (ik heb niets gepubliceerd) en de URL + labels in App Store Connect invullen.
