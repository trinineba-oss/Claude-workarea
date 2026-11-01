#!/system/bin/sh
# Runs early in boot after removal; settings/dumpsys need a booted system, so wait in background.
MODDIR=${0%/*}
(
  . "$MODDIR/lib/common.sh"
  wait_boot
  pm_log "uninstall: restoring"
  restore_all boot
  rm -rf /data/adb/producer-mode
) &
