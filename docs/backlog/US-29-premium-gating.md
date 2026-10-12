# US-29 — Premium-content en upsell-momenten

**Fase 6 — Monetization** · Afhankelijk van: US-27, US-28

## User story

Als speler wil ik precies weten wat Premium oplevert en het op een logisch moment aangeboden krijgen, zonder dat het spel me ermee lastigvalt.

## Relevante code / context

- Monetization-interface (US-27)
- Stage-select (US-14)
- Reflex-geschiedenis (US-11)
- Themes (US-24)

## Acceptatiecriteria

- [x] Premium ontgrendelt: Stage-levels 13+, uitgebreide Reflex-stats/grafiek, 3 premium themes, geen advertenties.
- [x] Premium-scherm met heldere opsomming + prijs + restore.
- [x] Upsell alleen na: nieuw persoonlijk record, uitspelen level 12, tik op een gelockt item. Nooit bij app-start, nooit midden in een potje.
- [x] Maximaal één onaangevraagde upsell per sessie.
- [x] Na aankoop direct alles ontgrendeld zonder herstart.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `core/premium.gd`: Premium gate't Stage-levels 13–30 (kroontjes in de level-select), de Reflex-grafiek + trend (resultaat én records-scherm tonen een teaser-knop), de 3 premium-thema's (Candy, Retro LCD, Aurora) en alle ads (`Platform.ads_disabled()`).
- `ui/premium_panel.gd`: opsomming uit `products.json`, echte store-prijs (koopknop uit zolang er geen prijs is), 'One-time purchase', bundel 'Everything', RESTORE PURCHASES, meldingen voor pending/fout. Ook bereikbaar via het kroon-icoon in de menubalk.
- Onaangevraagde upsell alleen na een verbroken record (niet bij de allereerste run) of na het uitspelen van level 12, op het resultaatscherm, max. één keer per sessie, nooit voor Premium-bezitters. Tik op een gelockt item = gevraagd → altijd toegestaan. Nooit bij app-start of in een run.
- Na aankoop: `entitlements_changed` ververst direct resultaat, menu, level-select, records en style-sheet — geen herstart.
- Getest met mock-store (scenario `s_premium`).
