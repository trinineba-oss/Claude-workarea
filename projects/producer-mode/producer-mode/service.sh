#!/system/bin/sh
MODDIR=${0%/*}
. "$MODDIR/lib/common.sh"; . "$MODDIR/lib/toggle.sh"
wait_boot
pm_log "boot: module $(grep ^version= "$MODDIR/module.prop")"
# Clean "off" state on every boot. Settings/Doze persist across reboots, so restore them;
# sysfs and props were already reset by the reboot.
lock
[ -n "$(ls "$PM_BK" 2>/dev/null)" ] && { pm_log "boot: restoring leftovers"; restore_all boot; }
set_mode off; rm -f "$PM_STATE/owner"
unlock
load_config
[ "${AUTO_MODE:-0}" = 1 ] || exit 0

# --- Auto mode -------------------------------------------------------------
pm_log "auto mode: polling every ${AUTO_POLL_SEC}s"
fg_pkg() {
  dumpsys activity activities 2>/dev/null | grep -m1 -E 'mResumedActivity|topResumedActivity' \
    | sed -n 's/.* \([A-Za-z0-9_.]*\)\/.*/\1/p'
}
uptime_cs() { read u _ < /proc/uptime; echo "${u%.*}${u#*.}"; }
i=0; cost=0
while :; do
  sleep "${AUTO_POLL_SEC:-5}"
  [ "$(getprop sys.producer_mode.auto_stop)" = 1 ] && { pm_log "auto mode stopped"; exit 0; }
  t0=$(uptime_cs); pkg=$(fg_pkg); t1=$(uptime_cs)
  cost=$((cost + t1 - t0)); i=$((i+1))
  if [ $i -ge 60 ]; then pm_log "auto: avg poll $((cost * 10 / i)) ms over $i polls"; i=0; cost=0; fi
  [ -n "$pkg" ] || continue
  want=off; apps | grep -qx "$pkg" && want=on
  mode=$(get_mode)
  if [ "$want" = on ] && [ "$mode" = off ]; then
    lock; SUMMARY=""; mode_on auto; unlock; pm_log "auto: ON for $pkg"
  elif [ "$want" = off ] && [ "$mode" = on ] && [ "$(cat "$PM_STATE/owner" 2>/dev/null)" = auto ]; then
    lock; mode_off auto; unlock; pm_log "auto: OFF ($pkg in front)"
  fi
done
