#!/usr/bin/env bash
set -euo pipefail

# gammastep hook API:
# $1 = event name
# for period-changed: $2 = old period, $3 = new period
# periods include: none, night, daytime, transition
# (as documented in gammastep man page) :contentReference[oaicite:5]{index=5}

if [[ "${1:-}" != "period-changed" ]]; then
  exit 0
fi

NEW="${3:-}"

# At sunset, gammastep enters "transition" and then "night".
# We want: immediate 3500K at sunset, then ramp down to 1000K by ~3 hours.
if [[ "$NEW" != "transition" && "$NEW" != "night" ]]; then
  exit 0
fi

# Prevent multiple ramps if we get both transition->night events.
LOCK="${XDG_RUNTIME_DIR:-/tmp}/gammastep-evening-ramp.lock"
if [[ -e "$LOCK" ]]; then
  exit 0
fi
trap 'rm -f "$LOCK"' EXIT
: > "$LOCK"

# Ensure immediate drop to 3500K (matches your requirement)
gammastep -O 3500 >/dev/null 2>&1 || true  # :contentReference[oaicite:6]{index=6}

# Ramp: 3500 -> 1000 over 180 minutes, step every 2 minutes.
(
  START=3500
  END=1000
  DURATION_MIN=180
  STEP_MIN=2
  STEPS=$((DURATION_MIN / STEP_MIN))

  for ((i=0; i<=STEPS; i++)); do
    # linear interpolation
    TEMP=$(( START - ( (START - END) * i / STEPS ) ))
    gammastep -O "$TEMP" >/dev/null 2>&1 || true
    sleep $((STEP_MIN * 60))
  done
) >/dev/null 2>&1 & disown

exit 0

