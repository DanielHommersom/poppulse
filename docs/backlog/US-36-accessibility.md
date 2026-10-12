# US-36 — Toegankelijkheid

**Fase 7 — Launch-ready** · Afhankelijk van: US-23

## User story

Als speler met kleurenblindheid of gevoeligheid voor beweging wil ik de game comfortabel kunnen spelen.

## Relevante code / context

- `main.gd` (`_shake`)
- Theme-systeem (US-23)

## Acceptatiecriteria

- [x] Optie 'Minder beweging': geen screenshake, minder flitsen.
- [x] Kleurenblind-vriendelijk thema of symbolen op bubbles waar kleur betekenis heeft.
- [x] Volgt iOS 'Reduce Motion' standaard.
- [x] Tekst in HUD voldoet aan minimale contrastwaarde.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- Settings ▸ ACCESSIBILITY: **Reduce motion** (Like iOS / On / Off; default volgt iOS Reduce Motion via `PopPulseNative.system_reduce_motion`, desktop-test met `-- --reduce-motion`). Uit: geen screenshake, zachtere pop/fail-flitsen, 60 % minder particles, rustigere idle-shimmer, banners zonder zoom, geen 'punch'-schaling.
- **Symbols on lit bubbles**: oplichtende targets krijgen een witte ring + stip, zodat 'oplichten' niet alleen van kleur/helderheid afhangt (decoys hadden al een kruis; Memory gebruikt positie + toon).
- Nieuw gratis thema **Contrast**: Okabe-Ito-kleurenblind-veilig palet, puur zwart, sterke randen.
- Contrast: alle tekst gaat via `UiStyle` met een minimale tekst-alpha (0,55). `tests/test_contrast.gd` checkt per thema alle tekstkleuren op panelen én achtergrond en knopteksten: overal ≥ 4,5:1 (WCAG AA).
- Instellingen: `core/access.gd`.
