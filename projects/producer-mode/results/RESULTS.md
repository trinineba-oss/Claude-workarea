# Measurements

One row per tweak, enabled **alone**, on a fresh boot. Record negative results too.
Latency: OboeTester Round Trip (loopback) or Tap to Tone. Glitches: OboeTester Glitch test or
10 min of the fixed FL Studio Mobile test project. Thermals: max zone temp over 15 min.
Battery: % drain per 30 min.

| Tweak | Setting | Latency OFF → ON (ms) | Glitches OFF → ON | Max temp OFF → ON (°C) | Throttled? | Battery /30 min OFF → ON | Keep? |
|---|---|---|---|---|---|---|---|
| baseline | all off | | | | | | — |
| CPU_MINFREQ_PCT | 70 | | | | | | |
| CPU_GOVERNOR_PERF | 1 | | | | | | |
| TOPAPP_UCLAMP_MIN | 50 | | | | | | |
| DOZE_WHITELIST | 1 | | | | | | |
| ANIMATIONS_OFF | 1 | | | | | | |
| AUDIO_MMAP | 1 | | | | | | |
| AUDIO_STANDBY_MS | 60000 | | | | | | |
| Auto mode poll cost | 5 s | avg ms/poll from log: | | | | | |
