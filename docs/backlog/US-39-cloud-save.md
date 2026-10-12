# US-39 — Cloud save via iCloud

**Fase 8 — Na launch** · Afhankelijk van: US-08

## User story

Als speler wil ik mijn voortgang behouden als ik een nieuwe telefoon neem of op mijn iPad speel.

## Relevante code / context

- SaveData (US-08)
- `autoload/platform.gd`

## Acceptatiecriteria

- [ ] `Platform.cloud_load()/cloud_save()` via iCloud key-value of CloudKit-plugin.
- [x] Merge-strategie: hoogste records en meeste voortgang winnen per veld (geen 'last write wins' voor alles).
- [x] Werkt offline; synchroniseert bij volgende start.

## Definition of done

- [ ] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `Platform.cloud_load()` / `cloud_save(data, force)` via de iCloud key-value store van de officiële `ICloud`-plugin (hele save onder één sleutel; push max. 1× per 30 s, geforceerd bij app-pauze/afsluiten). Op desktop te testen met `-- --mock-cloud` (bestand `user://cloud_mock.json`).
- Merge (`core/save_merge.gd`), per veld: hoogste score / laagste reflex-tijd / snelste tik, meeste runs voor de tellers, beste sterren en tijd per level, aankopen en unlocks samengevoegd, beste daily-uitslag per dag, streak van het laatst gespeelde toestel, vroegste achievement-unlock, instellingen van dit toestel. Geen 'last write wins'.
- Offline: alles blijft lokaal werken; bij de volgende start (en bij een melding dat een ander toestel iets pushte) wordt gemerged en teruggeschreven.
- Tests: `tests/test_save_merge.gd`; scenario `s_cloud` (remote record komt binnen en wordt teruggepusht).
- **Open:** iCloud-capability (key-value storage) aan de App ID toevoegen, `ICloud`-plugin in `ios/plugins/` zetten en testen met twee toestellen op hetzelfde Apple-ID.

## Vervallen (8 oktober 2026)

Keuze product owner: voortgang wordt alleen op het toestel opgeslagen. De iCloud-code (`Platform.cloud_*`, `SaveData.cloud_sync`, `SaveMerge`) is verwijderd. Premium blijft wel herstelbaar via de App Store (Restore Purchases / RevenueCat).
