# WarZone Caucasus Web Command Center

Live strategic dashboard for **WarZone Caucasus Dynamic Sector Campaign v4.47**.

The dashboard reads the campaign directly from the real WarZone runtime state and aggregates the live `ZoneCommander` data through the campaign's `WZ_SECTOR` definitions. It exports the 14 strategic sectors, campaign progression, coalition state and active operations while DCS is running.

## Live data exported from DCS

- Server / telemetry state and mission time
- Players online and aircraft type
- All 14 WarZone strategic sectors and current ownership
- Locked / unlocked / frontline / secured sector state
- Per-sector component-zone control and geometry
- Sector level and income
- NATO / RED coalition accounts
- NATO personal-wallet aggregate
- Active `GroupCommander` patrol / attack / supply operations
- Zone / sector progression event feed
- Operation launch events

The public feed intentionally does **not** export exact enemy aircraft, SAM or ground-unit positions.

## Architecture

```text
DCS Dedicated Server
  |
  | WarZoneWebBridge (every 2 s)
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

For public 24/7 deployment the recommended production path is:

```text
DCS -> JSON -> Node on 127.0.0.1:8787 -> Cloudflare Tunnel -> HTTPS Internet
```

## 1. Install the Lua bridge in the mission

Load `bridge/WarZoneWebBridge.lua` only after the WarZone campaign runtime has been created (`bc` / `WZ_SECTOR`). The tested WEB LIVE FIX2 mission embeds the bridge in the already-loaded WarZone campaign script so it starts in the correct order.

Successful startup is logged as:

```text
[WarZoneWebBridge] LIVE telemetry started for WZ_SECTOR v4.47
```

Output file:

```text
Saved Games\<DCS instance>\WarZoneWeb\WarZoneWebState.json
```

The DCS mission scripting environment must provide `io` and `lfs` for telemetry / persistence writes.

## 2. Run the web server manually

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
$env:WARZONE_STATE_FILE="$env:USERPROFILE\Saved Games\DCS\WarZoneWeb\WarZoneWebState.json"
node server.js
```

For a simple Windows one-click launch, double-click:

```text
AVVIA_WARZONE_WEB.cmd
```

## Environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `PORT` | `8787` | HTTP port |
| `HOST` | `0.0.0.0` | Bind address |
| `WARZONE_STATE_FILE` | auto-detect / demo state | Exact DCS telemetry JSON |
| `WARZONE_STALE_MS` | `15000` | Mark live DCS telemetry offline after this age |
| `WARZONE_HEALTH_DETAILS` | `0` | Set to `1` only for local debugging to expose the telemetry file path in `/api/health` |

## 3. Install as a Windows 24/7 startup task

Close any manually running `npm start` process, then open **PowerShell as Administrator** in `web` and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\windows\Install-WarZoneWebService.ps1
```

This creates the `WarZone Web Command Center` Scheduled Task, runs it as `SYSTEM`, starts it at Windows boot, binds the site to `127.0.0.1:8787`, and restarts Node if the process exits.

Logs:

```text
web\logs\warzone-web.log
web\logs\warzone-web-error.log
```

Uninstall:

```powershell
.\windows\Uninstall-WarZoneWebService.ps1
```

## 4. Publish it to the Internet

See **[PUBLIC_DEPLOYMENT.md](PUBLIC_DEPLOYMENT.md)**.

The recommended public deployment is a named **Cloudflare Tunnel** installed as a Windows service and mapped to:

```text
http://127.0.0.1:8787
```

Use a hostname such as:

```text
https://warzone.example.com
```

Do **not** port-forward `8787` and do not expose the DCS Saved Games directory or scripting interfaces to the Internet.

## Operational map

The bridge aggregates the actual campaign strategic sector definitions in `WZ_SECTOR`. Each sector can contain multiple component zones; the browser uses their geographic centers / geometry to plot the strategic campaign while keeping tactical enemy-unit positions private.

## Campaign paths

NATO:

```text
3 -> 2 -> 1 -> 6 -> 7 -> 8 -> 9 -> 10
```

RED:

```text
3 -> 4 -> 5 -> 11 -> 12 -> 13 -> 14
```
