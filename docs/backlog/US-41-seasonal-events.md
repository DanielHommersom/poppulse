# US-41 — Seizoensgebonden content

**Fase 8 — Na launch** · Afhankelijk van: US-17, US-23

## User story

Als speler wil ik af en toe tijdelijke themes en challenges, zodat de game fris blijft.

## Relevante code / context

- Theme-systeem (US-23)
- Daily (US-17)

## Acceptatiecriteria

- [x] Event-definitie in data: begin/einddatum, thema, speciale challenge-set.
- [x] Event-content kan via een remote JSON (CDN) worden bijgewerkt zonder app-update; fallback op ingebouwde data.
- [x] Eerste event: Halloween of winter.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- Event-definitie in `data/events/events.json`: begin/einddatum, thema, beloningstekst en een set speciale challenges (mode + overrides + doel). Autoload `Events` (actief event, dagen over, voortgang, beloning).
- Remote: `remote_url` wordt bij start op de achtergrond opgehaald, gevalideerd, gecachet en alleen gebruikt bij een hogere `version`; anders cache of ingebouwde data (`tests/test_events.gd`: kapotte JSON, ongeldig schema, oudere versie, nieuwere versie). Uitleg in `docs/events.md`.
- Eerste event: **Spooky Season** (Halloween, 15 okt – 3 nov 2026) met nieuw Halloween-thema en 4 challenges; plus een Winter-event (15 dec – 7 jan) met het Ice-thema.
- In de game: cadeau-icoon in de menubalk tijdens een event, eenmalige 'IS LIVE'-toast, eventpaneel met doelen en beste resultaten; eventthema gratis tijdens het event en permanent na het halen van alle challenges.
- **Open:** het JSON-bestand op de CDN-URL zetten (ik heb niets gepubliceerd).
