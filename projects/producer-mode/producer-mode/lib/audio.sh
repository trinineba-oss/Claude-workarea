# Experimental audio tweaks. Never edits vendor audio XML.

# Report whether audioserver's fast threads are already SCHED_FIFO. Read-only.
audio_check_rt() {
  pid=$(pidof audioserver) || { pm_log "audioserver not running"; return; }
  ps -T -p "$pid" -o tid,cls,rtprio,comm 2>/dev/null | grep -i -E 'fast|AudioOut|TimeCheck|FF' >> "$PM_LOG"
  if ps -T -p "$pid" -o cls,comm 2>/dev/null | grep -i fast | grep -q FF; then
    pm_log "audioserver fast threads are SCHED_FIFO: nothing to do"
  else
    pm_log "audioserver: no SCHED_FIFO fast thread seen (only logged, not changed)"
  fi
}

audio_mmap_supported() {
  dumpsys media.audio_flinger 2>/dev/null | grep -qi mmap && return 0
  [ -n "$(getprop aaudio.mmap_policy)" ] && return 0
  return 1
}

audio_apply() {
  restart=0
  if [ "${AUDIO_MMAP:-0}" = 1 ]; then
    if audio_mmap_supported; then
      prop_set aaudio.mmap_policy 2
      prop_set aaudio.mmap_exclusive_policy 2
      say "AAudio MMAP policy=2"; restart=1
    else say "AAudio MMAP: HAL shows no MMAP support, skipped"; fi
  fi
  if [ "${AUDIO_STANDBY_MS:-0}" -gt 0 ]; then
    prop_set ro.audio.flinger_standbytime_ms "$AUDIO_STANDBY_MS"
    say "flinger standby=${AUDIO_STANDBY_MS}ms"; restart=1
  fi
  if [ $restart = 1 ]; then
    if [ "${AUDIO_RESTART:-0}" = 1 ]; then
      killall audioserver 2>/dev/null; say "audioserver restarted"
    else say "(audio props apply after audioserver restart / app restart)"; fi
  fi
  audio_check_rt
}
