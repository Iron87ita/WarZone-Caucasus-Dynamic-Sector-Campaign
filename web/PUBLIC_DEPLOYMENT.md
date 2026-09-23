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
- The WEB LIVE FIX2 mission running successfully at least once
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

## 4. Public access

If the page must be visible to everyone, do not place a Cloudflare Access login policy in front of the public hostname.

The WarZone public telemetry deliberately contains strategic campaign data only. Exact enemy aircraft, SAM and ground-unit positions are not exported by the bridge.

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

A healthy response should report the web service and current telemetry state without exposing the local Windows path to `WarZoneWebState.json`.

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
