# US-40 — Pass-and-play multiplayer

**Fase 8 — Na launch** · Afhankelijk van: US-06, US-17

## User story

Als speler wil ik met vrienden op één toestel om de beurt dezelfde challenge spelen en scores vergelijken.

## Relevante code / context

- ModeRegistry (US-06)
- Daily-seed logica (US-17)

## Acceptatiecriteria

- [x] 2–4 spelers, namen invoeren (optioneel).
- [x] Iedere speler krijgt exact dezelfde seed/challenge.
- [x] 'Geef door aan [naam]'-scherm tussen beurten.
- [x] Eindscherm met ranglijst en winnaar-animatie.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- Vijfde kaart **PASS & PLAY** in de rij met mode-kaarten (zelfde opmaak; selecteren + PLAY opent de setup, met de laatst gespeelde mode voorgeselecteerd) (`ui/party_panels.gd`): kies Score / Reflex / Memory, 2–4 spelers, namen optioneel (leeg = 'Player n').
- Iedereen krijgt exact dezelfde challenge: één seed per sessie via `context.seed` (zelfde `GameMode.rng`-mechanisme als de daily). Getest: de eerste targets zijn voor alle spelers identiek.
- Tussen beurten een volledig 'PASS TO <naam>'-scherm met de vorige uitslag; pas na 'I'M READY' start de countdown (geen X, zodat niemand vastloopt).
- Eindscherm: ranglijst (Reflex: laagste tijd wint), 'NAME WINS!' met vallende/wiebelende kroon, goud-bursts, geluid en haptic; PLAY AGAIN (zelfde spelers, nieuwe seed) of DONE.
- Party-runs tellen niet mee voor records, daily of leaderboards. Stoppen via pauze beëindigt de sessie.
- Bijkomend: `Modal.is_open()` is nu false zodra het sluiten begint (voorkomt dat een fade-out de volgende actie blokkeert).
