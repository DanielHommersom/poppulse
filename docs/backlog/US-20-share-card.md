# US-20 — Deelbare resultaatkaart

**Fase 4 — Retentie** · Afhankelijk van: US-01

## User story

Als speler wil ik mijn score of reactietijd als mooie afbeelding delen, zodat ik vrienden kan uitdagen.

## Relevante code / context

- Resultaatscherm (`ui/hud.gd` `show_results`)
- `tools/capture.gd` (bestaande screenshot-logica)

## Acceptatiecriteria

- [x] Knop 'Deel' op het resultatenscherm.
- [x] Genereert een 1080×1350 afbeelding (offscreen SubViewport): mode, score/ms, record-badge, game-naam, neon-stijl.
- [ ] Opent de native iOS share sheet via `Platform.share_image(image, text)` (iOS-plugin achter de platformlaag).
- [x] Tekst bevat een uitdaging ('Kun jij sneller dan 198 ms?') en later een App Store-link.

## Notities

Godot heeft geen ingebouwde share sheet; gebruik een bestaande iOS share-plugin of een kleine eigen plugin.

## Definition of done

- [ ] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- Deel-knop (share-icoon) onder iedere resultaatkaart.
- `ui/share_card.gd` rendert offscreen in een SubViewport een 1080×1350 PNG: POP IT, mode, resultaat (score / ms / level + sterren), 'NEW PERSONAL BEST'-badge, gloeiende bubbles, uitdaging onderaan.
- `Platform.share_image(image, text)`: slaat op in `user://share/` en roept de eigen iOS-plugin `PopPulseNative.share_image` aan (UIActivityViewController, met popover-anker voor iPad). Desktop: PNG wordt getoond in Finder en de tekst gaat naar het klembord.
- Tekst: 'Can you beat 198 ms? #PopPulse' (per mode een eigen uitdaging). `Platform.APP_STORE_URL` wordt automatisch toegevoegd zodra je hem invult.
- **Open:** de share sheet zelf is nog niet op een toestel getest (plugin moet nog gecompileerd worden, zie `ios/plugins/README.md`).

- 8 oktober 2026: PopPulseNative gebouwd (`tools/build_poppulse_native.sh`) en aangezet in beide iOS-presets; export slaagt en linkt. Wacht nog op test op een toestel.

- 12 oktober 2026: getest op iPhone door product owner — akkoord.
