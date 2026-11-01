# WarZone Web - 24/7 Public Deployment on Windows

Recommended production layout:

```text
DCS Dedicated Server
  -> WarZoneWebState.json
  -> Node.js Command Center (127.0.0.1:8787)
  -> Cloudflare Tunnel service
  -> HTTPS public hostname
  -> Players / browsers
```

The Node process is intentionally bound to loopback for this deployment. Do not expose port `8787` directly on the router. Do not expose the DCS Saved Games directory or mission-scripting interfaces to the Internet.

## 1. Install the WarZone web process as a Windows startup task

Requirements:

- Node.js 20+
- A WarZone `.miz` that actually loads the Lua telemetry bridge and has successfully exported a live state at least once (the published v4.47 `.miz` must **not** be assumed to contain the later web integration)
- `WarZoneWebState.json` present in the DCS Saved Games folder

Close any manually running `npm start` window first.

Open **PowerShell as Administrator** in the `web` directory and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\windows\Install-WarZoneWebService.ps1
```

The installer:

- finds the live `WarZoneWebState.json`
- creates the `WarZone Web Command Center` Scheduled Task
- runs it as `SYSTEM`
- starts it automatically at Windows boot
- binds Node to `127.0.0.1:8787`
- restarts Node if the process exits
- writes logs to `web\logs`

Verify locally:

```text
http://127.0.0.1:8787
http://127.0.0.1:8787/api/health
```

To remove the startup task:

```powershell
.\windows\Uninstall-WarZoneWebService.ps1
```

## 2. Create a production Cloudflare Tunnel

A production tunnel requires a domain managed by Cloudflare.

In the Cloudflare dashboard:

1. Open **Networking -> Tunnels**.
2. Create a new Cloudflare Tunnel.
3. Select the Windows connector.
4. On the DCS server, open Command Prompt as Administrator and run the `cloudflared.exe service install <TUNNEL_TOKEN>` command supplied by the Cloudflare dashboard.
5. Add a **Published application** route.
6. Choose a public hostname, for example:

```text
warzone.example.com
```

7. Set the service URL to:

```text
http://127.0.0.1:8787
```

8. Save the route.

The site should then be available at:

```text
https://warzone.example.com
```

No inbound router port-forward is required for the web dashboard when using Cloudflare Tunnel.

## 3. Important: use a named production tunnel

Do not use a temporary `trycloudflare.com` Quick Tunnel for WarZone production. The dashboard uses Server-Sent Events (`/events`) for live updates, and Cloudflare documents Quick Tunnels as development-only and not supporting SSE.

Use a normal named tunnel installed as a Windows service.

## 4. Public access and task-control security

For a **public read-only dashboard**, the site may be accessible without a Cloudflare Access login. Public telemetry contains strategic campaign data only; exact enemy aircraft, SAM and ground-unit positions are not exported by the bridge.

**However, the current Node.js task-acceptance endpoint (`POST /api/tasks/:id/accept`) has no browser-user authentication.** It checks only that the selected DCS pilot is online, that the task is available, and that the player's coalition matches. If published without access restrictions, another visitor could submit a command on behalf of an online pilot.

**Do not expose the task-acceptance POST route to anonymous visitors.** Restrict it using your reverse proxy, access gateway or application authentication. If you want public read-only monitoring, block `POST /api/tasks/*/accept` at the edge while leaving the telemetry GET routes available. This is an operational requirement until application-level authorization is implemented.

The optional `POST /api/telemetry` endpoint is separate and requires `WARZONE_INGEST_TOKEN` to be configured; never publish that token.

## 5. Firewall / router

For the web dashboard:

- Do not port-forward `8787`.
- Do not create a public Windows Firewall inbound rule for `8787`.
- `cloudflared` makes the outbound connection to Cloudflare.
- The DCS multiplayer port remains separate from the web deployment.

## 6. Health checks

Local:

```text
http://127.0.0.1:8787/api/health
```

Public:

```text
https://warzone.example.com/api/health
```

The health endpoint reports the web process and the current telemetry status without exposing the local Windows path to `WarZoneWebState.json` by default. **`ok: true` only confirms that Node.js responded**; it does not prove a DCS mission is online.

If the service is using the repository's bundled `web/data/state.json`, it can display **sample** `ONLINE` data without a running DCS server. For public deployment, configure `WARZONE_STATE_FILE` to a real DCS telemetry file and confirm its update timestamps.

## 7. Logs

WarZone web process:

```text
web\logs\warzone-web.log
web\logs\warzone-web-error.log
```

Cloudflare Tunnel runs as its own Windows service and can be inspected through Windows Services / Service Control Manager and Cloudflare's tunnel dashboard.

## 8. Boot recovery

After a Windows reboot the intended sequence is:

```text
Windows starts
  -> WarZone Web Scheduled Task starts
  -> Node listens on 127.0.0.1:8787
  -> cloudflared Windows service connects to Cloudflare
  -> DCS Dedicated Server starts / mission loads
  -> WarZoneWebState.json begins updating
  -> public dashboard changes from OFFLINE to ONLINE
```

The web process can start before DCS. It will automatically begin serving live data as soon as the telemetry file becomes current.
