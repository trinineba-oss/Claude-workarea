# Producer Mode (Magisk / KernelSU / APatch module)

Toggleable "music production" mode for any rooted Android 9+ device, used with a USB MIDI controller and
Android DAWs (FL Studio Mobile, Zenbeats, Koala, G-Stomper). Aims for fewer dropouts and steadier
latency. Off = normal phone. Everything it changes is backed up and restored.

**It never touches thermal protection.** No thermal services, configs or trip points are changed.

## Before you install
- Keep Magisk's stock boot image backup and a known-good module zip.
- Know the rescue path (below).
- Magisk v27+, KernelSU and APatch give you the Action button. Older Magisk: `su -c sh /data/adb/modules/producer-mode/action.sh`.

## Device compatibility
One zip for every device. Nothing is hard-coded to a chipset: each tweak checks what the device
has and skips cleanly (and says so) when it's missing.

| Need | Supported |
|---|---|
| Android | 9+ (API 28) |
| Root | Magisk, KernelSU, APatch |
| CPU | any architecture (pure shell, no binaries) |
| CPU frequency | `cpufreq/policy*`, or per-CPU `cpuN/cpufreq` on older kernels |
| Foreground boost | `uclamp` (newer kernels) or `schedtune.boost` (older 4.x kernels) |
| Audio props | `resetprop` required for `ro.*` props; skipped without it |

The installer prints a capability report for your device; it is also saved to
`/data/adb/producer-mode/state/caps.txt` and refreshed every boot. Vendor performance daemons
(MediaTek PPM, Qualcomm `msm_performance`/`cpu_boost`) can override CPU settings: the module
detects that, logs `OVERRIDE`, and never fights it.

## Install
From a PC with adb: `tools/install.sh` then `adb reboot`.
Or build with `tools/build.sh` and flash `dist/producer-mode-*.zip` in the Magisk app.

## Toggle
Magisk app → Modules → Producer Mode → **Action**. It shows a summary of what was applied.
Press again to turn it off and restore everything. Every reboot starts in OFF.

## Configure
Edit `/data/adb/producer-mode/producer.conf` (kept across updates). **All tweaks start disabled**:
enable one, toggle on, measure (see `results/RESULTS.md`), keep it only if it helps.
Wi-Fi/Bluetooth are never turned off unless you set `WIFI_OFF=1` / `BLUETOOTH_OFF=1` (Wi-Fi off breaks wireless ADB).

DAW apps live in `/data/adb/producer-mode/apps.list`, one package per line. Find a package name with
`adb shell pm list packages | grep -i <name>`. Used for the Doze whitelist and auto mode.

Auto mode (`AUTO_MODE=1`, needs a reboot) switches ON when a listed app is in front and back OFF when
you leave it. It only turns off what it turned on itself; a manual ON stays on. The log reports the
poll's own cost every 60 polls.

## Logs and state
Log: `/data/adb/producer-mode/log.txt` (rotated at 256 KB), pull with `tools/logs.sh`.
State and backups: `/data/adb/producer-mode/state/`.

## Bootloop recovery
- From a PC: `tools/rescue.sh` (waits for adb, then disables all Magisk modules).
- On the phone: boot to safe mode (the key combo varies; often hold Volume Down during boot); Magisk and
  KernelSU then disable modules.
The module does nothing in `post-fs-data`, so a boot hang from it is unlikely.

## Uninstall
Remove it in your root manager and reboot. `uninstall.sh` waits for boot, restores any leftover settings and
Doze entries, then deletes `/data/adb/producer-mode`.

## Developer workflow
1. `tools/recon.sh` → `recon/report.txt`, summarise in `recon/NOTES.md`.
2. Enable one tweak, reboot, measure, record in `results/RESULTS.md`.
3. `system.prop` stays empty until a prop is proven at runtime.
