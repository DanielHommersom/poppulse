# US-03 — Instellingen: geluid, muziek en haptics

**Fase 1 — MVP valideren**

## User story

Als speler wil ik geluid en trillen aan/uit kunnen zetten, zodat ik kan spelen in de trein of in een stille ruimte.

## Relevante code / context

- `autoload/sfx.gd`
- `autoload/platform.gd` (`haptics_enabled`)
- `autoload/save_data.gd`
- `ui/hud.gd`

## Acceptatiecriteria

- [x] Tandwiel-knop in idle-scherm opent een settings-paneel in de bestaande neon-stijl (`ui/ui_style.gd`).
- [x] Toggles: Geluid, Haptics. (Muziek-slider pas als er muziek is.)
- [x] Instellingen worden opgeslagen in `SaveData` en direct toegepast bij opstarten.
- [x] Settings openen tijdens een potje is niet mogelijk (alleen vanuit IDLE/RESULTS).
- [x] Respecteert de iOS stil-schakelaar voor geluid (audio session category ambient).

## Buiten scope

Taal, accounts, restore purchases (US-28).

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- Tandwiel linksboven (alleen in IDLE en RESULTS; `main._open_settings()` weigert in andere states). Paneel = `ui/settings_panel.gd` op de nieuwe herbruikbare `Modal`-basis.
- Instellingen in `SaveData` (`get_setting/set_setting` + signal `setting_changed`); `Sfx` en `Platform` lezen ze bij opstarten en luisteren live. Autoload-volgorde: SaveData eerst.
- Stil-schakelaar: `audio/general/ios/session_category = Ambient` (+ `mix_with_others`, zodat eigen muziek van de speler doorspeelt). Op device nog even bevestigen.
- Muziek-slider bewust weggelaten: er is (nog) geen muziek.
