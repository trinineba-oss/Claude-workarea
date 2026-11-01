# Recon notes (per device; copy this table for each phone you test)

**Status: not run yet.** Run `tools/recon.sh` with the phone attached, then fill in below.
Phase 3 tweaks stay disabled until this confirms they are possible.

| Question | Finding |
|---|---|
| Exact model / device / platform | |
| Chipset (MediaTek / Snapdragon) | |
| cpufreq policies and steps | |
| `scaling_min_freq` writable? | |
| `performance` governor available? | |
| Vendor perf control (`/proc/ppm`, perf HAL) that overrides? | |
| uclamp in `/dev/cpuctl/top-app`? | |
| audioserver fast threads SCHED_FIFO? | |
| Fast mixer / MMAP in audio_flinger? | |
| Native sample rate / burst size | |
| MPK Mini II enumerates (`dumpsys usb`, `/dev/snd`)? | |
| Idle thermal zone temps | |
