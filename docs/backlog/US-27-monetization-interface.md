# US-27 — Monetization-interface met mock-implementatie

**Fase 6 — Monetization** · Afhankelijk van: US-08

## User story

Als ontwikkelaar wil ik aankopen en advertenties achter één interface in de platformlaag, zodat gameplay- en UI-code onafhankelijk zijn van StoreKit/AdMob en ik alles kan testen zonder echte SDK.

## Relevante code / context

- `autoload/platform.gd`

## Acceptatiecriteria

- [x] API: `is_entitled(product_id)`, `purchase(product_id)`, `restore_purchases()`, `get_price(product_id)`, `can_show_rewarded(placement)`, `show_rewarded(placement) -> bool`, `maybe_show_interstitial(placement)`.
- [x] Signals: `purchase_completed`, `purchase_failed`, `entitlements_changed`.
- [x] Mock-backend (desktop/debug) met toggles: aankoop slaagt/faalt, ad beschikbaar/niet.
- [x] Producten gedefinieerd in `data/products.json` (id, type, wat het ontgrendelt).
- [x] Entitlements worden lokaal gecachet in SaveData.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `Platform`: `is_entitled`, `purchase`, `restore_purchases`, `get_price`, `can_show_rewarded`, `show_rewarded` (await → bool, alleen true bij volledig bekeken), `maybe_show_interstitial` (await → bool). Signals `purchase_completed`, `purchase_failed` (reason cancelled/error/pending), `entitlements_changed`, `restore_completed`.
- Backends achter interfaces in `platform/`: `StoreBackend` + `MockStore`, `AdsBackend` + `MockAds` (nep-advertentie full screen). Echte backends volgen in US-28/31.
- Mock-toggles in de debug-overlay (F2): aankoop slaagt / faalt / annuleert / pending, ad-fill aan/uit, ad overslaan, entitlements resetten.
- `data/products.json`: id, `store_id`, type, `grants` (wat het ontgrendelt), `unlocks` (tekst), `mock_price` (alleen mock). Bundel `bundle_all` grant alles.
- Entitlements gecachet in `SaveData.unlocks.entitlements` (werkt offline). Premium-spelers zien nooit ads; rewarded-voordelen krijgen ze zonder ad.
- Tests: `tests/test_monetization.gd` (producten, aankoop + bundel, faalredenen, restore, rewarded voltooid/overgeslagen/geen fill, premium).
