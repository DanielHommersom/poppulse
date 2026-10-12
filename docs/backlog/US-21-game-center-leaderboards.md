# US-21 — Game Center login en leaderboards

**Fase 4 — Retentie** · Afhankelijk van: US-06, US-08

## User story

Als speler wil ik mijn scores vergelijken met vrienden en de wereld, zodat ik een extra reden heb om beter te worden.

## Relevante code / context

- `autoload/platform.gd`

## Acceptatiecriteria

- [x] `Platform.authenticate()`, `Platform.submit_score(board_id, value)`, `Platform.show_leaderboard(board_id)` — iOS-implementatie via Game Center-plugin, no-op op andere platformen.
- [x] Leaderboards: Score Mode, Reflex (laagste gemiddelde = beste), Memory, Daily Challenge.
- [x] Login stil op de achtergrond bij app-start; spel werkt volledig zonder login.
- [x] Leaderboard-knop op resultatenscherm en stats-scherm.

## Definition of done

- [ ] Alle acceptatiecriteria afgevinkt
- [ ] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `Platform.authenticate()`, `submit_score(key, value)`, `show_leaderboard(key)` + `leaderboard_id(key)`; iOS via de officiële `GameCenter`-plugin (events gepolld in `Platform._process`), elders stille no-op.
- Leaderboards: Score, Reflex (Low → High in ASC), Memory, en Daily als *recurring* bord per mode (`poppulse.daily.score/reflex/memory`), omdat punten en ms niet in één bord passen. Setup-tabel in `docs/game-center.md`.
- Stille login bij start; zonder login/plugin werkt alles. Trofee-knop op het resultaatscherm en per mode op het records-scherm.
- Runs met een rewarded 'continue' worden niet ingestuurd (voorbereid voor US-32).
- **Open:** leaderboards aanmaken in App Store Connect en testen met een sandbox-account op een toestel.

**Vervallen (5 okt 2026, keuze product owner):** geen leaderboards en geen Game Center. De integratie is uit de code verwijderd; achievements werken alleen lokaal (US-22).
