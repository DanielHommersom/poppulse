# Reflex Mode — meetmethode

**Start** — `ReflexMode._light()` zet de bubble *instant* aan (`Bubble.light_up(instant = true)`, geen fade-in) en wacht daarna op `RenderingServer.frame_post_draw`. Het moment waarop dat signaal vuurt (`Time.get_ticks_usec()`) is de start: het eerste frame waarin de bubble volledig oplicht is dan naar de GPU gestuurd.

**Einde** — `Board._unhandled_input` stempelt `Board.last_press_usec = Time.get_ticks_usec()` op het moment dat de touch-down-event wordt verwerkt, nog vóór `_process` van dat frame. De reactie is `last_press_usec − start`.

Waarom niet de frame-tijd: met frame-tijd zou iedere meting op een veelvoud van 8,3 ms (120 Hz) of 16,7 ms (60 Hz) vallen en altijd de wachttijd tot het volgende frame bevatten.

**Wat er níet in zit** (constant per toestel, dus eerlijk voor vergelijkingen op hetzelfde toestel):

- scan-out van het scherm (≈ ½ frame),
- touch-sampling van het scherm (120–240 Hz op recente iPhones) en de afhandeling door iOS tot de event bij Godot is.

Godot 4.7 geeft input-events geen hardware-tijdstempel mee; de eerste plek waar we de touch zien is de event-afhandeling. Op Android kan `input_devices/buffering/agile_event_flushing` dat nog iets verbeteren (zie US-42).

**Randgevallen**

- Tik vóór het oplichten → `TOO EARLY`, de prikkel wordt opnieuw gestart (telt niet).
- Tik op een andere bubble terwijl er één oplicht → fout, geen tijd; telt als prikkel.
- Geen tik binnen `timeout` s → `TOO SLOW`, telt als prikkel.
- Pauze terwijl een bubble oplicht → de prikkel wordt opnieuw gestart, zodat de pauze nooit in een meting komt.
- Een tik die binnenkomt voordat het oplicht-frame gerenderd is, kan geen reactie zijn en krijgt minimaal 1 ms.
