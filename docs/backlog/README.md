# Pop Pulse — Backlog

Iedere user story is een zelfstandige opdracht die je 1-voor-1 in Cowork kunt laten bouwen. Werk van boven naar beneden; de afhankelijkheden staan per story vermeld.

## Prompt voor Cowork

Gebruik per story deze prompt (vervang het nummer):

```
Lees docs/backlog/README.md (conventies) en docs/backlog/US-XX-*.md.
Implementeer deze user story in het Godot-project in deze map.
Volg de bestaande architectuur en conventies. Houd je aan de scope van de story.
Test door het project te draaien, vink de acceptatiecriteria af in het story-bestand
en zet de status in README.md op ✅.
```

## Architectuur-conventies

- **Godot 4.7, GDScript, getypeerd** (`var x := ...`, return types).
- **Game manager + state machine** in `main.gd`; modes erven van `GameMode` (`modes/game_mode.gd`) en praten alleen via signals.
- **Presentatie los van regels**: effects, audio, haptics en HUD reageren op mode-signals; modes roepen ze niet direct aan.
- **Platformlaag**: alles wat iOS/Android-specifiek is (haptics, IAP, ads, share) gaat via de autoload `Platform`.
- **Data-driven**: tuning, levels, producten en ad-regels in `data/*.json`, niet in code.
- **Opslag** alleen via de autoload `SaveData`.
- **Stijl**: neon arcade; gebruik `ui/ui_style.gd` en (na US-23) het actieve thema i.p.v. hardcoded kleuren.

## Al gebouwd (basis MVP)

- ✅ Bubble-systeem met states, glow-shader, press/pop/fail/expire-animaties (`core/bubble.gd`, `shaders/bubble.gdshader`)
- ✅ Board 5×6 met multi-touch input en fidget/attract-modus in idle (`core/board.gd`)
- ✅ Particles, shockwave-rings, floating text, screenshake (`core/effects.gd`, `main.gd`)
- ✅ Geluid met combo-toonladder (`autoload/sfx.gd`) en basis-haptics (`autoload/platform.gd`)
- ✅ Score Mode: score, combo, multiplier, timer, data-driven ramp (`modes/score_mode.gd`, `data/score_mode.json`)
- ✅ HUD met countdown, resultaten en highscore (`ui/hud.gd`), lokale opslag (`autoload/save_data.gd`)
- ✅ iPhone- en iPad-layout met safe areas; capture-tool voor screenshots (`tools/`)

## Stories


### Fase 1 — MVP valideren

| Status | ID | Story | Afhankelijk van |
|---|---|---|---|
| 🔄 | [US-01](US-01-ios-testbuild.md) | iOS test-build via TestFlight | — |
| ✅ | [US-02](US-02-haptics-device.md) | Haptics op iOS verifiëren en verfijnen | US-01 |
| ✅ | [US-03](US-03-settings.md) | Instellingen: geluid, muziek en haptics | — |
| ✅ | [US-04](US-04-pause-interrupt.md) | Pauze en app-onderbreking | — |
| ✅ | [US-05](US-05-tuning-overlay.md) | Debug tuning-overlay voor game feel | — |

### Fase 2 — Fundament voor meerdere modes

| Status | ID | Story | Afhankelijk van |
|---|---|---|---|
| ✅ | [US-06](US-06-mode-registry.md) | Game modes loskoppelen van main.gd | — |
| ✅ | [US-07](US-07-main-menu.md) | Hoofdmenu met mode-selectie | US-06 |
| ✅ | [US-08](US-08-save-v2.md) | SaveData uitbreiden: schema, stats en voortgang | — |
| ✅ | [US-09](US-09-difficulty-manager.md) | Gedeelde, data-driven Difficulty Manager | US-06 |

### Fase 3 — Game modes

| Status | ID | Story | Afhankelijk van |
|---|---|---|---|
| ✅ | [US-10](US-10-reflex-mode.md) | Reflex Mode | US-06, US-08 |
| ✅ | [US-11](US-11-reflex-history.md) | Reflex-geschiedenis en voortgang | US-10 |
| ✅ | [US-12](US-12-memory-mode.md) | Memory Mode | US-06, US-09 |
| ✅ | [US-13](US-13-stage-framework.md) | Stage Mode: level-framework | US-06, US-08, US-09 |
| ✅ | [US-14](US-14-stage-select.md) | Stage Mode: level-select scherm | US-13 |
| ✅ | [US-15](US-15-stage-levels-30.md) | 30 levels ontwerpen | US-13, US-14 |
| ✅ | [US-16](US-16-first-run.md) | Eerste keer spelen zonder tutorial | US-07, US-08 |

