# Device capability detection. Read-only. Lets one module run on any rooted Android 9+ device:
# every tweak checks what exists and skips cleanly when it doesn't.

# Root manager: magisk | kernelsu | apatch | unknown
root_manager() {
  if [ -n "$KSU" ] || [ -d /data/adb/ksu ]; then echo kernelsu
  elif [ -n "$APATCH" ] || [ -d /data/adb/ap ]; then echo apatch
  elif command -v magisk >/dev/null 2>&1 || [ -d /data/adb/magisk ]; then echo magisk
  else echo unknown; fi
}

# Boost interface for the foreground app: uclamp (newer kernels) | schedtune (older, 4.x) | none
boost_iface() {
  if [ -e /dev/cpuctl/top-app/cpu.uclamp.min ]; then echo uclamp
  elif [ -e /dev/stune/top-app/schedtune.boost ]; then echo schedtune
  else echo none; fi
}

# Vendor performance daemons that may override CPU settings (logged, never fought).
vendor_perf() {
  v=""
  for d in /proc/ppm /sys/module/msm_performance /sys/devices/system/cpu/cpu_boost /sys/kernel/ged; do
    [ -e "$d" ] && v="$v ${d##*/}"
  done
  echo "${v# }"
}

# Full report, one "key: value" per line.
caps_report() {
  echo "device: $(getprop ro.product.manufacturer) $(getprop ro.product.model) ($(getprop ro.product.device))"
  echo "platform: $(getprop ro.board.platform) / $(getprop ro.hardware)"
  echo "android: $(getprop ro.build.version.release) (API $(getprop ro.build.version.sdk))"
  echo "root: $(root_manager)"
  echo "cpu policies: $(cpu_policies | wc -l)"
  g=no; for p in $(cpu_policies); do grep -qw performance "$p/scaling_available_governors" 2>/dev/null && g=yes; done
  echo "performance governor: $g"
  echo "foreground boost: $(boost_iface)"
  echo "vendor perf control: $(vendor_perf | sed 's/^$/none/')"
  m=no; audio_mmap_supported && m=yes
  echo "aaudio mmap: $m"
  command -v resetprop >/dev/null 2>&1 && echo "resetprop: yes" || echo "resetprop: no (ro.* audio props unavailable)"
}
