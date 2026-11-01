# WarZone Caucasus Web Command Center

Companion live strategic dashboard developed against the **WarZone Caucasus Dynamic Sector Campaign v4.47** runtime.

**Release distinction:** The latest separately published mission file is [v4.47](../README.md#release-and-source-code-status). The web dashboard and several task-control Lua adapters were added to the repository **after** that release. Their presence on `main` does not prove that they are embedded in the downloadable v4.47 `.miz`; the mission must load the corresponding modules before these features can work.

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
- Mission task definitions, availability, briefing, status and rewards **when the task manager/bridge patch is installed**

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
  |-- GET /events  (Server-Sent Events)
  |-- POST /api/tasks/:id/accept (optional task command)
  `-- POST /api/telemetry (optional authenticated ingestion)
  |
  v
Browser Command Center
```

For public 24/7 deployment the recommended production path is:

```text
DCS -> JSON -> Node on 127.0.0.1:8787 -> Cloudflare Tunnel -> HTTPS Internet
```

## 1. Integrate the Lua bridge and optional task controls into the mission

Load `bridge/WarZoneWebBridge.lua` **after** the WarZone campaign runtime (`bc` / `WZ_SECTOR`) is initialized. The downloadable v4.47 mission release predates the repository's web-integration commits; do not assume it includes the bridge.

For **read-only telemetry**, the bridge must be embedded and executing correctly inside the running `.miz`.

For **web task acceptance**, the mission additionally needs the Lua task manager (`mission/WarZone_TaskManager.lua`), the task bridge patch (`mission/WarZone_TaskBridgePatch.lua`), the command inbox (`mission/WarZone_WebCommands.lua`) and the player-mission-board bindings (`mission/WarZone_TaskBindings.lua`). The bindings depend on existing WarZone player-mission-board functions and must be loaded after those functions are defined. All of these files exist in this repository; they are not automatically injected into an already published `.miz`.

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
| `WARZONE_COMMAND_DIR` | directory named `commands` next to the selected state file | Where the web server queues task-acceptance command files |
| `WARZONE_INGEST_TOKEN` | unset (ingest disabled) | Bearer token required for optional `POST /api/telemetry` |
| `WARZONE_MAX_INGEST_BYTES` | `2097152` | Maximum accepted telemetry POST body size in bytes |

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

**Security note:** As currently implemented, `POST /api/tasks/:id/accept` checks that the selected pilot is online and belongs to the correct coalition, but **does not authenticate the person using the browser**. Do not expose this write endpoint publicly without a separate authorization layer or route-level restriction. A public read-only dashboard can block task-acceptance POST requests at the reverse proxy.

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

## Web-based mission tasking

When the optional task-control Lua modules are installed, the dashboard can list CAP, CAS, SEAD and STRIKE tasks, display briefings and submit task-acceptance requests for pilots currently online in the corresponding coalition.

Flow:

```text
Browser -> POST /api/tasks/:id/accept -> Node.js command file
    -> DCS WZ_WEB_COMMANDS -> WZ_TASKS -> WZ_TASK_BINDINGS
    -> existing WarZone player mission board
```

An HTTP `202 Accepted` response indicates the command was **queued**, not that DCS has activated the task. Confirm the resulting task status in the updated telemetry. Without the mission-side command reader and bindings, the web request cannot activate a real mission.

## Demo-data warning

If no live DCS telemetry file is found, the web service may fall back to the committed `web/data/state.json` example. It contains **simulated** players, sectors and an `ONLINE` status for UI demonstration; this is **not evidence of a running DCS server**. For production, set `WARZONE_STATE_FILE` explicitly and check that the JSON file is being updated by DCS.

## Campaign paths

NATO:

```text
3 -> 2 -> 1 -> 6 -> 7 -> 8 -> 9 -> 10
```

RED:

```text
3 -> 4 -> 5 -> 11 -> 12 -> 13 -> 14
```
