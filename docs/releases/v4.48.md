# WarZone Caucasus v4.48

## Enhanced AI Activity, F10 Control & Dynamic AI Tasks

Version **4.48** increases battlefield activity and lets players control their coalition's AI tempo from F10. Newly spawned enemy AI groups become concrete player objectives: for example, a **BLUE SEAD flight creates an interception task for RED**, and a RED flight creates the corresponding BLUE task.

This release is built from the supplied **V4.47 Iron87Ita mission**. All mission menus, briefings, task descriptions, notifications and status messages are in **English**.

### New: F10 AI control

Open **F10 > WARZONE MISSIONS > AI CONTROL** to:

- View the current activity profile, limits and active groups.
- Select **AUTO, LOW, NORMAL, HIGH, OFFENSIVE**, or **NEW LAUNCHES PAUSED**.
- Request **CAP, CAS, SEAD, ground columns or a naval raid**.
- Halt active campaign columns and resume their movement.

Each coalition controls its own AI. Settings are shared by that coalition's players and reset to AUTO when the mission restarts. Pausing suspends new launches while active groups continue their missions. Requests remain subject to traffic limits, unlocked sectors, base ownership and parking availability. An empty server does not launch new groups.

### New: tasks against enemy AI spawns

Open **F10 > WARZONE MISSIONS > DYNAMIC AI TASKS > Refresh target list**, select an entry under **ENEMY GROUP LIST**, read **Briefing / position**, then **Accept task**.

- Eligible spawns include SEAD, CAS, CAP/BARCAP, AWACS, tankers, cargo, recon aircraft, ground columns, dynamic SAM defenses and ships.
- Task briefings identify the exact group and show coordinates, bearing/range, altitude, speed and surviving unit count. Origin and destination are included when available.
- The assigned group's F10 tracking marker updates every **30 seconds**.
- One AI task is available per player group, with one assigned group per target. These tasks can run alongside existing territorial missions.
- All units in the target group must be destroyed. Withdrawal or despawn closes the task without success.
- A task bonus requires at least one kill credited to a player in the assigned group. It is added to pending earnings and redeemed after safe RTB under existing WarZone rules.
- Other-forces-only kills do not award the assigned group a bonus. Disconnecting or starting a new life releases the previous assignment.
- The target catalog is paginated and refreshed on request. Initial groups, inactive templates, human groups and CSAR survivors are excluded from new-spawn tasks.

### Increased AI activity

AUTO uses the following upper limits **per coalition** while at least one human is present:

| Total human players | Combat flights | Ground columns |
| --- | ---: | ---: |
| 1–2 | 3 | 2 |
| 3–4 | 4 | 3 |
| 5–6 | 6 | 3 |
| 7+ | 8 | 4 |

Up to **1 AWACS and 2 tankers per coalition** are available in addition. With at least three combat slots, capacity is shared between CAP, CAS and SEAD so early CAP launches cannot occupy every slot.

Manual limits are LOW: **2 flights / 1 column**, NORMAL: **4 / 2**, HIGH: **6 / 3**, and OFFENSIVE: **8 / 4**. Campaign conditions can permit fewer active groups.

- Earlier, staggered air departures and shorter launch/respawn gaps.
- Four ground dispatchers per coalition, with staggered initial departures.
- AUTO solo/duo ground respawn delays reduced from **30–40 minutes to 8–12 minutes**.
- Columns can continue toward the next objective after securing a sector.
- Road routes include a final off-road leg when necessary.
- Stalled columns receive route recovery after four minutes without progress, with a maximum of three attempts per leg. Recovery is suspended for columns halted through F10.
- Surviving vehicles continue receiving orders after the lead vehicle is lost.
- AIEN permits up to **18 groups** moving tactically at once.
- Earlier naval raid attempts and shorter naval cooldowns.

### English localization and documentation

- Translated the new AI controls, task menus, briefings, markers, status messages and notifications into English.
- Translated three AIEN diagnostic messages.
- Updated the mission briefing with the current V4.48 settings and F10 instructions.
- Included an English player guide, validation report and SHA-256 checksums.

### Installation and upgrade

1. Download `WarZone_IRON87_CAUCASO_DYNAMIC_SECTOR_MODERN_V4_48_Iron87Ita_EN.miz` from this release.
2. Stop the current mission or dedicated server session.
3. Back up the existing campaign save, then select the new `.miz` from `Saved Games\DCS\Missions\` or your server mission directory.
4. Keep the existing compatible WarZone persistence file and start the mission.

The persistence filename and save schema are unchanged from the supplied V4.47 mission; no save migration is introduced. AI tempo selections and live task assignments apply to the current mission session.

The repository's **Web Command Center and web task-control modules are separate source integrations**. They are not embedded in this `.miz` and require their own integration; this release adds the in-mission F10 controls and AI task board described above.

### Validation and practical limits

- All embedded Lua scripts and mission tables compile with **DCS `lua.dll`**.
- Simulated DCS API tests pass for opposing spawn tasks, assignment, tracking, F10 pagination, partial/full group destruction, one-time pending bonuses, despawn handling, disconnects, coalition controls and activity limits.
- Tests exercise the actual campaign scaler, air dispatchers, convoy continuation/recovery and paused/empty-server naval launch gates.
- An archive-wide language audit passed, and translation preserves the V4.48 Lua gameplay logic.
- ZIP integrity checks passed. The English build changes the campaign script, briefing dictionary and three AIEN diagnostic messages relative to the supplied base.

**An in-simulator flight session has not been run.** Actual taxi behavior, terrain pathfinding and server performance still require testing in DCS. Existing reference images remain the English reference artwork from the supplied base; where an older image shows different AI limits, use this release's updated briefing and current F10 status.

Created by **IRON87ITA**.