### Fase 4 — Retentie

| Status | ID | Story | Afhankelijk van |
|---|---|---|---|
| ✅ | [US-17](US-17-daily-challenge.md) | Daily Challenge | US-07, US-08 |
| ✅ | [US-18](US-18-streak.md) | Dagelijkse streak | US-17 |
| ✅ | [US-19](US-19-stats-screen.md) | Records- en statistiekenscherm | US-08, US-11 |
| ✅ | [US-20](US-20-share-card.md) | Deelbare resultaatkaart | US-01 |
| ➖ | [US-21](US-21-game-center-leaderboards.md) | Game Center login en leaderboards | US-06, US-08 |
| ✅ | [US-22](US-22-achievements.md) | Achievements | US-21 |

### Fase 5 — Themes & cosmetics

| Status | ID | Story | Afhankelijk van |
|---|---|---|---|
| ✅ | [US-23](US-23-theme-system.md) | Theme-systeem | US-08 |
| ✅ | [US-24](US-24-themes-picker.md) | Extra themes en theme-kiezer | US-23 |
| ✅ | [US-25](US-25-bubble-designs.md) | Unlockable bubble-designs | US-23 |
| ✅ | [US-26](US-26-sound-packs.md) | Geluidspakketten | US-23 |

### Fase 6 — Monetization

| Status | ID | Story | Afhankelijk van |
|---|---|---|---|
| ✅ | [US-27](US-27-monetization-interface.md) | Monetization-interface met mock-implementatie | US-08 |
| 🔄 | [US-28](US-28-storekit-premium.md) | Premium Unlock via StoreKit (RevenueCat) | US-01, US-27 |
| ✅ | [US-29](US-29-premium-gating.md) | Premium-content en upsell-momenten | US-27, US-28 |
| ➖ | [US-30](US-30-cosmetic-packs.md) | Losse cosmetische packs | US-28 |
| 🔄 | [US-31](US-31-ads-sdk-consent.md) | Advertentie-SDK, ATT en toestemming | US-01, US-27 |
| ✅ | [US-32](US-32-rewarded-placements.md) | Rewarded ads op vrijwillige momenten | US-31 |
| ✅ | [US-33](US-33-interstitial-rules.md) | Interstitials met strikte frequentieregels | US-31 |
| ➖ | [US-34](US-34-analytics.md) | Analytics en soft-launch metrics | US-31 |

### Fase 7 — Launch-ready

| Status | ID | Story | Afhankelijk van |
|---|---|---|---|
| ✅ | [US-35](US-35-performance.md) | Performance- en batterijpass | US-01 |
| ✅ | [US-36](US-36-accessibility.md) | Toegankelijkheid | US-23 |
| ✅ | [US-37](US-37-store-assets.md) | App-icoon, launch screen en App Store-assets | US-24 |
| 🔄 | [US-38](US-38-privacy-compliance.md) | Privacy, leeftijdsclassificatie en App Store-compliance | US-31, US-34 |

### Fase 8 — Na launch

| Status | ID | Story | Afhankelijk van |
|---|---|---|---|
| ➖ | [US-39](US-39-cloud-save.md) | Cloud save via iCloud | US-08 |
| ✅ | [US-40](US-40-pass-and-play.md) | Pass-and-play multiplayer | US-06, US-17 |
| ✅ | [US-41](US-41-seasonal-events.md) | Seizoensgebonden content | US-17, US-23 |
| 🔄 | [US-42](US-42-android-port.md) | Android-versie | US-27, US-21 |

Status: ➖ vervallen (keuze product owner) · ⬜ open · 🔄 code klaar, wacht op device-/store-/handmatige verificatie (zie "Implementatie-notities" → **Open** in de story) · ✅ klaar

## Validatie-moment

Na **Fase 1** eerst zelf en met een paar testers spelen (TestFlight). Pas als de kerninteractie overtuigt, door naar Fase 2+. Na **Fase 6** een soft launch in één klein land en sturen op de metrics uit US-34 voordat je breed lanceert.
