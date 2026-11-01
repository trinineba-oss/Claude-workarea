# CPU tweaks. Thermal is never touched here.
cpu_policies() { ls -d /sys/devices/system/cpu/cpufreq/policy* 2>/dev/null; }

# Lowest available step >= pct% of cpuinfo_max_freq.
cpu_pick_step() { # policy pct
  max=$(cat "$1/cpuinfo_max_freq" 2>/dev/null) || return 1
  want=$((max * $2 / 100))
  best=""
  for f in $(cat "$1/scaling_available_frequencies" 2>/dev/null); do
    [ "$f" -ge "$want" ] && { [ -z "$best" ] || [ "$f" -lt "$best" ]; } && best=$f
  done
  echo "${best:-$want}"
}

cpu_apply() {
  n=0; checks=""
  if [ "${CPU_MINFREQ_PCT:-0}" -gt 0 ]; then
    for p in $(cpu_policies); do
      s=$(cpu_pick_step "$p" "$CPU_MINFREQ_PCT") || continue
      sysfs_set "$p/scaling_min_freq" "$s" && { n=$((n+1)); checks="$checks $p/scaling_min_freq=$s"; }
    done
    say "CPU min freq (${CPU_MINFREQ_PCT}%): $n policies"
  fi
  if [ "${CPU_GOVERNOR_PERF:-0}" = 1 ]; then
    n=0
    for p in $(cpu_policies); do
      grep -qw performance "$p/scaling_available_governors" 2>/dev/null || { pm_log "skip: no performance gov in $p"; continue; }
      sysfs_set "$p/scaling_governor" performance && { n=$((n+1)); checks="$checks $p/scaling_governor=performance"; }
    done
    say "CPU performance governor: $n policies"
  fi
  if [ "${TOPAPP_UCLAMP_MIN:-0}" -gt 0 ]; then
    if sysfs_set /dev/cpuctl/top-app/cpu.uclamp.min "$TOPAPP_UCLAMP_MIN"; then
      say "top-app uclamp.min=$TOPAPP_UCLAMP_MIN"
    else say "top-app uclamp: not available"; fi
  fi
  # Detect vendor perf HAL / PPM overrides: re-read once, log, don't fight.
  if [ -n "$checks" ]; then
    sleep 3
    for c in $checks; do
      path=${c%=*}; want=${c##*=}; now=$(cat "$path" 2>/dev/null)
      [ "$now" = "$want" ] || { pm_log "OVERRIDE: $path is '$now', wanted '$want' (vendor perf control?)"; say "warning: $path overridden by vendor"; }
    done
  fi
}
