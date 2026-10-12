# Seizoensevents

Definitie: `data/events/events.json` (ingebouwd) — per event `id`, `name`, `start`/`end` (UTC-datum, inclusief), `theme` (een thema met `unlock = "event"` en `unlock_ref = <event id>`), `reward_text` en `challenges` (mode, titel, `goal`, optioneel `lower_is_better`, `overrides` op config-paden zoals bij de daily).

Werking in de game:
- Tijdens het event: cadeau-icoon in de menubalk + één toast "… IS LIVE"; het eventthema is gratis te gebruiken.
- Iedere challenge heeft een vaste seed (iedereen dezelfde run) en telt niet mee voor de gewone records.
- Alle challenges gehaald → het thema blijft voor altijd ontgrendeld.

## Bijwerken zonder app-update

1. Pas de JSON aan en **verhoog `version`**.
2. Kopieer het bestand naar `docs/events.json` en publiceer: dat is `remote_url` (`https://danielhommersom.github.io/poppulse/events.json`, GitHub Pages).
3. Bij de volgende start haalt de game hem op, valideert hem (modes bestaan, verplichte velden aanwezig), cachet hem in `user://events_cache.json` en gebruikt hem alleen als de versie nieuwer is. Bij een fout of offline: cache of ingebouwde data.

Let op: een **nieuw thema** kan niet remote worden toegevoegd (thema's zitten in de app); een remote event gebruikt dus een bestaand thema of `"theme": ""`.

## Events in deze build

| Event | Periode | Thema |
|---|---|---|
| Spooky Season | 15 okt – 3 nov 2026 | Halloween (nieuw) |
| Winter Glow | 15 dec 2026 – 7 jan 2027 | Ice |
