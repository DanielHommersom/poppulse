# US-30 — Losse cosmetische packs

**Fase 6 — Monetization** · Afhankelijk van: US-28

## User story

Als speler wil ik een los thema of bubble-pack kunnen kopen, zodat ik mijn favoriete look heb zonder alles te kopen.

## Relevante code / context

- Monetization-interface (US-27)
- Themes (US-24)
- Bubble-designs (US-25)

## Acceptatiecriteria

- [x] 2–3 non-consumable packs (bv. 'Galaxy pack': thema + bubble-design + sound pack).
- [x] Preview vóór aankoop (live op het board).
- [x] Bundel 'Alles' als het Premium + alle packs omvat; prijslogica in `data/products.json`.
- [x] Restore herstelt ook packs.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- Twee packs als non-consumables in `data/products.json` (veld `pack`: thema + bubble-design + sound pack): **Galaxy** (Galaxy-thema, Gem-bubbles, Cosmic-geluid) en **Ocean** (nieuw Ocean-thema, nieuwe Pearl-druppelvorm, nieuw Deep Sea-geluid).
- Winkel = tab PACKS in het style-sheet (ook direct geopend als je een pack-item probeert te gebruiken): tikken = live preview van thema + bubbles op het board én de geluiden; daarna BUY met de store-prijs, of USE PACK als je hem bezit.
- Bundel **Everything** (`bundle_all`): `bundle_of` + `grants` in `products.json` = Premium + alle packs (ook toekomstige: nieuwe packs toevoegen aan de lijst).
- Restore herstelt packs ook (getest met de mock: `s_packs`). Echte StoreKit-test: zie het open punt bij US-28.

**Vervallen (5 okt 2026, keuze product owner):** er is maar één aankoop, Premium. De inhoud van de packs (Galaxy- en Ocean-thema, Gem- en Pearl-bubbles, Cosmic- en Deep Sea-geluid) zit nu in Premium; de PACKS-tab en de bundel zijn verwijderd.
