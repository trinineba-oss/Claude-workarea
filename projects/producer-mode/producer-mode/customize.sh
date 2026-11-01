# Install-time checks. Sourced by Magisk's installer.
API=$(getprop ro.build.version.sdk)
[ "${API:-0}" -lt 30 ] && abort "! Android 11+ required (found API $API)"
case "$ARCH" in arm64|arm) ;; *) abort "! Unsupported arch: $ARCH";; esac
ui_print "- $(getprop ro.product.model) / $(getprop ro.board.platform), API $API"
mkdir -p /data/adb/producer-mode/state
for f in producer.conf apps.list; do
  [ -f /data/adb/producer-mode/$f ] || cp "$MODPATH/config/$f" /data/adb/producer-mode/$f
done
ui_print "- Config: /data/adb/producer-mode/producer.conf"
ui_print "- All tweaks are OFF by default. Enable one, measure, repeat."
ui_print "- Thermal protection is never modified."
[ "${MAGISK_VER_CODE:-0}" -lt 27000 ] && ui_print "! Magisk < v27: no Action button; run action.sh via su"
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
