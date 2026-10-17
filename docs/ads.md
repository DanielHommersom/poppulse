# Advertenties, consent en ATT

Alles zit achter `Platform` (`autoload/platform.gd`): `can_show_rewarded`, `show_rewarded`, `maybe_show_interstitial`, `start_ads_after_first_game`, `show_ad_privacy_options`. Backend op een toestel: `platform/admob_ads.gd`; desktop / zonder native plugin: `platform/mock_ads.gd`.

## Plugin (geïnstalleerd)

[Poing Studios godot-admob](https://github.com/poingstudios/godot-admob-plugin) **v5.1.0** (getest t/m Godot 4.7.2, Google Mobile Ads iOS 13.9.0, UMP 3.1.0):

- `addons/admob/` — de GDScript-API + editor-plugin (aanzetten: Project ▸ Project Settings ▸ Plugins ▸ AdMob).
- `addons/admob/ios/bin/` — de iOS-library (`ios-template-v4.7.2.zip`, alleen `ads`, geen mediation). De Google-SDK's komen via Swift Package Manager mee bij het exporteren.
- Project Settings ▸ `admob/general/ios/app_id` = `ca-app-pub-3366446717708247~4912469721`. De plugin schrijft zelf `GADApplicationIdentifier` en de SKAdNetwork-lijst in de Info.plist; die horen dus **niet** in *Additional Plist Content*.
- Updaten: nieuwe release downloaden, `addons/admob` vervangen, de iOS-template van dezelfde versie in `addons/admob/ios/bin/` zetten.

## Ad units

`data/ads.json` → `units.<os>.<rewarded|interstitial>.test|release`. Debug-builds gebruiken altijd Googles test-units; release-builds de echte (iOS: rewarded `…/3435736524`, interstitial `…/9123177472`).

## Volgorde bij de eerste keer

1. Speler speelt zijn eerste potje (nooit een prompt bij app-start).
2. **Google UMP** (`AdMobAds.request_consent`): het GDPR/TCF-formulier waar dat nodig is (EER/VK).
3. **Eigen uitleg** (`ui/att_prompt.gd`, "Keep Pop Pulse free" → CONTINUE), daarna **Apple's tracking-vraag (ATT)** via de godot-x/att-plugin (singleton `GodotxATT`). De tekst in Apple's venster is `NSUserTrackingUsageDescription` in de export-preset. Is de status al bepaald (of beperkt), dan verschijnt geen van beide.
4. De Ads-SDK start. Gepersonaliseerd alleen met GDPR-toestemming (of niet vereist) **én** ATT "authorized"; anders `npa=1`.
5. Status in `SaveData.ads`. Volgende starts: direct door (UMP ververst de status stil).

Premium → de SDK wordt nooit gestart en er worden nooit ads geladen of getoond.

## AdMob ▸ Privacy & messaging (verplicht)

1. **European regulations** (GDPR): bericht maken voor Pop Pulse, talen EN + NL, met "Do not consent", publiceren.
2. **IDFA explainer**: **niet** publiceren. De app toont zelf de uitleg en Apple's ATT-vraag; met dit bericht erbij krijgt de speler twee uitlegschermen.
3. **US state regulations**: bericht maken en publiceren.

## Instelling

Settings ▸ PRIVACY & LEGAL ▸ **CHANGE AD CONSENT** opent Google's privacy-opties. De knop staat er alleen als: geen Premium, de consent-flow heeft gedraaid (na het 1e potje) én UMP zegt dat privacy-opties verplicht zijn (`privacy_options_requirement_status == REQUIRED`: EER/VK/CH, gereguleerde US-staten). Elders zou Google's formulier niet verschijnen. Na sluiten wordt de nieuwe keuze direct toegepast (`npa` voor volgende advertenties; de SDK leest ook de nieuwe TCF-string).

## Frequentie (build 2, `data/ads.json`)

**Interstitials** (alleen bij resultaten ▸ menu / volgend potje, `core/ad_rules.gd`):
- eerste sessie pas vanaf het **3e afgeronde potje** (`first_session_after_runs`), daarna vrij volgens de regels hieronder;
- nieuwe sessie = koude start **of terugkomen na ≥ 30 min** op de achtergrond (`session_gap_seconds`);
- minimaal **3 potjes** en **90 s** tussen twee interstitials;
- niet na het **allereerste potje van een modus** (`skip_first_run_per_mode`); records blokkeren niet meer;
- niet direct na een rewarded video; nooit met Premium, nooit tijdens spelen/pauze/opstarten.

**Rewarded** (altijd vrijwillig, knop alleen als er een video klaarstaat):
| Placement | Waar | Beloning |
|---|---|---|
| `continue` | resultaat (normaal potje) | doorspelen |
| `daily_retry` | resultaat (Daily) | extra officiële poging |
| `style_trial` | Style ▸ premium thema / bubble / geluid | 24 uur gebruiken (`unlocks.trials`, sleutel `id` of `kind:id`) |
| `level_trial` | Premium-scherm bij een vergrendeld level (13–30, alleen als het via voortgang bereikbaar is) | dat level 1× spelen; RETRY/NEXT daarna gaan weer via het slot |

Verlopen trials vallen bij de volgende start terug op de standaard (thema Neon, bubble Round, geluid Classic).

