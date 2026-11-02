# WarZone Caucasus – Dynamic Sector Campaign

**Latest mission release: v4.48 English (2026-11-02) · DCS World · Caucasus · Dynamic PvE / PvPvE**

![WarZone Caucasus logo](assets/images/WarZoneLogo.png)

WarZone Caucasus is a persistent single-player and multiplayer campaign by **IRON87ITA**, built around progressive sector warfare. The operational front expands as sectors are captured, creating a focused battlefield while avoiding unnecessary AI activity across the entire map.

## Highlights

- Fourteen strategic sectors
- Independent NATO and RED campaign paths
- Persistent campaign progression
- Dynamic sector activation
- Player-scaled enemy air forces
- CAP, BARCAP, CAS, SEAD and strike missions
- Enhanced adaptive AI activity with coalition-specific F10 tempo controls
- Dynamic player tasks against newly spawned enemy AI groups
- Moving ground columns with continued advances and bounded route recovery
- Dynamic AI commander and F10 commander menu
- Player shop and support-purchasing system
- Persistent purchased ground units and MQ-9/JTAC assets
- Friendly-zone and map-marker deployment
- Forward helicopter operations, FARPs and FOB support
- Tanker, AWACS, JTAC and GCI support
- Integrated briefing and kneeboard
- Single-player and multiplayer compatible

## Campaign structure

### NATO progression

```text
3 → 2 → 1 → 6 → 7 → 8 → 9 → 10
```

### RED progression

```text
3 → 4 → 5 → 11 → 12 → 13 → 14
```

Only the current front and previously unlocked sectors remain active. The campaign covers the Northern Caucasus, Mozdok, Krasnodar, the Black Sea coast, Georgia and Abkhazia.

## Dynamic operations

Players can launch or support multiple mission types through the campaign systems:

- Combat Air Patrol and BARCAP
- Close Air Support
- Suppression of Enemy Air Defences
- Strike missions
- Dynamic counterattacks
- Ground-force purchases and deployment
- MQ-9 / JTAC support
- Tanker and AWACS operations

Enemy air and ground dispatcher activity scale with the total number of active players. In v4.48, AUTO allows up to 3 combat flights and 2 columns per coalition for solo/duo play, increasing to 8 combat flights and 4 columns at 7+ players. Up to 1 AWACS and 2 tankers are available in addition. Zone defenses retain their intended operational strength.

Open **F10 > WARZONE MISSIONS > AI CONTROL** to select AUTO, LOW, NORMAL, HIGH, OFFENSIVE or pause new launches; request CAP/CAS/SEAD, ground or naval reinforcements; and halt or resume campaign columns. Each coalition controls its own AI.

Open **F10 > WARZONE MISSIONS > DYNAMIC AI TASKS > Refresh target list** to accept tasks against live enemy spawns. For example, a BLUE SEAD flight becomes a RED interception task. Briefings identify the exact target group, and assigned-group F10 tracks update every 30 seconds. Destroy all target units; withdrawal/despawn does not count as success. Task bonuses require an assigned-group kill and safe RTB.

See the [English AI control and task guide](docs/AI_CONTROL_AND_TASKS.md) and [v4.48 release notes](docs/releases/v4.48.md) for limits, procedures and validation details.

## Persistence

Campaign progress is saved between mission and server restarts. Version 4.47 adds a dedicated persistence layer for assets purchased through the player shop.

Purchased units now retain:

- Surviving members of partially damaged groups
- Saved position and heading
- Coalition and country information
- MQ-9 / JTAC deployment state
- Permanent removal after destruction

Shop units remain separate from the standard ZoneCommander respawn tables, preserving zone defence, capture, counterattack and garrison behaviour.

Version 4.48 retains the persistence filename and save schema of the supplied V4.47 base. No save migration is introduced; back up an existing save before upgrading. AI tempo selections and live AI task assignments apply to the current mission session.

## Release and source-code status

The current downloadable mission is [v4.48 English](https://github.com/Iron87ita/WarZone-Caucasus-Dynamic-Sector-Campaign/releases/tag/v4.48), built from the supplied V4.47 Iron87Ita mission. It includes the enhanced AI activity, F10 AI controls and dynamic AI tasks described above. All mission menus, briefings, notifications and status messages are in English.

The `main` branch also contains [Web Command Center source code](web/README.md) and Lua integrations for telemetry and web-based mission acceptance. These are **separate source integrations and are not embedded in the v4.48 `.miz`**. See the [changelog](CHANGELOG.md) for the distinction between mission releases and repository-only changes.

All embedded Lua scripts and mission tables compile with DCS `lua.dll`, and simulated DCS API checks pass. An in-simulator flight session has not been run; actual taxi behavior, terrain pathfinding and server performance still require testing. Existing reference artwork is in English; for current AI limits, use the updated briefing and F10 status.

Historical packaging note: the older v4.45 release includes a `V4_55.miz` filename whose published SHA-256 matches the v4.45 asset. That filename does not establish a newer build.

## Installation and update

1. Download `WarZone_IRON87_CAUCASO_DYNAMIC_SECTOR_MODERN_V4_48_Iron87Ita_EN.miz` from the [latest GitHub release](https://github.com/Iron87ita/WarZone-Caucasus-Dynamic-Sector-Campaign/releases/latest).
2. Stop the current WarZone mission or dedicated server.
3. Replace the previous mission with the new `.miz` file.
4. Back up and keep the existing compatible persistence file.
5. Start the mission and continue the campaign.

No campaign reset is required when upgrading from a compatible version.

## Community

- YouTube: [@Iron87Ita](https://www.youtube.com/@Iron87Ita)
- Discord: `iron87`

Feedback and campaign reports are welcome through [GitHub Issues](https://github.com/Iron87ita/WarZone-Caucasus-Dynamic-Sector-Campaign/issues).

## Disclaimer

This is an unofficial community mission for DCS World. DCS and related product names are trademarks of Eagle Dynamics SA. This project is not affiliated with or endorsed by Eagle Dynamics.

