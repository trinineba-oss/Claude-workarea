# ON/OFF entry points. Caller sets MODDIR and sources common.sh first.
. "$MODDIR/lib/cpu.sh"; . "$MODDIR/lib/system.sh"; . "$MODDIR/lib/audio.sh"

mode_on() {
  if [ "$(get_mode)" = on ]; then say "Already ON (backups kept)"; return 0; fi
  pm_log "=== ON ($1) ==="
  load_config
  cpu_apply; system_apply; audio_apply
  set_mode on; echo "$1" > "$PM_STATE/owner"
  [ -n "$(ls "$PM_BK" 2>/dev/null)" ] || say "No tweaks enabled. Edit $PM_DIR/producer.conf"
}

mode_off() {
  pm_log "=== OFF ($1) ==="
  restore_all
  set_mode off; rm -f "$PM_STATE/owner"
  say "Producer mode OFF, settings restored"
}
