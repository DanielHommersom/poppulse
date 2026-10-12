# Android build

Alle platformcode zit achter `Platform`; op Android worden automatisch de Android-backends gekozen als hun plugin-singleton bestaat.

| Functie | Android-implementatie | Plugin |
|---|---|---|
| Haptics | `PopPulseNative.haptic` (predefined effects: tick / click / heavy click), anders `Input.vibrate_handheld` | eigen: `platform_src/android/poppulse_native` |
| Share | `PopPulseNative.share_image` (ACTION_SEND + FileProvider) | eigen |
| Reduce motion | `PopPulseNative.system_reduce_motion` ("Animaties verwijderen") | eigen |
| Aankopen | `platform/play_billing.gd` (`PlayBilling`) incl. pending + acknowledge + stille restore bij start | [GodotGooglePlayBilling](https://github.com/godot-sdk-integrations/godot-google-play-billing) |
| Achievements | lokaal op het toestel (geen Play Games) | – |
| Ads + consent | `platform/admob_ads.gd` (zelfde code als iOS; Android-units in `data/ads.json`) | Poing Studios godot-admob |
| Cloud save | nee: voortgang alleen lokaal op het toestel | – |

## Eenmalig

1. Export templates 4.7.2 + Android SDK/JDK 17 (Editor ▸ Editor Settings ▸ Export ▸ Android). *Project ▸ Install Android Build Template* (gradle build staat aan in de preset).
2. **PopPulseNative bouwen**: maak een Android-library-module van `platform_src/android/poppulse_native/` (Android Studio ▸ New Module ▸ Import), `./gradlew :poppulse_native:assembleRelease`, kopieer de AAR naar `addons/poppulse_native/bin/poppulse_native-release.aar`. De editor-plugin (`addons/poppulse_native`) neemt hem dan mee in de export.
3. Plugins Play Billing en AdMob installeren volgens hun README (Godot 4-versies; check compatibiliteit met 4.7).
4. Play Console: app `com.digitaldiamonds.poppulse`, in-app producten met dezelfde `store_id`'s als in `data/products.json`.
5. Upload-keystore lokaal instellen (niet committen).

## Back-knop

`config/quit_on_go_back = false`; `main._on_back()`: sluit eerst wat bovenop ligt (style-sheet, modals; pauze = hervatten), pauzeert een lopende run, gaat van resultaten naar het menu en sluit pas vanuit het menu de app.

## Testen

Minimaal één goedkoop toestel (bv. 2–3 GB RAM, Android 10) en één high-end toestel: framerate (debug-overlay F2/3 vingers), haptics, aankoop met een licentie-testaccount, consent-formulier in de EER, back-knop in elke staat, share sheet, tablet-layout.
