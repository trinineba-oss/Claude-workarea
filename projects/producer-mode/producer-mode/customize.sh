# Install-time checks. Sourced by the Magisk / KernelSU / APatch installer.
API=$(getprop ro.build.version.sdk)
[ "${API:-0}" -lt 28 ] && abort "! Android 9+ required (found API $API)"
# Pure shell, no binaries: any CPU architecture works.
ui_print "- $(getprop ro.product.manufacturer) $(getprop ro.product.model) / $(getprop ro.board.platform), API $API, $ARCH"
mkdir -p /data/adb/producer-mode/state
for f in producer.conf apps.list; do
  [ -f /data/adb/producer-mode/$f ] || cp "$MODPATH/config/$f" /data/adb/producer-mode/$f
done
# Capability report: what this device supports. Unsupported tweaks are skipped at runtime.
PM_STATE=/data/adb/producer-mode/state
. "$MODPATH/lib/cpu.sh"; . "$MODPATH/lib/audio.sh"; . "$MODPATH/lib/detect.sh"
caps_report > "$PM_STATE/caps.txt" 2>/dev/null
while IFS= read -r l; do ui_print "  $l"; done < "$PM_STATE/caps.txt"
ui_print "- Config: /data/adb/producer-mode/producer.conf"
ui_print "- All tweaks are OFF by default. Enable one, measure, repeat."
ui_print "- Thermal protection is never modified."
if [ "$(root_manager)" = magisk ] && [ "${MAGISK_VER_CODE:-0}" -lt 27000 ]; then
  ui_print "! Magisk < v27: no Action button; run action.sh via su"
fi
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
