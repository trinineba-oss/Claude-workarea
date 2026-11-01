#!/bin/sh
# Phase 0 device recon. Runs on the host, read-only on the phone.
# Output: recon/report.txt. Summarise into recon/NOTES.md by hand.
cd "$(dirname "$0")/.."; mkdir -p recon; OUT=recon/report.txt
r() { echo; echo "### $1"; adb shell su -c "$1" 2>&1; }
{
  echo "# Producer Mode recon $(date)"
  for p in ro.product.model ro.product.device ro.board.platform ro.hardware \
           ro.build.version.release ro.build.fingerprint; do
    echo "$p=$(adb shell getprop $p | tr -d '\r')"
  done
  r 'for p in /sys/devices/system/cpu/cpufreq/policy*; do echo "== $p (cpus: $(cat $p/related_cpus))"; for f in scaling_available_governors scaling_governor scaling_min_freq scaling_max_freq cpuinfo_max_freq scaling_available_frequencies; do printf "%s: " $f; cat $p/$f 2>&1; done; ls -l $p/scaling_min_freq $p/scaling_governor; done'
  r 'for d in /proc/ppm /sys/kernel/ged /proc/cpufreq /sys/module/msm_performance /sys/devices/system/cpu/cpu_boost; do [ -e $d ] && { echo "PRESENT: $d"; ls $d; } || echo "absent: $d"; done'
  r 'cat /proc/ppm/policy_status 2>/dev/null'
  r 'ps -A | grep -i -E "power|perf"'
  r 'for f in /dev/cpuset/*/cpus; do echo "$f: $(cat $f)"; done'
  r 'ls /dev/stune 2>&1; ls /dev/cpuctl 2>&1; for f in /dev/cpuctl/*/cpu.uclamp.min; do echo "$f: $(cat $f)"; done'
  r 'dumpsys media.audio_flinger | head -150'
  r 'dumpsys media.audio_flinger | grep -i -E "mmap|fast|frame count|sample rate|latency"'
  r 'getprop | grep -i -E "aaudio|audio"'
  r 'lshal 2>/dev/null | grep -i audio; ps -A | grep -i audio'
  r 'pid=$(pidof audioserver); ps -T -p $pid -o tid,cls,rtprio,comm'
  r 'dumpsys usb | head -80'
  r 'ls -l /dev/snd; cat /proc/asound/cards'
  r 'for z in /sys/class/thermal/thermal_zone*; do echo "$(cat $z/type): $(cat $z/temp)"; done'
} > "$OUT"
echo "Wrote $OUT"
