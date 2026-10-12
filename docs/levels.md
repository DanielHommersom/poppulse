# Stage-levels

Bron: `data/stages/stages.json` (gegenereerd met `tools/gen_levels.py`, daarna vrij met de hand aan te passen).

Iedere 5e level is een piek; de level erna is bewust rustiger. Een fout = verkeerde bubble, gemiste target of een 'niet tikken'-bubble aangetikt. Sterren: 1 = gehaald; 2/3 als zowel de tijd als het aantal fouten binnen de drempel blijft.

## Blok 1 (1–10) — **meerdere tegelijk**: van één target naar 2–4 tegelijk en targets die in paren oplichten.

| ID | Naam | Nieuw element | Board | Doel | Tijd (s) | Max fouten | ★★★ | ★★ | Bot casual / skilled (gehaald, sterren) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | First Pops | basics | 4×5 | 16 | 18 | 5 | ≤ 10.2s, ≤ 1 fout | ≤ 13.3s, ≤ 3 fouten | 5/5 22222 / 5/5 33333 |
| 2 | Warming Up | basics | 4×5 | 19 | 20 | 5 | ≤ 12.2s, ≤ 1 fout | ≤ 14.8s, ≤ 3 fouten | 5/5 22323 / 5/5 33333 |
| 3 | Two's Company | two targets live | 4×5 | 22 | 22 | 4 | ≤ 14.2s, ≤ 1 fout | ≤ 16.3s, ≤ 2 fouten | 5/5 22313 / 5/5 33323 |
| 4 | Keep Up | two targets live | 4×5 | 26 | 26 | 4 | ≤ 16.2s, ≤ 1 fout | ≤ 19.3s, ≤ 2 fouten | 5/5 22222 / 5/5 33333 |
| 5 | Rush Hour | piek | 4×5 | 35 | 32 | 3 | ≤ 21.6s, ≤ 0 fout | ≤ 23.8s, ≤ 1 fouten | 5/5 13213 / 5/5 33122 |
| 6 | Double Tap | doubles (lit in pairs) | 4×5 | 22 | 14 | 4 | ≤ 8.3s, ≤ 1 fout | ≤ 10.5s, ≤ 2 fouten | 5/5 22222 / 5/5 33333 |
| 7 | Pairs | doubles | 4×5 | 29 | 18 | 4 | ≤ 11.1s, ≤ 1 fout | ≤ 13.5s, ≤ 2 fouten | 5/5 21222 / 5/5 33333 |
| 8 | Triple Threat | three targets live | 4×5 | 32 | 20 | 4 | ≤ 11.8s, ≤ 1 fout | ≤ 14.7s, ≤ 2 fouten | 5/5 22122 / 5/5 33233 |
| 9 | Crowded | up to four live | 4×5 | 35 | 22 | 3 | ≤ 13.2s, ≤ 0 fout | ≤ 15.8s, ≤ 1 fouten | 5/5 21112 / 5/5 33333 |
| 10 | Swarm | piek | 4×5 | 45 | 25 | 3 | ≤ 16.7s, ≤ 0 fout | ≤ 18.8s, ≤ 1 fouten | 4/5 31110 / 5/5 32233 |

## Blok 2 (11–20) — **kortere lifetime**: targets doven sneller uit; groter board (5×5).

| ID | Naam | Nieuw element | Board | Doel | Tijd (s) | Max fouten | ★★★ | ★★ | Bot casual / skilled (gehaald, sterren) |
|---|---|---|---|---|---|---|---|---|---|
| 11 | Quick Fade | shorter lifetime | 5×5 | 26 | 26 | 4 | ≤ 16.6s, ≤ 1 fout | ≤ 19.1s, ≤ 2 fouten | 5/5 22332 / 5/5 33333 |
| 12 | Blink | shorter lifetime | 5×5 | 29 | 28 | 4 | ≤ 18.5s, ≤ 1 fout | ≤ 21.0s, ≤ 2 fouten | 5/5 33323 / 5/5 23333 |
| 13 | Flicker | short + two live | 5×5 | 32 | 30 | 4 | ≤ 20.1s, ≤ 1 fout | ≤ 22.5s, ≤ 2 fouten | 5/5 33333 / 5/5 33333 |
| 14 | Snap Pairs | short doubles | 5×5 | 35 | 21 | 3 | ≤ 12.9s, ≤ 0 fout | ≤ 15.1s, ≤ 1 fouten | 4/5 33021 / 5/5 23223 |
| 15 | Lightning | piek | 5×5 | 45 | 21 | 3 | ≤ 15.0s, ≤ 0 fout | ≤ 15.4s, ≤ 1 fouten | 5/5 22221 / 5/5 12233 |
| 16 | Breather | short, calm | 5×5 | 26 | 27 | 5 | ≤ 16.5s, ≤ 1 fout | ≤ 19.8s, ≤ 3 fouten | 5/5 22222 / 5/5 33333 |
| 17 | Fast Pairs | short doubles | 5×5 | 35 | 20 | 4 | ≤ 12.9s, ≤ 1 fout | ≤ 14.5s, ≤ 2 fouten | 5/5 32332 / 5/5 33233 |
| 18 | Three Flash | short, three live | 5×5 | 38 | 21 | 3 | ≤ 13.7s, ≤ 0 fout | ≤ 15.1s, ≤ 1 fouten | 5/5 13122 / 5/5 33323 |
| 19 | Strobe | short, four live | 5×5 | 42 | 21 | 3 | ≤ 14.7s, ≤ 0 fout | ≤ 15.2s, ≤ 1 fouten | 5/5 23223 / 5/5 32132 |
| 20 | Overdrive | piek | 5×5 | 51 | 22 | 3 | ≤ 15.6s, ≤ 0 fout | ≤ 16.1s, ≤ 1 fouten | 4/5 03321 / 5/5 32323 |

