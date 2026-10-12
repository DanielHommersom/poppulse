# US-02 — Haptics op iOS verifiëren en verfijnen

**Fase 1 — MVP valideren** · Afhankelijk van: US-01

## User story

Als speler wil ik bij iedere pop een korte, strakke tik voelen, zodat het spel aanvoelt als een fysieke fidget toy.

## Relevante code / context

- `autoload/platform.gd` (`haptic()`)
- `main.gd` (aanroepen per event)

## Acceptatiecriteria

- [ ] Op device getest: LIGHT / MEDIUM / HEAVY / ERROR voelen duidelijk verschillend.
- [x] Als `Input.vibrate_handheld` op iOS te grof/traag is: Core Haptics (UIImpactFeedbackGenerator / CHHapticEngine) via een iOS-plugin, achter dezelfde `Platform.haptic()`-API.
- [x] Gameplay-code roept nooit direct een iOS-API aan; alleen `Platform.haptic()`.
- [x] Snelle opeenvolgende pops (>10/s) veroorzaken geen haptic-achterstand of lag.

## Definition of done

- [ ] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- `Platform.haptic()` gebruikt de eigen plugin `PopPulseNative` (UIImpactFeedbackGenerator light/medium/heavy + UINotificationFeedbackGenerator error, vooraf `prepare`d) en valt anders terug op `Input.vibrate_handheld` (Core Haptics in Godot 4.7).
- Throttle van 40 ms: binnen dat venster mag alleen een *sterkere* haptic de vorige vervangen; zo ontstaat bij >10 pops/s geen wachtrij.
- Plugin-bron in `ios/plugins/poppulse_native/src`, bouwinstructies in `ios/plugins/README.md`.
- **Open:** plugin is nog niet gecompileerd en het verschil LIGHT/MEDIUM/HEAVY/ERROR is niet op een toestel gevoeld.

- 8 oktober 2026: PopPulseNative gebouwd (`tools/build_poppulse_native.sh`) en aangezet in beide iOS-presets; export slaagt en linkt. Wacht nog op test op een toestel.
