# US-10 — Reflex Mode

**Fase 3 — Game modes** · Afhankelijk van: US-06, US-08

## User story

Als speler wil ik mijn pure reactietijd meten en verbeteren, zodat ik kan zien hoe snel ik ben en mijn persoonlijke record kan breken.

## Relevante code / context

- `modes/game_mode.gd`
- `core/bubble.gd` (`light_up`)
- ModeRegistry (US-06)

## Acceptatiecriteria

- [x] Een ronde = 10 prikkels. Steeds één bubble licht op na een willekeurige wachttijd (1,0–3,0 s, configureerbaar in `data/reflex_mode.json`).
- [x] Reactietijd gemeten vanaf het frame waarop de bubble zichtbaar oplicht tot de touch-down (input-timestamp, niet frame-tijd).
- [x] Te vroeg tikken (vóór oplichten) = 'TE VROEG' feedback, prikkel telt opnieuw.
- [x] Verkeerde bubble = fout, geen tijd geregistreerd.
- [x] Per prikkel zichtbaar: '247 ms'. Bij beste tijd ooit: 'PERSONAL BEST' banner + extra effect.
- [x] Resultaat: gemiddelde, beste, slechtste; gemiddelde is de score voor het record (lager = beter).
- [x] Geen timer of combo in de HUD (via hooks uit US-06).

## Notities

Let op input-latency: gebruik `_input` en de event-timestamp waar mogelijk; documenteer de meetmethode.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `modes/reflex_mode.gd` + `data/reflex_mode.json` (`stimuli`, `wait_min`, `wait_max`, `timeout`, board 4×5), geregistreerd in `ModeRegistry`.
- Meetmethode gedocumenteerd in `docs/reflex-timing.md`: start = `frame_post_draw` van het eerste volledig-oplichtende frame, einde = event-afhandeling van de touch-down (`Board.last_press_usec`). Godot 4.7 heeft geen hardware-tijdstempel op input-events.
- Teksten in de game zijn Engels zoals de rest van de UI: 'TOO EARLY' (= 'TE VROEG'), 'PERSONAL BEST'.
- Te vroeg = prikkel herstart; verkeerde bubble of time-out = fout zonder tijd (telt als prikkel). Pauze tijdens een oplichtende bubble herstart de prikkel.
- 'PERSONAL BEST' + gouden ringen/burst/shake bij de snelste losse reactie ooit (`best_single` in de save); de allereerste meting ooit telt niet als PB.
- Record = gemiddelde (lager = beter via `lower_is_better()`). Resultaat: gemiddelde, beste, slechtste, fouten.
- Nieuwe generieke mode-signals: `announce`, `progress`, `reaction`; `GameMode.context` levert records aan zonder dat modes de save lezen.
