# US-08 — SaveData uitbreiden: schema, stats en voortgang

**Fase 2 — Fundament voor meerdere modes**

## User story

Als speler wil ik dat al mijn records, statistieken en voortgang bewaard blijven, ook na een update van de app.

## Relevante code / context

- `autoload/save_data.gd`

## Acceptatiecriteria

- [x] Save-bestand heeft een `version`-veld en een migratie-functie (v1 → v2 behoudt bestaande highscores).
- [x] Per mode: best, aantal potjes, totale speeltijd, laatste N scores.
- [x] Secties voor: settings, stage-voortgang, unlocks/entitlements, daily/streak.
- [x] Schrijven is atomair (eerst temp-bestand, dan rename) zodat een crash de save niet corrupt maakt.
- [x] Unit-achtige testscène of script dat migratie en load/save controleert.

## Notities

Geen gevoelige data opslaan. Cloud sync komt later (US-39) en moet deze structuur kunnen wrappen.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- Opslag is nu `user://save.json` (schema `version: 2`). Structuur + migratie in `core/save_store.gd` (los testbaar), de autoload `SaveData` is de enige toegang.
- Migratie: de oude `user://save.cfg` (v1: `[best]`, `[settings]`) wordt bij eerste start overgezet; het oude bestand blijft staan als extra vangnet. Ontbrekende secties worden altijd aangevuld, onbekende sleutels blijven bewaard.
- Per mode: `best`, `played`, `time_played`, `total`, `recent` (laatste 20), `best_at`. Secties: `settings`, `stage`, `unlocks` (entitlements, themes, designs, sound_packs, trials), `daily`, `flags`, `achievements`, `cosmetics`, `stats`.
- Atomisch: schrijven naar `.tmp` → vorige versie naar `.bak` → rename. Bij een corrupt/ontbrekend hoofdbestand wordt `.bak` geladen. Schrijven wordt per frame gebundeld (`mark_dirty()`) en geforceerd bij app-pauze/afsluiten.
- Tests: `tests/test_save_data.gd` (migratie, round-trip, stats/recent, corrupte save → backup, toekomstige velden). Draaien: `Godot --headless --path . res://tests/run_tests.tscn -- --test-save`.
- `--test-save` (+ `--fresh`) laat dev-scenario's en tests een aparte save gebruiken.
