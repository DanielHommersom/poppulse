# US-23 — Theme-systeem

**Fase 5 — Themes & cosmetics** · Afhankelijk van: US-08

## User story

Als ontwikkelaar wil ik het uiterlijk (kleuren, achtergrond, bubble-look, geluid) als data-bestand kunnen wisselen, zodat themes toevoegen geen codewerk is.

## Relevante code / context

- `shaders/bubble.gdshader`
- `shaders/background.gdshader`
- `core/board.gd` (rainbow hue per rij)
- `ui/hud.gd` (kleurconstanten)
- `autoload/sfx.gd`

## Acceptatiecriteria

- [x] `ThemeData` Resource (.tres): bubble-palet, shader-parameters, achtergrond-shaderparameters, HUD-accentkleuren, sfx-pack id.
- [x] Hardcoded kleuren in `hud.gd` en `board.gd` vervangen door waarden uit het actieve thema.
- [x] `ThemeManager` autoload: `apply(theme_id)`, signal `theme_changed`; wisselen kan live in het menu.
- [x] Huidige look is het default thema 'Neon' en ziet er identiek uit.

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `core/theme_data.gd` (`ThemeData` Resource): bubble-palet (`hue_rows` of vaste `palette`), `bubble_params` (uniforms in `bubble.gdshader`: `dim_mix`, `hot_add`, `rim_*`, `spec_*`, `glow_*`), achtergrond (`bg_top/bottom/accent/grid/vignette`), board-plaat, UI-kleuren, `sfx_pack`, en unlock-status voor US-24+.
- Thema-bestanden in `res://themes/*.tres`; default `themes/neon.tres`.
- Autoload `ThemeManager`: `apply(id, persist)`, `revert_preview()`, signal `theme_changed`. Zet de `UiStyle`-palette (nu `static var` i.p.v. `const`); board, achtergrond, HUD, resultaatkaart en alle modals luisteren en kleuren live om zonder herbouw.
- Hardcoded kleuren in `hud.gd` (eigen consts verwijderd) en `board.gd` (plaat + regenboog) komen nu uit het actieve thema.
- Identiek: pixel-vergelijking van het idle-scherm en het records-scherm vóór/na de refactor geeft 0 afwijkende pixels (scenario `s_look`).