## Blok 3 (21–30) — **vaste patronen en 'niet tikken'-bubbles** (grijs met kruis); board 5×6.

| ID | Naam | Nieuw element | Board | Doel | Tijd (s) | Max fouten | ★★★ | ★★ | Bot casual / skilled (gehaald, sterren) |
|---|---|---|---|---|---|---|---|---|---|
| 21 | Merry-go-round | fixed pattern | 5×6 | 26 | 26 | 4 | ≤ 16.8s, ≤ 1 fout | ≤ 19.4s, ≤ 2 fouten | 5/5 22122 / 5/5 33333 |
| 22 | Don't Touch | decoys | 5×6 | 29 | 32 | 4 | ≤ 19.2s, ≤ 1 fout | ≤ 23.4s, ≤ 2 fouten | 5/5 13222 / 5/5 33333 |
| 23 | Zigzag | pattern + decoys | 5×6 | 32 | 32 | 4 | ≤ 21.2s, ≤ 1 fout | ≤ 24.1s, ≤ 2 fouten | 5/5 22332 / 5/5 33331 |
| 24 | Minefield | decoys in pairs | 5×6 | 35 | 24 | 4 | ≤ 14.9s, ≤ 1 fout | ≤ 17.5s, ≤ 2 fouten | 5/5 22213 / 5/5 33333 |
| 25 | Trapdoor | piek | 5×6 | 42 | 42 | 3 | ≤ 30.1s, ≤ 0 fout | ≤ 31.5s, ≤ 1 fouten | 3/5 01201 / 5/5 33322 |
| 26 | Easy Does It | decoys, calm | 5×6 | 29 | 32 | 4 | ≤ 19.2s, ≤ 1 fout | ≤ 23.7s, ≤ 2 fouten | 5/5 23112 / 5/5 33333 |
| 27 | Diagonals | paired pattern | 5×6 | 35 | 23 | 4 | ≤ 14.2s, ≤ 1 fout | ≤ 16.6s, ≤ 2 fouten | 5/5 23223 / 5/5 33333 |
| 28 | Crossfire | pattern + decoys | 5×6 | 38 | 39 | 4 | ≤ 26.5s, ≤ 1 fout | ≤ 29.0s, ≤ 2 fouten | 5/5 33133 / 5/5 33333 |
| 29 | Hazard | many decoys | 5×6 | 42 | 27 | 4 | ≤ 19.5s, ≤ 1 fout | ≤ 20.2s, ≤ 2 fouten | 5/5 12321 / 5/5 32333 |
| 30 | Grand Finale | piek | 5×6 | 54 | 32 | 4 | ≤ 22.6s, ≤ 1 fout | ≤ 23.5s, ≤ 2 fouten | 4/5 11120 / 5/5 33333 |

## Haalbaarheid

`tools/level_bot.tscn` speelt ieder level 5× met twee gesimuleerde spelers (headless, versneld):

- **casual** — reactie 420 ± 80 ms, 160 ms tussen tikken, 3% mis-tik, 8% tikt een 'niet tikken'-bubble aan;
- **skilled** — reactie 300 ± 50 ms, 110 ms tussen tikken, 1% mis-tik, 2% decoy.

Tijdslimiet = mediane casual-tijd × 1,45 + 2 s; ★★★-tijd = mediane skilled-tijd × 1,12 + 0,5 s; ★★-tijd = mediane casual-tijd × 1,1 + 1 s.

Opnieuw meten na het aanpassen van levels:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://tools/level_bot.tscn -- --test-save --runs=5
```
