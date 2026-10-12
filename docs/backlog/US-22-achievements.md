# US-22 — Achievements

**Fase 4 — Retentie** · Afhankelijk van: US-21

## User story

Als speler wil ik achievements verdienen, zodat ik kleine doelen heb naast het verbeteren van mijn score.

## Relevante code / context

- `autoload/platform.gd`
- SaveData (US-08)

## Acceptatiecriteria

- [x] 15–20 achievements gedefinieerd in `data/achievements.json` (bv. combo 50, reactie < 200 ms, 30 levels 3 sterren, 7-daagse streak).
- [x] Lokale tracking + doorsturen naar Game Center via `Platform.report_achievement(id, percent)`.
- [x] In-game toast in de neon-stijl bij unlock.
- [x] Achievements blijven lokaal werken zonder Game Center.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- 19 achievements in `data/achievements.json` (o.a. combo 25/50, reflex-gemiddelde < 250 ms, losse tik < 200 ms, alle 30 levels gehaald / 3 sterren, streak 7/30, 500 fidget-pops, flawless run). Per stuk: `stat`, `goal`, optioneel `compare: lte`, `gc_id`.
- Autoload `Achievements`: voortgang wordt grotendeels afgeleid uit wat al in de save staat (records, sterren, streaks) + een paar eigen tellers. Unlocks in `SaveData.achievements`.
- `Platform.report_achievement(gc_id, percent)` spiegelt alleen toenames naar Game Center; bij (her)aanmelden wordt alles opnieuw gesynct. Het systeem-banner staat uit omdat we een eigen neon-toast tonen (`ui/toast.gd`, met wachtrij).
- Overzicht met voortgang onderaan het records-scherm.
- Werkt volledig zonder Game Center. Game Center-kant: zie het open device-punt van US-21.
- Bijkomend: `SaveData` bundelt schrijfacties nu tot max. één atomische save per 0,5 s (geforceerd bij pauze/afsluiten).

**Update 5 okt 2026:** achievements worden alleen lokaal op het toestel opgeslagen; de koppeling met Game Center is verwijderd.
