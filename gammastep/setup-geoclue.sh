#!/usr/bin/env bash
set -euo pipefail

echo "▶ Installing GeoClue2"
zypper -n install geoclue2

echo "▶ Installing GeoClue override drop-in"
install -d -m 0755 /etc/geoclue/conf.d
install -m 0644 "$(dirname "$0")/geoclue-conf.d/90-gammastep.conf" /etc/geoclue/conf.d/90-gammastep.conf

# geoclue.service is often static / D-Bus activated; start if available, don’t enable
systemctl start geoclue.service 2>/dev/null || true
systemctl restart geoclue.service 2>/dev/null || true

echo "▶ GeoClue2 configured for gammastep"

