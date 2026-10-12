# iOS-plugins

Alle native code zit achter `autoload/platform.gd`. Iedere plugin is optioneel: ontbreekt de singleton (desktop, Android, of een build zonder plugin), dan valt `Platform` terug op een portable implementatie of een no-op/mock.

| Singleton | Bron | Gebruikt door |
|---|---|---|
| `PopPulseNative` | eigen plugin, `poppulse_native/src/` | haptics (US-02), share sheet (US-20), Reduce Motion (US-36), open_url |
| `GodotxRevenueCat` | [godot-x/revenue-cat](https://github.com/godot-x) 2.5.0 (`addons/godotx_revenue_cat`, `revenue_cat/`) | Premium-aankoop + restore (US-28) — zie `docs/storekit.md` |
| `GodotxATT` | [godot-x/att](https://github.com/godot-x) 3.0.0 (`addons/godotx_att`, `att/`) | Apple's tracking-vraag (US-31) |
| `PoingGodotAdMob` | [Poing Studios godot-admob](https://github.com/poingstudios/godot-admob) v5.1 (`addons/admob`, libs in `addons/admob/ios/bin`) | ads + UMP-consent (US-31) — zie `docs/ads.md` |

## PopPulseNative bouwen

Gebouwd en ingecheckt: `poppulse_native/PopPulseNative.debug.xcframework` en `.release.xcframework` (toestel arm64 + simulator). Godot kiest zelf de juiste variant bij een debug- of release-export. Opnieuw bouwen, nodig na een wijziging in `src/` of een nieuwe Godot-versie:

```bash
git clone --depth 1 --branch 4.7.2-stable https://github.com/godotengine/godot.git ~/src/godot
pip3 install --user scons
tools/build_poppulse_native.sh ~/src/godot
```

Het script laat scons alleen de twee gegenereerde headers maken (geen engine-build) en compileert de plugin met dezelfde defines als de officiële iOS-templates (`DEBUG_ENABLED` alleen in de debug-variant, anders klopt de objectindeling niet). De Godot-broncode moet exact dezelfde versie zijn als de editor.

Let op: de officiële Godot-templates bevatten alleen een Intel-simulatorslice, en de iOS 26-simulator draait geen Intel-apps meer. Testen kan dus alleen op een echt toestel.

## Overige plugins

Voortgang wordt alleen op het toestel opgeslagen; er is geen iCloud-sync (US-39 vervallen).

De RevenueCat-xcframeworks zijn uitgedund tot `ios-arm64` + simulator (± 228 MB, inclusief dSYMs). Gebruik git LFS of houd ze buiten git en download de plugin opnieuw. `addons/admob/ios/bin` staat al in de `.gitignore` van de plugin.
