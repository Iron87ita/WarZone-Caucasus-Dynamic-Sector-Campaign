# WarZone Caucasus – Dynamic Sector Campaign

**Latest mission release: v4.49 English (2026-11-04) · DCS World · Caucasus · Dynamic PvE / PvPvE**

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
- Friendly AI escorts and opposing AI intercept/attack tasks
- Direct SEAD attacks with mixed weapons and bounded retries
- Explicit bingo-fuel return to the nearest friendly runway
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

Enemy air and ground dispatcher activity scale with the total number of active players. In v4.49, AUTO allows up to 3 combat flights and 2 columns per coalition for solo/duo play, increasing to 8 combat flights and 4 columns at 7+ players. Up to 1 AWACS and 2 tankers are available in addition. Zone defenses retain their intended operational strength.

Open **F10 > WARZONE MISSIONS** for six entries: Current task / F10 track, Cancel task, Friendly AI, Enemy AI, Sector missions and Reports / help. Coalition tempo, reinforcement and column controls are under **Friendly AI > Operations**.

Choose **Friendly AI** to protect a live friendly flight, or **Enemy AI** to intercept/attack an opposing group. Standard escort requires five minutes airborne within 5 NM; cargo escort requires confirmed delivery and at least 60 seconds nearby. Assigned-group tracks and catalogs update every 30 seconds. Personal bonuses require safe RTB.

Combat AI now receives actual role tasking after takeoff. SEAD uses direct attacks on individual defenses, prioritizes radars and carries ARM plus guided ground weapons for silent/non-radar targets. Attempts are bounded. At **30% internal fuel**, or earlier when measured return reserve requires it, the lowest-fuel aircraft triggers group RTB to the **nearest friendly airport**. Attack orders are cleared and cannot reactivate during RTB.

See the [English AI control and task guide](docs/AI_CONTROL_AND_TASKS.md), [v4.49 release notes](docs/releases/v4.49.md) and [validation report](docs/releases/v4.49-validation.txt).

## Persistence

Campaign progress is saved between mission and server restarts. Version 4.47 adds a dedicated persistence layer for assets purchased through the player shop.

Purchased units now retain:

- Surviving members of partially damaged groups
- Saved position and heading
- Coalition and country information
- MQ-9 / JTAC deployment state
- Permanent removal after destruction

Shop units remain separate from the standard ZoneCommander respawn tables, preserving zone defence, capture, counterattack and garrison behaviour.

Version 4.49 retains the supplied mission's persistence filename and save schema. No save migration is introduced; back up an existing save before upgrading. AI tempo selections and live AI task assignments apply to the current mission session.

## Release and source-code status

The current downloadable mission is [v4.49 English](https://github.com/Iron87ita/WarZone-Caucasus-Dynamic-Sector-Campaign/releases/tag/v4.49), based on the author's supplied V4.49 mission. It includes friendly escorts, enemy intercept/attack tasks, compact F10 menus, actual combat role tasking, direct SEAD attacks and nearest-base bingo RTB. Menus, briefings and task notifications are in English. See the [changelog](CHANGELOG.md).

The `main` branch also contains [Web Command Center source code](web/README.md) and Lua integrations for telemetry and web-based mission acceptance. These remain **separate source integrations and are not embedded in the v4.49 `.miz`**.

The published copy passes ZIP integrity checks, DCS Lua 5.1 compilation and **49 simulated activity/combat scenarios**. These checks do not establish live weapon hits, taxi behavior, landing or server performance; those require an in-simulator session. The supplied mission table, warehouses and other resources are preserved; only briefing/version metadata is aligned before publication.

Historical packaging note: the older v4.45 release includes a `V4_55.miz` filename whose published SHA-256 matches the v4.45 asset. That filename does not establish a newer build.

## Installation and update

1. Download `WarZone_IRON87_CAUCASO_DYNAMIC_SECTOR_MODERN_V4_49.miz` from the [latest GitHub release](https://github.com/Iron87ita/WarZone-Caucasus-Dynamic-Sector-Campaign/releases/latest).
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


