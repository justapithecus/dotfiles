# Gammastep (Night Light Replacement)

This module replaces KDE Night Light with **gammastep**, with:
- auto location via **GeoClue2**
- day/night temperature control
- an optional **evening ramp** hook

## Files

### Tracked config
- `config.ini` → installed to `~/.config/gammastep/config.ini`

### GeoClue2 allowlist (no agent prompts)
- `geoclue-conf.d/90-gammastep.conf` → installed to `/etc/geoclue/conf.d/90-gammastep.conf`

GeoClue uses drop-ins under `/etc/geoclue/conf.d/` and loads them in lexical order.  
The `90-` prefix makes this override load late (wins over earlier defaults).

### Optional hooks
- `hooks/99-evening-ramp.sh` → installed to `~/.config/gammastep/hooks/99-evening-ramp.sh`

Gammastep hooks are executed in lexical order.  
The `99-` prefix ensures this runs late.

## Install

### 1) Install + configure GeoClue2 (system)
This requires root because it writes `/etc/geoclue/conf.d/...`.

- Run: `gammastep/setup-geoclue.sh` (called from `install.sh`)

What it does:
- installs `geoclue2`
- installs the GeoClue allowlist drop-in for gammastep
- starts/restarts `geoclue.service` if present

Note: on openSUSE, `geoclue.service` is often **static** (D-Bus activated), so it cannot be enabled.

### 2) Install user config + hooks (user)
- Symlink `config.ini` into `~/.config/gammastep/config.ini`
- Symlink optional hooks into `~/.config/gammastep/hooks/`

## Testing

### Disable KDE Night Light
Turn off Night Light so it doesn't fight gammastep:
- System Settings → Display & Monitor → Night Light → Off

### Run in foreground
```bash
gammastep -v -c "$HOME/.config/gammastep/config.ini"

