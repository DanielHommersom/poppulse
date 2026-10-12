# Release-checklist (App Store)

## Juridisch & privacy
- [ ] `docs/index.html` (privacy policy) online en `AppInfo.PRIVACY_URL` + ASC ▸ Privacy Policy URL wijzen ernaar.
- [ ] Privacy-URL ingevuld in App Store Connect ▸ App Privacy ▸ Privacy Policy URL. Settings ▸ Privacy ▸ PRIVACY POLICY opent dezelfde URL.
- [ ] `docs/terms/index.html` online op `AppInfo.TERMS_URL` (Settings ▸ Terms of Use); `docs/support/index.html` online als ASC ▸ Support URL.
- [ ] `AppInfo.APP_STORE_ID` invullen zodra de app in App Store Connect bestaat: dan bevatten "Tell a friend" en gedeelde resultaten de App Store-link (tot die tijd de website-link).
- [ ] Merkcheck van de naam (zie `docs/store-assets.md`).

## App Privacy-labels (ASC ▸ App Privacy)
Moet overeenkomen met de daadwerkelijk ingebouwde SDK's (AdMob + UMP, RevenueCat). Voortgang, records en achievements blijven op het toestel en tellen niet als "verzameld":

| Datatype (Apple) | Verzameld | Gekoppeld aan identiteit | Tracking | Doeleinden |
|---|---|---|---|---|
| Identifiers ▸ Device ID | ja (AdMob, alleen na ATT-toestemming) | nee | **ja** | Advertenties van derden |
| Usage Data ▸ Advertising Data | ja (AdMob) | nee | **ja** | Advertenties van derden |
| Usage Data ▸ Product Interaction | ja (AdMob) | nee | nee | Advertenties van derden |
| Purchases ▸ Purchase History | ja (RevenueCat: transactie + anoniem app-user-id) | nee | nee | App-functionaliteit |
| Diagnostics ▸ Crash / Performance | nee (geen crash-SDK) | – | – | – |
| Contact info, Locatie, Contacten, Foto's | **nee** | – | – | – |
| Identifiers ▸ User ID | twijfelgeval: RevenueCat maakt een willekeurig anoniem app-user-id. Check RevenueCat's gids *Apple App Privacy*; bij twijfel opgeven als: niet gekoppeld aan identiteit, geen tracking, App-functionaliteit | nee | nee | App-functionaliteit |

- [ ] Labels ingevuld zoals hierboven; bij een nieuwe SDK deze tabel en `ios/PrivacyInfo.xcprivacy` bijwerken.

## Privacy manifest
- [ ] Export bevat `PrivacyInfo.xcprivacy` (Godot genereert hem uit de preset: `privacy/tracking_enabled`, `privacy/tracking_domains`, `privacy/*_access_reasons`). Vergelijk met `ios/PrivacyInfo.xcprivacy` en vervang hem in Xcode als iets ontbreekt.
- [ ] Google Mobile Ads / UMP-frameworks hebben hun eigen manifest (ingebouwd sinds GMA 11).
- [ ] Xcode ▸ Product ▸ Archive ▸ *Generate Privacy Report* doorlopen: geen waarschuwingen.

## Leeftijd & categorie
- [ ] Leeftijdsclassificatie-vragenlijst: geen geweld/gokken/etc.; *Unrestricted Web Access* nee; *Contests* nee → **12+** kiezen (advertenties van derden kunnen niet-kindgericht zijn).
- [ ] **Niet** in de Kids-categorie indienen; primaire categorie Games ▸ Casual, secundair Games ▸ Puzzle.
- [ ] AdMob: *tag for child-directed treatment* uit; maximum ad content rating **T** (teen).

## Aankopen (RevenueCat)

- [ ] RevenueCat-project + iOS-app, .p8 In-App Purchase Key geüpload, product geïmporteerd, entitlement `premium`.
- [ ] `revenuecat.ios_api_key` (`appl_…`) ingevuld in `data/products.json`.
- [ ] ASC: non-consumable `com.digitaldiamonds.poppulse.premium` (€3,99, Family Sharing aan) + Paid Apps Agreement getekend.
- [ ] Sandbox-test: kopen → ontgrendeld; app verwijderen → herinstalleren → Premium automatisch terug.

## Advertenties & tracking
- [ ] Echte AdMob app-id in `GADApplicationIdentifier` en echte unit-id's in `data/ads.json` (`release`).
- [ ] `NSUserTrackingUsageDescription` aanwezig (preset) en begrijpelijk.
- [ ] UMP-berichten gepubliceerd in AdMob ▸ Privacy & messaging (GDPR + US states). IDFA explainer **niet** publiceren: wij tonen ATT zelf ná consent.
- [ ] Getest: EER-toestel → consent-formulier na 1e potje → ATT → ads; weigeren → niet-gepersonaliseerd.

## In-app aankopen
- [ ] Alle producten uit `docs/storekit.md` *Ready to Submit*, met review-screenshot.
- [ ] Restore-knop aanwezig (Settings + Premium-scherm). Sandbox-test gedaan.

## Build
- [ ] `application/version` opgehoogd; release-preset `iOS` (zonder debug-tools).
- [ ] App-icoon, launch screen, screenshots 6,9" + 13" en app preview uit `store/` geüpload.
- [ ] Testflight-ronde zonder crashes.
- [ ] Export compliance: `ITSAppUsesNonExemptEncryption = false` (in de preset).
- [ ] Review-notitie: "Geen account nodig. Premium is een eenmalige non-consumable; advertenties alleen in de gratis versie."
