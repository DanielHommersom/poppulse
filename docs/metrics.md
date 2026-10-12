# Metrics & soft launch

Er zit **geen analytics-SDK** in Pop Pulse (TelemetryDeck is op 5 okt 2026 verwijderd). Meten gebeurt met de dashboards die je al hebt:

| Metric | Bron | Doel soft launch |
|---|---|---|
| D1 / D7-retentie | App Store Connect ▸ App Analytics ▸ Retention (spelers die analyse delen met ontwikkelaars) | ≥ 35 % / ≥ 12 % |
| Sessies per actief toestel | App Store Connect ▸ App Analytics ▸ Usage | ≥ 2,5 per dag |
| Conversie Premium | App Store Connect ▸ Sales and Trends: aantal Premium-aankopen ÷ installaties | ≥ 2 % |
| Ad-opbrengst, eCPM, fill | AdMob ▸ Reports (per ad unit: rewarded / interstitial) | – |
| ARPDAU | (IAP-omzet + AdMob-omzet) ÷ dagelijks actieve gebruikers | ≥ € 0,03 |

Niet meer zichtbaar zonder analytics: welke modes/levels gespeeld worden, waar spelers vastlopen en welk upsell-moment converteert. Wil je dat later toch weten, dan kan er opnieuw een (privacyvriendelijke) analytics-backend achter `Platform` worden gezet.
