# iOS build & TestFlight-upload

## Eenmalig

1. **Export templates** — Godot ▸ Editor ▸ Manage Export Templates ▸ *Download and Install* (4.7.2). Zonder `ios.zip` faalt de export.
2. **Xcode** (26+) met een ingelogd Apple Developer-account (Xcode ▸ Settings ▸ Accounts).
3. **App ID** `com.digitaldiamonds.poppulse` aanmaken in het Developer-portal met de capability *In-App Purchase*.
4. **App Store Connect** ▸ My Apps ▸ *+ New App* met dezelfde bundle id.
5. **Team ID** — vul in Godot (Project ▸ Export ▸ iOS ▸ *App Store Team ID*) je 10-tekens team-id in. Dit veld staat leeg in git; **commit geen signing-gegevens** (team-id, provisioning-UUID's, certificaten). Lokaal kun je ze ook via de editor invullen en de wijziging aan `export_presets.cfg` niet committen (`git update-index --assume-unchanged export_presets.cfg`).
6. **Native plugins** — zie `ios/plugins/README.md`. De officiële Godot iOS-plugins (`InAppStore`, later `ICloud`) en `PopPulseNative` (haptics + share sheet) worden in `ios/plugins/` geplaatst. Ontbreekt een plugin, dan valt `Platform` stil terug op een no-op / mock; de game blijft volledig speelbaar.

## Presets

| Preset | Gebruik | Bevat debug-tools |
|---|---|---|
| `iOS` | TestFlight / App Store (release) | nee (`debug/*` uitgesloten) |
| `iOS Playtest` | interne playtests met tuning-overlay (US-05) | ja (alleen in een *debug*-export zichtbaar) |

Beide: portrait-only (`display/window/handheld/orientation`), iPhone + iPad (`targeted_device_family = 2`), iOS 15+.

## Nieuwe TestFlight-build

1. Verhoog `application/version` (build-nummer) in de preset; `short_version` alleen bij een nieuwe marketingversie.
2. Project ▸ Export ▸ **iOS** ▸ *Export Project…* ▸ vink **Export With Debug** uit ▸ `build/ios/PopPulse.ipa`.
   Of via de terminal:
   ```bash
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-release "iOS" build/ios/PopPulse.ipa
   ```
3. Godot maakt naast de `.ipa` ook een Xcode-project. Open `build/ios/PopPulse.xcodeproj` ▸ *Product ▸ Archive*.
4. In de Organizer: *Distribute App* ▸ *App Store Connect* ▸ *Upload*.
5. App Store Connect ▸ TestFlight: wacht op *Processing*, vul *What to Test* in en voeg testers toe.

## Op een eigen toestel (zonder TestFlight)

Preset **iOS** (of **iOS Playtest**) ▸ *Export With Debug* aan ▸ open het Xcode-project ▸ kies je iPhone/iPad ▸ *Run*. Of in de Godot-editor: Remote Debug ▸ *One-click deploy* naar een aangesloten toestel.

## Controlelijst per build

- [ ] Start zonder crash op iPhone én iPad.
- [ ] Notch / Dynamic Island en home-indicator overlappen geen HUD (`Platform.safe_margins()`; desktop-preview: `Godot --path . -- --fake-notch`).
- [ ] ProMotion: 120 fps. Geregeld via `display/window/ios/allow_high_refresh_rate`, `vsync_mode = enabled`, `application/run/max_fps = 0` en `CADisableMinimumFrameDurationOnPhone` in de Info.plist (preset ▸ *additional_plist_content*). Controleer met de FPS-teller in de tuning-overlay (US-05) of Xcode ▸ Debug Navigator.
- [ ] Stil-schakelaar dempt geluid (`audio/general/ios/session_category = Ambient`).
