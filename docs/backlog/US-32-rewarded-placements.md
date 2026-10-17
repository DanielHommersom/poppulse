# US-32 — Rewarded ads op vrijwillige momenten

**Fase 6 — Monetization** · Afhankelijk van: US-31

## User story

Als gratis speler wil ik zelf kiezen om een video te kijken voor een voordeel, zodat ik nooit gedwongen word.

## Relevante code / context

- Ads SDK (US-31)
- Stage Mode (US-13)
- Score Mode
- Daily (US-17)
- Themes (US-24)

## Acceptatiecriteria

- [x] Placement 'continue': na falen in Stage of Score Mode, 1× per run doorgaan (+10 s of 1 leven extra).
- [x] Placement 'theme_trial': premium thema 24 uur proberen.
- [x] Placement 'daily_retry': één extra officiële poging voor de daily challenge.
- [x] Knop is verborgen als er geen ad beschikbaar is (geen lege wachtschermen).
- [x] Beloning alleen bij voltooide ad (callback), niet bij overslaan.
- [x] Records behaald met 'continue' worden gemarkeerd / tellen niet voor leaderboard (keuze vastleggen).

## Definition of done

- [x] Alle acceptatiecriteria afgevinkt
- [x] Project start zonder errors/warnings in Godot
- [x] Bestaande modes handmatig getest op regressie
- [x] Platformspecifieke code alleen in `autoload/platform.gd` (of plugins daarachter)
- [x] Status in `docs/backlog/README.md` bijgewerkt

## Implementatie-notities

- **continue**: na time-up in Score (+10 s) of verlies in Stage (+1 leven, of +10 s bij tijd op), 1× per run. Link '▶ CONTINUE …' op het resultaat; na een volledig bekeken ad: 3-2-1 en de run gaat verder met dezelfde score/combo. Het eerste (tussen)resultaat wordt teruggedraaid, zodat de run één keer telt.
- **theme_trial**: in het style-sheet bij een gelockt premium-thema '▶ TRY FOR 24 HOURS' → 24 uur bruikbaar (`unlocks.trials`); na afloop valt het thema terug naar Neon.
- **daily_retry**: na je officiële daily '▶ ONE MORE OFFICIAL TRY' (max. 1 per dag); de beste van beide telt.
- Knoppen alleen zichtbaar als `Platform.can_show_rewarded()` true is; beloning alleen bij `show_rewarded() == true` (volledig bekeken), niet bij overslaan.
- **Keuze vastgelegd:** een record dat met 'continue' is behaald telt lokaal wel als persoonlijk record maar wordt gemarkeerd ('NEW BEST! (continued)', `best_continued` in de save) en wordt **nooit** naar een leaderboard gestuurd.
- Premium-spelers krijgen deze voordelen zonder ad.
- Getest met de mock-ads (scenario `s_rewarded`).

- 17 oktober 2026 (build 2): extra rewarded-placements `level_trial` (vergrendeld level 1× spelen) en `style_trial` (ook bubbles + geluiden 24 uur); zie docs/ads.md.
