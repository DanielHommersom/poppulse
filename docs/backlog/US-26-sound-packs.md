# US-26 — Geluidspakketten

**Fase 5 — Themes & cosmetics** · Afhankelijk van: US-23

## User story

Als speler wil ik een ander pop-geluid kunnen kiezen, zodat de feedback blijft verrassen.

## Relevante code / context

- `autoload/sfx.gd` (toonladder, `play_pop`)

## Acceptatiecriteria

- [x] Sound pack = set samples of synth-parameters per categorie (pop, miss, tick, go, expire).
- [x] Minimaal 3 packs: Classic, Bubble wrap, Arcade 8-bit.
- [x] Combo-toonladder werkt in ieder pack.
- [x] Pack kiesbaar in settings of gekoppeld aan thema (instelbaar).

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `data/sound_packs.json`: per pack synth-parameters voor `pop` (type bloop / snap / chip / bell + toonhoogte), `miss`, `expire`, `tick`, `go` (golfvorm sine/square/pulse/noise, sweep, optioneel arpeggio).
- Packs: **Classic** (exact het oude geluid), **Bubble Wrap** (ruis-krak + korte plop), **Arcade 8-bit** (pulse-blip met octaafsprong, bit-crush), plus **Cosmic** (bel, onderdeel van het Galaxy-pack, US-30).
- Combo-toonladder: ieder pack synthetiseert één pop per noot van de pentatonische ladder, dus combo's klimmen in elk pack. Packs worden één keer gegenereerd en gecachet.
- Instelbaar: settings ▸ SOUND PACK ('Match theme' aan = pack volgt het thema, bv. Retro → Arcade; uit = vrije keuze), of via tab SOUNDS in het style-sheet (met hoorbare preview).
