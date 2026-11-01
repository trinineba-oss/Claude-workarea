# Shared helpers. POSIX sh (Magisk BusyBox ash). Sourced, never executed.
PM_DIR=/data/adb/producer-mode
PM_STATE=$PM_DIR/state
PM_BK=$PM_STATE/backup
PM_LOG=$PM_DIR/log.txt
PM_LOG_MAX=262144
mkdir -p "$PM_BK" 2>/dev/null

SUMMARY=""
say() { SUMMARY="$SUMMARY$1
"; pm_log "$1"; }

pm_log() {
  if [ -f "$PM_LOG" ]; then
    sz=$(wc -c < "$PM_LOG" 2>/dev/null)
    [ "${sz:-0}" -gt "$PM_LOG_MAX" ] && mv -f "$PM_LOG" "$PM_LOG.old"
  fi
  echo "$(date '+%m-%d %H:%M:%S') [$$] $*" >> "$PM_LOG"
}

load_config() {
  . "$MODDIR/config/producer.conf"
  [ -f "$PM_DIR/producer.conf" ] && . "$PM_DIR/producer.conf"
  APPS_LIST="$MODDIR/config/apps.list"
  [ -f "$PM_DIR/apps.list" ] && APPS_LIST="$PM_DIR/apps.list"
}

apps() { grep -v -e '^[[:space:]]*#' -e '^[[:space:]]*$' "$APPS_LIST" 2>/dev/null | tr -d ' \r'; }

get_mode() { cat "$PM_STATE/mode" 2>/dev/null || echo off; }
set_mode() { echo "$1" > "$PM_STATE/mode"; }

# Simple lock so the Action button and the auto-mode loop never interleave.
lock() {
  n=0
  while ! mkdir "$PM_STATE/lock" 2>/dev/null; do
    n=$((n+1)); [ $n -ge 30 ] && { pm_log "lock: stale, breaking"; rm -rf "$PM_STATE/lock"; }
    sleep 1
  done
}
unlock() { rm -rf "$PM_STATE/lock"; }

# --- Backups -------------------------------------------------------------
# One file per changed item in $PM_BK. Line 1: type, line 2: target, line 3: original value.
# A backup is written only if none exists, so applying twice never loses the original.
bk_key() { echo "$1_$2" | tr -c 'A-Za-z0-9_.\n-' '_'; }

bk_save() { # type target value
  f="$PM_BK/$(bk_key "$1" "$2")"
  [ -f "$f" ] && return 0
  printf '%s\n%s\n%s\n' "$1" "$2" "$3" > "$f"
}

# sysfs: probe, back up, write, verify. Returns 0 on success.
sysfs_set() { # path value
  p=$1; v=$2
  if [ ! -e "$p" ]; then pm_log "skip: $p missing"; return 1; fi
  if [ ! -w "$p" ]; then pm_log "skip: $p not writable"; return 1; fi
  old=$(cat "$p" 2>/dev/null)
  bk_save sysfs "$p" "$old"
  if ! echo "$v" > "$p" 2>/dev/null; then pm_log "fail: write '$v' > $p"; return 1; fi
  now=$(cat "$p" 2>/dev/null)
  [ "$now" = "$v" ] || pm_log "note: $p reads '$now' after writing '$v'"
  pm_log "set $p: '$old' -> '$v'"
  return 0
}

setting_set() { # namespace key value
  old=$(settings get "$1" "$2" 2>/dev/null)
  bk_save setting "$1 $2" "$old"
  settings put "$1" "$2" "$3" && pm_log "settings $1 $2: '$old' -> '$3'"
}

prop_set() { # name value
  old=$(getprop "$1")
  bk_save prop "$1" "$old"
  if command -v resetprop >/dev/null 2>&1; then resetprop "$1" "$2"
  else
    case $1 in ro.*) pm_log "skip: $1 needs resetprop"; return 1;; esac
    setprop "$1" "$2"
  fi && pm_log "prop $1: '$old' -> '$2'"
}

doze_add() { # pkg
  if dumpsys deviceidle whitelist 2>/dev/null | grep -q ",$1,"; then
    pm_log "doze: $1 already whitelisted, leaving alone"; return 0
  fi
  pm list packages 2>/dev/null | grep -qx "package:$1" || { pm_log "doze: $1 not installed"; return 1; }
  bk_save doze "$1" "absent"
  dumpsys deviceidle whitelist "+$1" >/dev/null 2>&1 && pm_log "doze: +$1"
}

radio_set() { # wifi|bluetooth enable|disable
  case $1 in wifi) k=wifi_on;; bluetooth) k=bluetooth_on;; esac
  old=$(settings get global $k 2>/dev/null)
  bk_save radio "$1" "$old"
  svc "$1" "$2" 2>/dev/null || cmd "${1}_manager" "$2" 2>/dev/null
  pm_log "radio $1 -> $2 (was $k=$old)"
}

# Restore everything. With "boot", runtime-only items (sysfs, props) are dropped
# instead of written back: a reboot has already reset them.
restore_all() {
  for f in "$PM_BK"/*; do
    [ -f "$f" ] || continue
    t=$(sed -n 1p "$f"); tg=$(sed -n 2p "$f"); v=$(sed -n 3p "$f")
    case "$t" in
      sysfs)
        [ "$1" = boot ] || { echo "$v" > "$tg" 2>/dev/null && pm_log "restored $tg = '$v'" || pm_log "restore failed: $tg"; } ;;
      prop)
        if [ "$1" != boot ]; then
          if ! command -v resetprop >/dev/null 2>&1; then setprop "$tg" "$v"
          elif [ -z "$v" ]; then resetprop --delete "$tg" 2>/dev/null; else resetprop "$tg" "$v"; fi
          pm_log "restored prop $tg = '$v'"
        fi ;;
      setting)
        ns=${tg%% *}; k=${tg#* }
        if [ "$v" = null ] || [ -z "$v" ]; then settings delete "$ns" "$k" >/dev/null 2>&1
        else settings put "$ns" "$k" "$v"; fi
        pm_log "restored settings $ns $k = '$v'" ;;
      doze)
        dumpsys deviceidle whitelist "-$tg" >/dev/null 2>&1; pm_log "doze: -$tg" ;;
      radio)
        [ "$v" = 0 ] || { svc "$tg" enable 2>/dev/null || cmd "${tg}_manager" enable 2>/dev/null; pm_log "radio $tg re-enabled"; } ;;
    esac
    rm -f "$f"
  done
}

wait_boot() { until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done; }
