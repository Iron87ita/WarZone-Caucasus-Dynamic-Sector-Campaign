# WarZone Caucasus Web Command Center

Live strategic dashboard for **WarZone Caucasus Dynamic Sector Campaign v4.47**.

The dashboard reads the campaign directly from the real `BattleCommander` / `ZoneCommander` runtime state. It does not require sector names to be hardcoded: sectors, ownership, front lines, trigger-zone coordinates and campaign connections are discovered automatically while DCS is running.

## Live data exported from DCS

- Server / telemetry state and mission time
- Players online and aircraft type
- All WarZone sectors and current ownership
- Frontline detection using `BattleCommander.connections`
- Sector level, income and active/destroyed state
- Trigger-zone center / polygon geometry converted to latitude/longitude
- NATO / RED coalition accounts
- NATO personal-wallet aggregate
- Active `GroupCommander` patrol / attack / supply operations
- Zone-capture event feed
- Operation launch events

The public feed intentionally does **not** export exact enemy aircraft, SAM or ground-unit positions.

## Architecture

```text
DCS Dedicated Server
  |
  | WarZoneWebBridge.lua (every 2 s)
  v
Saved Games\<DCS instance>\WarZoneWeb\WarZoneWebState.json
  |
  v
Node.js web/server.js
  |-- GET /api/state
  |-- GET /api/health
  `-- GET /events  (Server-Sent Events)
  |
  v
Browser Command Center
```

## 1. Install the Lua bridge in the mission

Add `bridge/WarZoneWebBridge.lua` to the `.miz` and load it **after the WarZone Commander script/classes have been loaded**.

The bridge starts automatically when the file is executed.

WarZone v4.47 already uses persistence, so a server configured for campaign persistence should already have the required `io` / `lfs` mission-scripting access. If `io` or `lfs` are unavailable, the bridge logs:

```text
[WarZoneWebBridge] io/lfs unavailable - telemetry disabled
```

Output file:

```text
Saved Games\<DCS instance>\WarZoneWeb\WarZoneWebState.json
```

No modification to `ZoneCommander:capture()` or the WarZone save format is required.

## 2. Run the web server

Requires **Node.js 20+**. No npm packages are required.

```powershell
cd web
npm start
```

Open:

```text
http://localhost:8787
```

On Windows the server automatically checks common DCS Saved Games locations:

```text
DCS.openbeta_server
DCS.server
DCS.openbeta
DCS
```

You can always specify the exact file explicitly:

```powershell
$env:WARZONE_STATE_FILE="$env:USERPROFILE\Saved Games\DCS.openbeta_server\WarZoneWeb\WarZoneWebState.json"
node server.js
```

## Environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `PORT` | `8787` | HTTP port |
| `HOST` | `0.0.0.0` | Bind address |
| `WARZONE_STATE_FILE` | auto-detect / demo state | Exact DCS telemetry JSON |
| `WARZONE_STALE_MS` | `15000` | Mark live DCS telemetry offline after this age |

## Operational map

The bridge uses the actual WarZone `CustomZone` data. For each strategic zone it exports the trigger-zone center and, when available, polygon vertices. DCS local coordinates are converted with `coord.LOtoLL()`.

The browser then plots the campaign topology without any external map library. `BattleCommander.connections` are rendered as links between sectors and frontline sectors receive a highlighted ring.

If geographic coordinates are unavailable, the UI automatically falls back to a topology layout.

## Campaign paths

NATO:

```text
3 -> 2 -> 1 -> 6 -> 7 -> 8 -> 9 -> 10
```

RED:

```text
3 -> 4 -> 5 -> 11 -> 12 -> 13 -> 14
```

## Production publishing

For an Internet-facing server, put the Node process behind a reverse proxy such as Caddy or Nginx and expose only HTTPS (`443`). Do not expose DCS scripting ports or the Saved Games directory to the Internet.
