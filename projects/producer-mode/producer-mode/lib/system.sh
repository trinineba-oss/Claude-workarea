system_apply() {
  if [ "${DOZE_WHITELIST:-0}" = 1 ]; then
    n=0; for a in $(apps); do doze_add "$a" && n=$((n+1)); done
    say "Doze whitelist: $n apps"
  fi
  if [ "${ANIMATIONS_OFF:-0}" = 1 ]; then
    for k in window_animation_scale transition_animation_scale animator_duration_scale; do
      setting_set global $k 0
    done
    say "Animations off"
  fi
  [ "${WIFI_OFF:-0}" = 1 ] && { radio_set wifi disable; say "Wi-Fi off"; }
  [ "${BLUETOOTH_OFF:-0}" = 1 ] && { radio_set bluetooth disable; say "Bluetooth off"; }
  return 0
}
