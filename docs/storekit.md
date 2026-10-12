# In-app aankopen (RevenueCat)

Gameplay en UI kennen alleen `Platform` (`is_entitled`, `purchase`, `restore_purchases`, `get_price`). Op het toestel gebruikt `Platform` `platform/revenuecat_store.gd` bovenop de **Godotx RevenueCat**-plugin (singleton `GodotxRevenueCat`, `addons/godotx_revenue_cat` + `ios/plugins/revenue_cat`). RevenueCat praat met StoreKit, valideert de bon en meldt of de entitlement `premium` actief is; dat wordt bij elke start stil gecontroleerd (herinstallatie, nieuwe telefoon, Family Sharing).

Fallbacks: debug of desktop → `platform/mock_store.gd`. Een **release-build** zonder plugin of API-key krijgt `platform/unavailable_store.gd`: kopen geeft een fout. Premium kan dus nooit gratis worden (getest in `tests/test_revenuecat.gd`).

## RevenueCat (eenmalig)

1. app.revenuecat.com → project *Pop Pulse* → app *App Store*, bundle id `com.digitaldiamonds.poppulse`.
2. In-App Purchase Key: ASC ▸ Users and Access ▸ Integrations ▸ In-App Purchase → key (.p8) maken en uploaden bij RevenueCat, met Issuer ID en Key ID.
3. Products: `com.digitaldiamonds.poppulse.premium` importeren.
4. Entitlements: `premium` aanmaken en het product eraan koppelen (moet gelijk zijn aan `rc_entitlement` in `data/products.json`).
5. Offerings: `default` met dit product (niet strikt nodig, de game koopt op product-id).
6. API keys: de **public** iOS SDK key (`appl_…`) in `data/products.json` → `revenuecat.ios_api_key`. Deze key is publiek bedoeld en mag in de app; de secret key nooit.

## App Store Connect

Maak deze **non-consumable** aan (Premium is de enige aankoop) (Features ▸ In-App Purchases). Prijzen staan alléén in App Store Connect; de game toont de gelokaliseerde prijs die StoreKit teruggeeft en nooit een hardcoded bedrag.

| `products.json` id | Product ID (ASC) | Ontgrendelt |
|---|---|---|
| `premium_unlock` | `com.digitaldiamonds.poppulse.premium` | levels 13–30, volledige Reflex-stats, 5 premium thema's (incl. Galaxy en Ocean), Gem- en Pearl-bubbles, Cosmic- en Deep Sea-geluid, geen ads |

Zet *Family Sharing* aan; vul review-screenshot en -notitie in.

## Afhandeling

| Situatie | Wat de speler ziet |
|---|---|
| Gelukt | Direct ontgrendeld (geen herstart); `purchase_completed` + `entitlements_changed`. |
| Geannuleerd | Niets, sheet blijft open. |
| Fout | 'Purchase failed — try again later'. |
| Pending (Ask to Buy) | 'Waiting for approval' — zodra de ouder akkoord geeft komt de transactie later binnen en wordt hij alsnog verwerkt. |
| Herstellen | Settings ▸ PURCHASES ▸ RESTORE PURCHASES (en op het Premium-scherm). Herstelt Premium. |

## Testen zonder App Store Connect

`ios/PopPulse.storekit` is een StoreKit-configuratie met dezelfde producten. In Xcode: *Product ▸ Scheme ▸ Edit Scheme ▸ Run ▸ Options ▸ StoreKit Configuration* → `PopPulse.storekit`. Daarmee werken aankopen, annuleren, *Ask to Buy* en fouten (Editor ▸ Enable Ask to Buy / Fail Transactions) in de simulator.

## Sandbox op een toestel

1. ASC ▸ Users and Access ▸ Sandbox Testers: tester aanmaken.
2. Op het toestel: Instellingen ▸ App Store ▸ Sandbox-account.
3. Koop Premium, verwijder de app, installeer opnieuw, *Restore Purchases* → Premium terug.
