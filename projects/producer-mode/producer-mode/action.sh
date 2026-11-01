#!/system/bin/sh
# Magisk Action button: toggles producer mode.
MODDIR=${0%/*}
. "$MODDIR/lib/common.sh"; . "$MODDIR/lib/toggle.sh"
lock
if [ "$(get_mode)" = on ]; then mode_off manual
else mode_on manual; say "Producer mode ON"; fi
unlock
printf '%s' "$SUMMARY"
