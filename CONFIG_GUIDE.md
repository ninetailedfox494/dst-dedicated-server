# Configuration Guide

## env/.env Variables

### Required

**DST_CLUSTER_TOKEN**
- Your Klei cluster token
- Get from: https://accounts.klei.com/account/game/server
- Format: `pds-XXXXXXXXXXXX`
- No default; must be set

### Cluster Identity

| Variable | Default | Notes |
|----------|---------|-------|
| `DST_CLUSTER_NAME` | `MyDediServer` | Folder name (no spaces) |
| `DST_CLUSTER_DISPLAY_NAME` | `NineTailedFox` | Name in server browser |
| `DST_CLUSTER_PASSWORD` | (empty) | Leave empty for public |
| `DST_CLUSTER_DESCRIPTION` | `DST Server` | Description in browser |

### Gameplay

| Variable | Default | Options |
|----------|---------|---------|
| `DST_GAME_MODE` | `endless` | `endless`, `survival`, `wilderness` |
| `DST_MAX_PLAYERS` | `6` | 1–64 |
| `DST_WORLD_SIZE` | `large` | `small`, `medium`, `large` |
| `DST_PVP` | `false` | `true` or `false` |
| `DST_PAUSE_WHEN_EMPTY` | `true` | Auto-pause with no players |

### Server

| Variable | Default | Notes |
|----------|---------|-------|
| `DST_CONSOLE_ENABLED` | `true` | Enable in-game console |
| `DST_TICK_RATE` | `15` | 10–30 (higher = more CPU) |
| `DST_OFFLINE_CLUSTER` | `false` | Private (not in browser) |

## env/mods.txt Format

Workshop mod IDs, one per line:

```
# Comments start with #
2078243581   # Display Attack Range
375850593    # Extra Equip Slots

# Blank lines ignored
1207269058
```

Find mod ID from Steam Workshop URL:
```
https://steamcommunity.com/sharedfiles/filedetails/?id=2078243581
                                                           ^^^^^^^^^^^ ID
```

## Access Control Files

### env/admins.txt

Users with full admin rights:
```
KU_XXXXXXXX
KU_YYYYYYYY
```

### env/whitelist.txt

If enabled, ONLY these users can join (one ID per line).
Leave empty to allow all users.

### env/blocklist.txt

Users banned from joining (one ID per line).

Find your user ID:
- Open Don't Starve Together
- View profile
- URL: `https://steamcommunity.com/profiles/123456789`
- DST ID: `KU_` prefix + last digits

## Changing Configuration

After editing `env/.env`, reapply:

```bash
bash scripts/stop.sh
bash setup_dst_server.sh    # Regenerate config
bash scripts/start.sh
```

## World Generation

Default presets:
- Master: `DST_FOREST`
- Caves: `DST_CAVE`

To customize, edit `data/master/worldgenoverride.lua` and `data/caves/worldgenoverride.lua` manually, then restart.

## Performance Tuning

Reduce CPU usage:
```bash
# env/.env
DST_TICK_RATE="10"          # Lower = less CPU
DST_WORLD_SIZE="small"      # Smaller world = faster
```

Increase available slots:
```bash
DST_MAX_PLAYERS="12"        # Up from 6
```

## Advanced: Manual Config Edits

Direct file edits (not recommended, may be overwritten by setup script):

- `data/cluster/cluster.ini` — Cluster settings
- `data/master/server.ini` — Master network
- `data/caves/server.ini` — Caves network
- `data/master/modoverrides.lua` — Master mod settings
- `data/caves/modoverrides.lua` — Caves mod settings

Always backup before manual edits:
```bash
bash scripts/backup.sh before-editing
```

---

See `README.md` for more details.
