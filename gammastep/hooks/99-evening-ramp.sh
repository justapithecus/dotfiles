#!/usr/bin/env bash
set -euo pipefail

# gammastep hook API:
# $1 = event name
# for period-changed: $2 = old period, $3 = new period
# periods include: none, night, daytime, transition

if [[ "${1:-}" != "period-changed" ]]; then
  exit 0
fi

NEW="${3:-}"

# At sunset, gammastep enters "transition" and then "night".
# We want: immediate 3500K at sunset, then ramp down to 1000K by ~3 hours.
if [[ "$NEW" != "transition" && "$NEW" != "night" ]]; then
  exit 0
fi

# Prevent multiple ramps (transition -> night) by locking per calendar day.
LOCK_DIR="${XDG_RUNTIME_DIR:-/tmp}"
LOCK="${LOCK_DIR}/gammastep-evening-ramp.$(date +%F).lock"
if [[ -e "$LOCK" ]]; then
  exit 0
fi
: > "$LOCK"

# Ensure immediate drop to 3500K
gammastep -O 3500 >/dev/null 2>&1 || true

# Ramp: 3500 -> 1000 over 180 minutes, step every 2 minutes.
(
  START=3500
  END=1000
  DURATION_MIN=180
  STEP_MIN=2
  STEPS=$((DURATION_MIN / STEP_MIN))

  for ((i=0; i<=STEPS; i++)); do
    TEMP=$(( START - ( (START - END) * i / STEPS ) ))
    gammastep -O "$TEMP" >/dev/null 2>&1 || true
    sleep $((STEP_MIN * 60))
  done
) >/dev/null 2>&1 &

