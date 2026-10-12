# US-35 — Performance- en batterijpass

**Fase 7 — Launch-ready** · Afhankelijk van: US-01

## User story

Als speler wil ik dat de game altijd vloeiend draait en mijn batterij niet leegtrekt.

## Relevante code / context

- `core/effects.gd` (maakt per burst nieuwe CPUParticles2D)
- `shaders/`

## Acceptatiecriteria

- [x] Particles, rings en float-text gebruiken object pooling i.p.v. nodes per event aanmaken.
- [ ] Stabiele 120 fps op een iPhone met ProMotion en 60 fps op een oudere iPhone (bv. iPhone 11) tijdens combo's van 50+.
- [x] In menu/idle zonder interactie: framerate omlaag (bv. 30 fps) om batterij te sparen.
- [x] Geen geheugengroei na 20 potjes achter elkaar (gemeten met de Godot profiler).

## Definition of done

- [ ] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `core/effects.gd`: vaste pools (24 particle-bursts, 32 ringen, 24 float-teksten) die rond-robin hergebruikt worden; per hit worden geen nodes meer aangemaakt of vrijgegeven.
- Batterij: in IDLE / RESULTS / PAUSED zakt `Engine.max_fps` na 6 s zonder aanraking naar 30; de eerste touch zet hem terug op 0 (= display-rate, 120 Hz op ProMotion). Tijdens countdown/spel altijd volle framerate.
- Geheugen: scenario `s_perf` speelt 20 Score-runs met een combo-bot (4× versneld) en meet via `Performance`-monitors: nodes 388 → 388, objecten 2823 → 2823, orphan-nodes 0, statisch geheugen 126,91 → 126,98 MB (ruis). Op de Mac min. 117 fps tijdens spel.
- **Open:** 120 fps op een ProMotion-iPhone en 60 fps op een iPhone 11 bij 50+ combo's meten op echte toestellen (Xcode ▸ Debug Navigator of de FPS-teller in de debug-overlay).
